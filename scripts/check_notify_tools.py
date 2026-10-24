#!/usr/bin/env python3
"""Compare GitHub release notifications against locally installed developer tools.

Fetches GitHub notifications, matches release events against CLI tools and
packages installed on the local machine (e.g. zensical, task, shuck, uv),
and compares installed versions against notified releases.
"""

import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
from typing import Any, Dict, List, Optional, Tuple

try:
    from packaging.version import parse as parse_version, InvalidVersion
except ImportError:
    parse_version = None
    InvalidVersion = Exception

# Ensure scripts directory is in sys.path
SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.append(str(SCRIPT_DIR))

try:
    from check_notify_apps import build_repo_to_app_map
    APP_REPOS = set(build_repo_to_app_map().keys())
except ImportError:
    APP_REPOS = set()

# Catppuccin Mocha Colors
BLUE = "\033[38;2;137;180;250m"
RED = "\033[38;2;243;139;168m"
GREEN = "\033[38;2;166;227;161m"
YELLOW = "\033[38;2;249;226;175m"
CYAN = "\033[38;2;148;226;213m"
GRAY = "\033[38;2;108;112;134m"
BOLD = "\033[1m"
RESET = "\033[0m"

# Known tool mapping: lowercased GitHub repo -> tool binary name
TOOL_REGISTRY: Dict[str, Dict[str, Any]] = {
    "zensical/zensical": {
        "bin": "zensical",
        "custom_upgrade": "uv tool upgrade zensical",
    },
    "go-task/task": {
        "bin": "task",
        "brew_formula": "go-task",
    },
    "ewhauser/shuck": {
        "bin": "shuck",
        "brew_formula": "ewhauser/tap/shuck",
    },
    "tstack/lnav": {
        "bin": "lnav",
    },
    "lycheeverse/lychee": {
        "bin": "lychee",
    },
    "astral-sh/uv": {
        "bin": "uv",
        "custom_upgrade": "uv self update",
    },
    "cli/cli": {
        "bin": "gh",
    },
    "getsops/sops": {
        "bin": "sops",
    },
    "filosottile/age": {
        "bin": "age",
    },
    "cloudflare/cloudflared": {
        "bin": "cloudflared",
    },
    "burntsushi/ripgrep": {
        "bin": "rg",
    },
    "junegunn/fzf": {
        "bin": "fzf",
    },
    "tmux/tmux": {
        "bin": "tmux",
        "version_flag": "-V",
    },
    "mikefarah/yq": {
        "bin": "yq",
    },
    "jqlang/jq": {
        "bin": "jq",
    },
    "casey/just": {
        "bin": "just",
    },
    "starship/starship": {
        "bin": "starship",
    },
    "sharkdp/bat": {
        "bin": "bat",
    },
    "sharkdp/fd": {
        "bin": "fd",
    },
}


def clean_version(v_str: Optional[str]) -> str:
    """Normalize version string."""
    if not v_str:
        return "unknown"
    cleaned = v_str.strip()
    if cleaned.lower().startswith("release-"):
        cleaned = cleaned[8:]
    elif cleaned.lower().startswith("v") and len(cleaned) > 1 and (cleaned[1].isdigit() or cleaned[1] == "."):
        cleaned = cleaned[1:]
    return cleaned.strip()


def extract_version_from_output(output: str) -> str:
    """Extract semantic version number from command standard output."""
    m = re.search(r"(?:[vV]|\b)(\d+(?:\.\d+)+(?:-[a-zA-Z0-9._]+)?)", output)
    if m:
        return m.group(1)
    return clean_version(output.strip().split("\n")[0])


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


def get_uv_tools() -> Dict[str, str]:
    """Parse installed uv tools and their versions."""
    tools: Dict[str, str] = {}
    if not shutil.which("uv"):
        return tools
    try:
        proc = subprocess.run(["uv", "tool", "list"], capture_output=True, text=True, check=False)
        if proc.returncode == 0:
            for line in proc.stdout.splitlines():
                # Format: "tool-name v1.2.3"
                m = re.match(r"^([a-zA-Z0-9_-]+)\s+v?([0-9.]+)", line.strip())
                if m:
                    tools[m.group(1).lower()] = m.group(2)
    except Exception:
        pass
    return tools


def get_installed_tool_version(
    bin_name: str, version_flag: str = "--version"
) -> Tuple[str, Optional[str]]:
    """Detect local binary and execute version check. Returns (version, path)."""
    bin_path = shutil.which(bin_name)
    if not bin_path:
        return "not installed", None

    try:
        proc = subprocess.run(
            [bin_path, version_flag],
            capture_output=True,
            text=True,
            check=False,
            timeout=5,
        )
        out = (proc.stdout or proc.stderr).strip()
        version = extract_version_from_output(out)
        return version or "unknown", bin_path
    except Exception:
        return "error", bin_path


def determine_upgrade_cmd(
    tool_name: str,
    bin_path: Optional[str],
    uv_tools: Dict[str, str],
    custom_upgrade: Optional[str] = None,
    brew_formula: Optional[str] = None,
) -> str:
    """Determine the optimal command to upgrade the local tool."""
    if custom_upgrade:
        return custom_upgrade

    if tool_name in uv_tools:
        return f"uv tool upgrade {tool_name}"

    if bin_path:
        if "linuxbrew" in bin_path or "/brew" in bin_path:
            formula = brew_formula or tool_name
            return f"brew upgrade {formula}"
        if ".cargo/bin" in bin_path:
            return f"cargo install {tool_name}"
        if bin_path.startswith("/usr/local/bin") and shutil.which("installer"):
            return f"curl -s https://i.jpillora.com/{tool_name}! | bash"

    if brew_formula:
        return f"brew upgrade {brew_formula}"

    return f"brew upgrade {tool_name}"


