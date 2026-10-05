#!/usr/bin/env python3
"""Homelab Web Application Version Checker.

Compares installed versions of LXC applications against upstream released versions
(e.g., GitHub releases or package registries).
Supports HTML/web-based extraction (e.g., Homepage footer).
"""

import argparse
from datetime import datetime
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from typing import Any, Callable, Dict, List, Optional, Tuple
import urllib.error
import urllib.request

# Ensure scripts dir in sys.path
SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.append(str(SCRIPT_DIR))

try:
    from lxc_update import find_lxc_container
except ImportError:
    find_lxc_container = None

# Catppuccin Mocha Colors
BLUE = "\033[38;2;137;180;250m"
RED = "\033[38;2;243;139;168m"
GREEN = "\033[38;2;166;227;161m"
YELLOW = "\033[38;2;249;226;175m"
CYAN = "\033[38;2;148;226;213m"
GRAY = "\033[38;2;108;112;134m"
BOLD = "\033[1m"
RESET = "\033[0m"


def clean_version(version_str: Optional[str]) -> str:
    """Normalize version string by stripping 'v', spaces, and newlines."""
    if not version_str:
        return "unknown"
    cleaned = version_str.strip()
    if cleaned.lower().startswith("v") and len(cleaned) > 1 and (cleaned[1].isdigit() or cleaned[1] == "."):
        cleaned = cleaned[1:]
    return cleaned.strip()


