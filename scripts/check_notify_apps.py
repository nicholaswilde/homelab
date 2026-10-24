#!/usr/bin/env python3
"""Compare GitHub release notifications against homelab web application versions.

Fetches unread GitHub notifications, filters for release events matching known
homelab apps, and compares them with currently installed versions on Proxmox LXC
or Docker containers.
"""

import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
from typing import Any, Dict, List, Optional, Tuple

# Ensure scripts directory is in sys.path
SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.append(str(SCRIPT_DIR))

try:
    from check_app_version import (
        APP_REGISTRY,
        check_app_version,
        clean_version,
    )
except ImportError:
    APP_REGISTRY = {}
    check_app_version = None
    clean_version = lambda s: s or "unknown"

try:
    from packaging.version import parse as parse_version, InvalidVersion
except ImportError:
    parse_version = None
    InvalidVersion = Exception

# Catppuccin Mocha Colors
BLUE = "\033[38;2;137;180;250m"
RED = "\033[38;2;243;139;168m"
GREEN = "\033[38;2;166;227;161m"
YELLOW = "\033[38;2;249;226;175m"
CYAN = "\033[38;2;148;226;213m"
GRAY = "\033[38;2;108;112;134m"
BOLD = "\033[1m"
RESET = "\033[0m"


def fetch_notifications(
    all_notifications: bool = False,
    token: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Fetch GitHub notifications using the `gh` CLI."""
    endpoint = "notifications?all=true" if all_notifications else "notifications"
    cmd = ["gh", "api", endpoint]
    if token:
        cmd.extend(["-H", f"Authorization: Bearer {token}"])

    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
        if proc.returncode != 0:
            print(
                f"{RED}Error fetching GitHub notifications{RESET}: {proc.stderr.strip()}",
                file=sys.stderr,
            )
            return []
        data = json.loads(proc.stdout)
        return data if isinstance(data, list) else []
    except Exception as e:
        print(f"{RED}Failed to execute gh command{RESET}: {e}", file=sys.stderr)
        return []


def build_repo_to_app_map(root_dir: Optional[Path] = None) -> Dict[str, str]:
    """Map lowercased GitHub repository names (owner/repo) to homelab app names."""
    mapping: Dict[str, str] = {}

    # 1. From APP_REGISTRY in check_app_version.py
    for app_name, reg in APP_REGISTRY.items():
        upstream = reg.get("upstream_repo")
        if upstream:
            mapping[upstream.lower().strip()] = app_name

    # 2. Dynamic discovery from local directory trees
    base = root_dir or Path.cwd()
    search_dirs = [base / "lxc", base / "pve", base / "docker"]
    for s_dir in search_dirs:
        if not s_dir.is_dir():
            continue
        for child in s_dir.iterdir():
            if not child.is_dir():
                continue
            app_name = child.name
            update_sh = child / "update.sh"
            if update_sh.is_file():
                content = update_sh.read_text(encoding="utf-8", errors="ignore")
                m = re.search(r'GITHUB_REPO="([^"]+)"', content)
                if m:
                    mapping[m.group(1).lower().strip()] = app_name

            compose_file = child / "compose.yaml"
            if compose_file.is_file():
                c_content = compose_file.read_text(encoding="utf-8", errors="ignore")
                for img in re.findall(r"image:\s*(?:ghcr\.io/)?([a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+):", c_content):
                    mapping[img.lower().strip()] = app_name

    return mapping


def extract_version_from_title(title: str) -> str:
    """Extract semantic version string from notification title or tag."""
    m = re.search(r"(?:[vV]|\b)(\d+(?:\.\d+)+(?:-[a-zA-Z0-9._]+)?)", title)
    if m:
        return m.group(1)
    return clean_version(title)


def resolve_release_version(title: str, release_api_url: Optional[str] = None) -> str:
    """Extract version from title, or query release API if title has no digits."""
    ver = extract_version_from_title(title)
    if not re.search(r"\d", ver) and release_api_url:
        try:
            proc = subprocess.run(
                ["gh", "api", release_api_url],
                capture_output=True,
                text=True,
                check=False,
            )
            if proc.returncode == 0:
                data = json.loads(proc.stdout)
                tag = data.get("tag_name")
                if tag:
                    return clean_version(tag)
        except Exception:
            pass
    return ver


def compare_versions(installed: str, latest: str) -> Tuple[str, bool]:
    """Compare installed version to notified version.

    Returns (status_string, is_up_to_date).
    """
    if installed in ("unknown", "uninstalled", None):
        return "unknown", False

    clean_inst = clean_version(installed)
    clean_lat = clean_version(latest)

    if clean_inst == clean_lat:
        return "up-to-date", True

    if parse_version:
        try:
            parsed_inst = parse_version(clean_inst)
            parsed_lat = parse_version(clean_lat)
            if parsed_inst >= parsed_lat:
                return "up-to-date", True
            return "update-available", False
        except InvalidVersion:
            pass

    return ("up-to-date" if clean_inst == clean_lat else "update-available"), (clean_inst == clean_lat)


def check_notify_apps(
    notifications: Optional[List[Dict[str, Any]]] = None,
    all_notifications: bool = False,
    github_token: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Compare GitHub release notifications with installed homelab web applications."""
    if notifications is None:
        notifications = fetch_notifications(all_notifications=all_notifications, token=github_token)

    repo_map = build_repo_to_app_map()
    seen_apps: Dict[str, Dict[str, Any]] = {}

    for notif in notifications:
        if notif.get("subject", {}).get("type") != "Release":
            continue

        repo_info = notif.get("repository", {})
        full_name = repo_info.get("full_name", "").lower().strip()
        if not full_name or full_name not in repo_map:
            continue

        app_name = repo_map[full_name]
        title = notif.get("subject", {}).get("title", "")
        release_url = notif.get("subject", {}).get("url")
        notified_ver = resolve_release_version(title, release_url)

        # Keep the latest notification per application
        if app_name in seen_apps:
            continue

        # Get installed version from check_app_version
        installed_ver = "unknown"
        node = "unknown"
        vmid = None

        if check_app_version:
            try:
                res = check_app_version(app_name)
                installed_ver = res.get("installed", "unknown")
                node = res.get("node", "unknown")
                vmid = res.get("vmid")
            except Exception:
                pass

        status, up_to_date = compare_versions(installed_ver, notified_ver)

        update_cmd = f"rtk uv run python scripts/lxc_update.py {app_name}"
        if node and node != "unknown":
            update_cmd += f" --node {node}"

        seen_apps[app_name] = {
            "app": app_name,
            "repo": repo_info.get("full_name"),
            "node": node,
            "vmid": vmid,
            "installed": installed_ver,
            "notified": notified_ver,
            "title": title,
            "status": status,
            "up_to_date": up_to_date,
            "update_cmd": update_cmd,
            "updated_at": notif.get("updated_at"),
            "url": notif.get("subject", {}).get("url"),
        }

    return list(seen_apps.values())


def format_table(results: List[Dict[str, Any]]) -> str:
    """Format comparison results into a clean terminal table."""
    if not results:
        return f"{YELLOW}No matching release notifications for homelab web applications.{RESET}"

    headers = ["App", "Node", "VMID", "Installed", "Notified", "Status", "Update Command"]
    rows: List[List[str]] = []

    for r in results:
        status_raw = r["status"]
        if status_raw == "up-to-date":
            status_str = f"{GREEN}Up to date{RESET}"
        elif status_raw == "update-available":
            status_str = f"{RED}{BOLD}Update available{RESET}"
        else:
            status_str = f"{YELLOW}{status_raw}{RESET}"

        vmid_str = str(r["vmid"]) if r["vmid"] is not None else "-"
        rows.append([
            f"{BOLD}{r['app']}{RESET}",
            r["node"],
            vmid_str,
            r["installed"],
            r["notified"],
            status_str,
            f"{GRAY}{r['update_cmd']}{RESET}",
        ])

    col_widths = [len(h) for h in headers]
    for row in rows:
        for i, val in enumerate(row):
            clean_val = re.sub(r"\033\[[0-9;]*m", "", val)
            col_widths[i] = max(col_widths[i], len(clean_val))

    def format_row(values: List[str]) -> str:
        line_parts = []
        for i, val in enumerate(values):
            clean_len = len(re.sub(r"\033\[[0-9;]*m", "", val))
            padding = " " * (col_widths[i] - clean_len)
            line_parts.append(val + padding)
        return "  ".join(line_parts)

    header_line = format_row(headers)
    sep_line = "  ".join("-" * w for w in col_widths)
    data_lines = [format_row(row) for row in rows]

    return "\n".join([header_line, sep_line, *data_lines])


def main() -> None:
    """CLI entrypoint."""
    parser = argparse.ArgumentParser(
        description="Compare GitHub release notifications with installed homelab web applications."
    )
    parser.add_argument(
        "-a", "--all",
        action="store_true",
        help="Include read notifications in search",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output raw JSON data",
    )
    parser.add_argument(
        "--token",
        help="GitHub token (defaults to gh CLI auth)",
    )
    args = parser.parse_args()

    results = check_notify_apps(
        all_notifications=args.all,
        github_token=args.token,
    )

    if args.json:
        print(json.dumps(results, indent=2))
        return

    print(format_table(results))


if __name__ == "__main__":
    main()