def extract_version_from_title(title: str, release_api_url: Optional[str] = None) -> str:
    """Extract release version from title or fallback to GitHub API."""
    m = re.search(r"(?:[vV]|\b)(\d+(?:\.\d+)+(?:-[a-zA-Z0-9._]+)?)", title)
    if m:
        return m.group(1)

    if release_api_url:
        try:
            proc = subprocess.run(["gh", "api", release_api_url], capture_output=True, text=True, check=False)
            if proc.returncode == 0:
                data = json.loads(proc.stdout)
                tag = data.get("tag_name")
                if tag:
                    return clean_version(tag)
        except Exception:
            pass

    return clean_version(title)


def compare_tool_versions(installed: str, latest: str) -> Tuple[str, bool]:
    """Compare tool versions. Returns (status, is_up_to_date)."""
    if installed in ("not installed", "unknown", "error", None):
        return installed or "unknown", False

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


def check_notify_tools(
    notifications: Optional[List[Dict[str, Any]]] = None,
    all_notifications: bool = False,
    github_token: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Compare release notifications with local CLI tool versions."""
    if notifications is None:
        notifications = fetch_notifications(all_notifications=all_notifications, token=github_token)

    uv_tools = get_uv_tools()
    results: Dict[str, Dict[str, Any]] = {}

    for notif in notifications:
        if notif.get("subject", {}).get("type") != "Release":
            continue

        repo_info = notif.get("repository", {})
        repo_full = repo_info.get("full_name", "").strip()
        repo_lower = repo_full.lower()
        repo_name = repo_info.get("name", "").strip().lower()

        # Skip homelab server/web apps that aren't developer CLI tools
        if repo_lower in APP_REPOS and repo_lower not in TOOL_REGISTRY:
            continue

        matched_reg = TOOL_REGISTRY.get(repo_lower)
        bin_name = None
        custom_upgrade = None
        brew_formula = None
        version_flag = "--version"

        if matched_reg:
            bin_name = matched_reg["bin"]
            custom_upgrade = matched_reg.get("custom_upgrade")
            brew_formula = matched_reg.get("brew_formula")
            version_flag = matched_reg.get("version_flag", "--version")
        elif shutil.which(repo_name):
            bin_name = repo_name
        elif repo_name in uv_tools:
            bin_name = repo_name
        else:
            continue

        if bin_name in results:
            continue

        # Check installed version
        if bin_name in uv_tools:
            installed_ver = uv_tools[bin_name]
            bin_path = shutil.which(bin_name)
        else:
            installed_ver, bin_path = get_installed_tool_version(bin_name, version_flag=version_flag)

        title = notif.get("subject", {}).get("title", "")
        release_url = notif.get("subject", {}).get("url")
        notified_ver = extract_version_from_title(title, release_url)

        status, up_to_date = compare_tool_versions(installed_ver, notified_ver)
        upgrade_cmd = determine_upgrade_cmd(
            tool_name=bin_name,
            bin_path=bin_path,
            uv_tools=uv_tools,
            custom_upgrade=custom_upgrade,
            brew_formula=brew_formula,
        )

        results[bin_name] = {
            "tool": bin_name,
            "repo": repo_full,
            "installed": installed_ver,
            "notified": notified_ver,
            "bin_path": bin_path,
            "status": status,
            "up_to_date": up_to_date,
            "upgrade_cmd": upgrade_cmd,
            "updated_at": notif.get("updated_at"),
            "url": notif.get("subject", {}).get("url"),
        }

    return list(results.values())


def format_table(results: List[Dict[str, Any]]) -> str:
    """Format comparison results into a clean terminal table."""
    if not results:
        return f"{YELLOW}No matching release notifications for local developer tools.{RESET}"

    headers = ["Tool", "Installed", "Notified", "Status", "Binary Location", "Upgrade Command"]
    rows: List[List[str]] = []

    for r in results:
        status_raw = r["status"]
        if status_raw == "up-to-date":
            status_str = f"{GREEN}Up to date{RESET}"
        elif status_raw == "update-available":
            status_str = f"{RED}{BOLD}Update available{RESET}"
        elif status_raw == "not installed":
            status_str = f"{GRAY}Not installed{RESET}"
        else:
            status_str = f"{YELLOW}{status_raw}{RESET}"

        bin_loc = r["bin_path"] or "-"
        rows.append([
            f"{BOLD}{r['tool']}{RESET}",
            r["installed"],
            r["notified"],
            status_str,
            f"{GRAY}{bin_loc}{RESET}",
            f"{CYAN}{r['upgrade_cmd']}{RESET}",
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
        description="Compare GitHub release notifications with locally installed developer tools."
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

    results = check_notify_tools(
        all_notifications=args.all,
        github_token=args.token,
    )

    if args.json:
        print(json.dumps(results, indent=2))
        return

    print(format_table(results))


if __name__ == "__main__":
    main()