def parse_homepage_version_from_web(
    base_url: str = "http://192.168.1.47:3000",
) -> Tuple[Optional[str], Optional[str]]:
    """Parse homepage version from the web page footer (e.g. v2.4.0 (source, Sep 17, 2026))."""
    try:
        req = urllib.request.Request(
            base_url, headers={"User-Agent": "homelab-version-checker"}
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            html = resp.read().decode("utf-8", errors="ignore")

        # 1. Direct SSR match fallback
        m = re.search(r'v(\d+\.\d+\.\d+)\s*\((source[^)]*)\)', html)
        if m:
            return m.group(1), f"v{m.group(1)} ({m.group(2)})"

        # 2. Extract webpack and index chunk paths
        webpack_match = re.search(
            r'src="(/_next/static/chunks/webpack-[^"]+\.js)"', html
        )
        index_match = re.search(
            r'src="(/_next/static/chunks/pages/index-[^"]+\.js)"', html
        )
        if not webpack_match or not index_match:
            return None, None

        # 3. Read index-*.js to identify Version component variable name
        with urllib.request.urlopen(
            base_url + index_match.group(1), timeout=5
        ) as resp:
            index_js = resp.read().decode("utf-8", errors="ignore")

        var_match = re.search(
            r"hideVersion\s*&&[^)]*jsx\)\(\s*([a-zA-Z0-9_$]+)\s*,", index_js
        )
        if not var_match:
            return None, None
        var_name = var_match.group(1)

        # 4. Find chunk ID for that variable
        chunk_match = re.search(rf"{re.escape(var_name)}=[^;]*\.e\((\d+)\)", index_js)
        if not chunk_match:
            return None, None
        chunk_id = chunk_match.group(1)

        # 5. Look up chunk hash in webpack chunk map
        with urllib.request.urlopen(
            base_url + webpack_match.group(1), timeout=5
        ) as resp:
            webpack_js = resp.read().decode("utf-8", errors="ignore")

        hash_match = re.search(
            rf'"{chunk_id}":"([a-f0-9]+)"', webpack_js
        ) or re.search(rf'{chunk_id}:"([a-f0-9]+)"', webpack_js)
        if not hash_match:
            return None, None
        chunk_hash = hash_match.group(1)

        # 6. Fetch version component chunk
        chunk_url = f"{base_url}/_next/static/chunks/{chunk_id}.{chunk_hash}.js"
        with urllib.request.urlopen(chunk_url, timeout=5) as resp:
            chunk_js = resp.read().decode("utf-8", errors="ignore")

        # 7. Extract version, revision, build date
        v_match = re.search(r"releases/tag/v?([0-9.]+)", chunk_js) or re.search(
            r'"v([0-9.]+)"', chunk_js
        )
        ver = v_match.group(1) if v_match else None

        build_time_match = re.search(r'"(\d{4}-\d{2}-\d{2}T[^"]+)"', chunk_js)
        rev_match = re.search(r'"(source|dev|nightly|[a-f0-9]{7,})"', chunk_js)

        formatted = f"v{ver}" if ver else "unknown"
        if ver and rev_match and build_time_match:
            try:
                dt = datetime.fromisoformat(
                    build_time_match.group(1).replace("Z", "+00:00")
                )
                date_str = dt.strftime("%b %d, %Y")
                formatted = f"v{ver} ({rev_match.group(1)}, {date_str})"
            except Exception:
                pass

        return ver, formatted
    except Exception:
        return None, None


APP_REGISTRY: Dict[str, Dict[str, Any]] = {
    "stirling-pdf": {
        "upstream_repo": "Stirling-Tools/Stirling-PDF",
        "default_node": "pve04",
        "default_vmid": 133,
        "cmd": [
            "unzip",
            "-q",
            "-c",
            "/opt/Stirling-PDF/Stirling-PDF.jar",
            "META-INF/MANIFEST.MF",
        ],
        "regex": r"Implementation-Version:\s*([^\r\n]+)",
    },
    "drawio": {
        "upstream_repo": "jgraph/drawio",
        "default_node": "pve04",
        "default_vmid": 136,
        "cmd": ["cat", "/var/lib/tomcat10/webapps/draw.version"],
        "regex": r"([0-9.]+)",
    },
    "changedetection": {
        "upstream_repo": "dgtlmoon/changedetection.io",
        "default_node": "pve04",
        "default_vmid": 116,
        "cmd": ["pipx", "list"],
        "regex": r"changedetection-io\s+([0-9.]+)",
    },
    "wallos": {
        "upstream_repo": "ellite/Wallos",
        "default_node": "pve03",
        "default_vmid": 116,
        "cmd": ["cat", "/opt/wallos/includes/version.php"],
        "regex": r'version\s*=\s*["\']v?([^"\']+)["\']',
    },
    "localsend": {
        "upstream_repo": "localsend/web",
        "default_node": "pve04",
        "default_vmid": 103,
        "cmd": ["git", "-C", "/opt/localsend", "rev-parse", "--short", "HEAD"],
        "version_type": "commit",
    },
    "homepage": {
        "upstream_repo": "gethomepage/homepage",
        "default_node": "pve04",
        "default_vmid": 110,
        "web_url": "http://192.168.1.47:3000",
        "web_parser": parse_homepage_version_from_web,
        "cmd": ["cat", "/opt/homepage_version.txt"],
        "regex": r"([0-9.]+)",
    },
    "convertx": {
        "upstream_repo": "C4illin/ConvertX",
        "default_node": "pve04",
        "default_vmid": 105,
        "cmd": ["docker", "inspect", "convertx", "--format", "{{.Config.Image}}"],
        "regex": r":v?([0-9.]+)",
    },
}


def get_latest_github_release(repo: str, token: Optional[str] = None) -> Optional[str]:
    """Fetch latest tag_name from GitHub API for a given owner/repo."""
    api_url = f"https://api.github.com/repos/{repo}/releases/latest"
    headers = {
        "User-Agent": "homelab-version-checker",
        "Accept": "application/vnd.github.v3+json",
    }
    github_token = token or os.environ.get("GITHUB_TOKEN")
    if github_token:
        headers["Authorization"] = f"Bearer {github_token}"

    req = urllib.request.Request(api_url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode())
            tag = data.get("tag_name")
            return clean_version(tag)
    except urllib.error.HTTPError as err:
        if err.code == 404:
            return get_latest_github_tag(repo, token=github_token)
        return None
    except Exception:
        return None


def get_latest_github_tag(repo: str, token: Optional[str] = None) -> Optional[str]:
    """Fetch latest tag from GitHub API tags list."""
    api_url = f"https://api.github.com/repos/{repo}/tags"
    headers = {
        "User-Agent": "homelab-version-checker",
        "Accept": "application/vnd.github.v3+json",
    }
    github_token = token or os.environ.get("GITHUB_TOKEN")
    if github_token:
        headers["Authorization"] = f"Bearer {github_token}"

    req = urllib.request.Request(api_url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode())
            if isinstance(data, list) and data:
                return clean_version(data[0].get("name"))
    except Exception:
        pass
    return None


def get_latest_github_commit(
    repo: str, branch: str = "main", token: Optional[str] = None
) -> Optional[str]:
    """Fetch latest commit short sha from GitHub API for a given repo branch."""
    api_url = f"https://api.github.com/repos/{repo}/commits/{branch}"
    headers = {
        "User-Agent": "homelab-version-checker",
        "Accept": "application/vnd.github.v3+json",
    }
    github_token = token or os.environ.get("GITHUB_TOKEN")
    if github_token:
        headers["Authorization"] = f"Bearer {github_token}"

    req = urllib.request.Request(api_url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode())
            sha = data.get("sha")
            if sha:
                return sha[:7]
    except Exception:
        pass
    return None


def get_installed_version(
    node: str, vmid: int, cmd: List[str], regex: Optional[str] = None, timeout: int = 10
) -> Optional[str]:
    """Execute command inside LXC container via SSH pct exec and extract version."""
    ssh_cmd = [
        "ssh",
        "-o",
        "BatchMode=yes",
        "-o",
        f"ConnectTimeout={timeout}",
        node,
        "pct",
        "exec",
        str(vmid),
        "--",
        *cmd,
    ]
    try:
        proc = subprocess.run(
            ssh_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=timeout + 5,
            check=False,
        )
        if proc.returncode != 0:
            return None

        stdout = proc.stdout.strip()
        if not stdout:
            return None

        if regex:
            match = re.search(regex, stdout)
            if match:
                return clean_version(match.group(1))
            return None
        return clean_version(stdout)
    except Exception:
        return None


def resolve_app_target(
    app_name: str, node: Optional[str] = None
) -> Tuple[
    Optional[str],
    Optional[int],
    Optional[str],
    Optional[List[str]],
    Optional[str],
    str,
    Optional[Callable],
    Optional[str],
]:
    """Determine (node, vmid, upstream_repo, cmd, regex, version_type, web_parser, web_url) for an app."""
    clean_name = app_name.lower().strip()

    # 1. Registered app
    if clean_name in APP_REGISTRY:
        reg = APP_REGISTRY[clean_name]
        target_node = node or reg["default_node"]
        vmid = reg.get("default_vmid")
        if not node and find_lxc_container:
            found = find_lxc_container(clean_name, node=target_node)
            if found:
                target_node, vmid, _, _ = found
        return (
            target_node,
            vmid,
            reg["upstream_repo"],
            reg.get("cmd"),
            reg.get("regex"),
            reg.get("version_type", "release"),
            reg.get("web_parser"),
            reg.get("web_url"),
        )

    # 2. Dynamic discovery from local update.sh
    root_dir = Path.cwd()
    script_candidates = [
        root_dir / "lxc" / clean_name / "update.sh",
        root_dir / "pve" / clean_name / "update.sh",
        root_dir / "docker" / clean_name / "update.sh",
    ]
    discovered_repo = None
    for cand in script_candidates:
        if cand.exists():
            content = cand.read_text(encoding="utf-8", errors="ignore")
            match = re.search(r'GITHUB_REPO="([^"]+)"', content)
            if match:
                discovered_repo = match.group(1)
                break

    target_node = node
    vmid = None
    if find_lxc_container:
        found = find_lxc_container(clean_name, node=node)
        if found:
            target_node, vmid, _, _ = found

    return target_node, vmid, discovered_repo, None, None, "release", None, None


def check_app_version(
    app_name: str,
    node: Optional[str] = None,
    github_token: Optional[str] = None,
) -> Dict[str, Any]:
    """Compare installed version to latest released version for a single app."""
    (
        target_node,
        vmid,
        upstream_repo,
        cmd,
        regex,
        version_type,
        web_parser,
        web_url,
    ) = resolve_app_target(app_name, node=node)

    result: Dict[str, Any] = {
        "app": app_name,
        "node": target_node or "unknown",
        "vmid": vmid,
        "repo": upstream_repo,
        "installed": "unknown",
        "installed_detail": None,
        "latest": "unknown",
        "status": "unknown",
        "up_to_date": False,
        "error": None,
    }

    if not upstream_repo:
        result["error"] = f"Upstream repository unknown for '{app_name}'"
        result["status"] = "unconfigured"
        return result

    # 1. Fetch latest released version
    if version_type == "commit":
        latest = get_latest_github_commit(upstream_repo, token=github_token)
    else:
        latest = get_latest_github_release(upstream_repo, token=github_token)
    if latest:
        result["latest"] = latest
    else:
        result["error"] = "Failed to fetch latest release from GitHub"

    # 2. Fetch installed version
    # Priority A: Web parser if configured (e.g., Homepage footer)
    if web_parser and web_url:
        w_ver, w_detail = web_parser(web_url)
        if w_ver:
            result["installed"] = clean_version(w_ver)
            result["installed_detail"] = w_detail

    # Priority B: Container execution fallback
    if result["installed"] == "unknown" and target_node and vmid and cmd:
        installed = get_installed_version(target_node, vmid, cmd, regex=regex)
        if installed:
            result["installed"] = installed

    # 3. Compare
    if result["installed"] != "unknown" and result["latest"] != "unknown":
        if result["installed"] == result["latest"]:
            result["status"] = "up-to-date"
            result["up_to_date"] = True
        else:
            result["status"] = "update-available"
            result["up_to_date"] = False
    elif result["installed"] != "unknown":
        result["status"] = "installed-only"
    elif result["latest"] != "unknown":
        result["status"] = "latest-only"

    return result


def format_table(results: List[Dict[str, Any]]) -> str:
    """Format comparison results into a clean terminal table."""
    headers = ["App", "Node", "VMID", "Installed", "Latest", "Status"]
    rows = []

    for r in results:
        vmid_str = str(r["vmid"]) if r["vmid"] is not None else "-"
        status = r["status"]
        if status == "up-to-date":
            status_fmt = f"{GREEN}Up to date{RESET}"
        elif status == "update-available":
            status_fmt = f"{YELLOW}Update available ({r['installed']} -> {r['latest']}){RESET}"
        elif status == "unconfigured":
            status_fmt = f"{GRAY}Not configured{RESET}"
        elif status == "latest-only":
            status_fmt = f"{GRAY}Latest only ({r['latest']}){RESET}"
        elif status == "installed-only":
            status_fmt = f"{GRAY}Installed only ({r['installed']}){RESET}"
        else:
            status_fmt = f"{RED}{status}{RESET}"

        installed_str = r.get("installed_detail") or r["installed"]

        rows.append(
            [
                r["app"],
                r["node"],
                vmid_str,
                installed_str,
                r["latest"],
                status_fmt,
            ]
        )

    # Compute column widths
    widths = [len(h) for h in headers]
    for row in rows:
        for idx, cell in enumerate(row):
            plain = re.sub(r"\033\[[0-9;]*m", "", str(cell))
            widths[idx] = max(widths[idx], len(plain))

    # Build output
    header_line = "  ".join(f"{h:<{widths[i]}}" for i, h in enumerate(headers))
    sep_line = "  ".join("-" * widths[i] for i in range(len(headers)))

    output_lines = [f"{BOLD}{header_line}{RESET}", sep_line]
    for row in rows:
        formatted_cells = []
        for i, cell in enumerate(row):
            plain = re.sub(r"\033\[[0-9;]*m", "", str(cell))
            pad = widths[i] - len(plain)
            formatted_cells.append(f"{cell}{' ' * pad}")
        output_lines.append("  ".join(formatted_cells))

    return "\n".join(output_lines)


def main() -> None:
    """CLI entrypoint."""
    parser = argparse.ArgumentParser(
        description="Compare installed LXC web app version to upstream release."
    )
    parser.add_argument(
        "app_name",
        nargs="?",
        help="Name of web app to check (e.g., stirling-pdf, drawio, wallos, homepage)",
    )
    parser.add_argument(
        "-a",
        "--all",
        action="store_true",
        help="Check all registered homelab web apps",
    )
    parser.add_argument(
        "-n",
        "--node",
        help="Proxmox node name override (e.g., pve04, pve03)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output structured JSON instead of human-readable table",
    )

    args = parser.parse_args()

    if not args.app_name and not args.all:
        parser.print_help()
        sys.exit(1)

    targets = list(APP_REGISTRY.keys()) if args.all else [args.app_name]

    results = []
    for app in targets:
        res = check_app_version(app, node=args.node)
        results.append(res)

    if args.json:
        print(json.dumps(results if args.all else results[0], indent=2))
    else:
        print(format_table(results))

    if args.all:
        has_updates = any(r["status"] == "update-available" for r in results)
        sys.exit(2 if has_updates else 0)
    else:
        sys.exit(0 if results[0]["status"] == "up-to-date" else 1)


if __name__ == "__main__":
    main()
