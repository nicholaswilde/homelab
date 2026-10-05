#!/usr/bin/env python3
"""LXC Application Updater.

Discovers and updates applications running inside Proxmox LXC containers.
Supports target version passing, git pulls inside containers, and service restarts.
"""

import argparse
from pathlib import Path
import re
import subprocess
import sys
from typing import Any, Dict, List, Optional, Tuple

# Catppuccin Mocha ANSI Colors
BLUE = "\033[38;2;137;180;250m"
RED = "\033[38;2;243;139;168m"
GREEN = "\033[38;2;166;227;161m"
YELLOW = "\033[38;2;249;226;175m"
RESET = "\033[0m"

DEFAULT_NODES: List[str] = ["pve04", "pve03", "pve01"]
REMOTE_REPO_PATH: str = "/root/git/nicholaswilde/homelab"


def log_info(msg: str) -> None:
    """Print info message in Catppuccin blue."""
    print(f"{BLUE}INFO{RESET}: {msg}")


def log_warn(msg: str) -> None:
    """Print warning message in Catppuccin yellow."""
    print(f"{YELLOW}WARN{RESET}: {msg}")


def log_error(msg: str) -> None:
    """Print error message in Catppuccin red."""
    print(f"{RED}ERRO{RESET}: {msg}")


def log_success(msg: str) -> None:
    """Print success message in Catppuccin green."""
    print(f"{GREEN}SUCC{RESET}: {msg}")


def run_ssh_command(
    node: str, cmd_args: List[str], timeout: int = 15
) -> Tuple[int, str, str]:
    """Execute command on remote node over SSH and return (exit_code, stdout, stderr)."""
    full_cmd = [
        "ssh",
        "-o",
        "BatchMode=yes",
        "-o",
        f"ConnectTimeout={timeout}",
        node,
        *cmd_args,
    ]
    try:
        proc = subprocess.run(
            full_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=timeout + 30,
            check=False,
        )
        return proc.returncode, proc.stdout, proc.stderr
    except subprocess.TimeoutExpired:
        return 124, "", f"SSH command timed out after {timeout}s"
    except Exception as exc:
        return 1, "", str(exc)


def parse_pct_list(output: str) -> List[Dict[str, Any]]:
    """Parse output table of 'pct list' into list of container dictionaries."""
    containers: List[Dict[str, Any]] = []
    lines = output.strip().splitlines()
    if not lines:
        return containers

    # Find columns from header
    for line in lines[1:]:
        line = line.strip()
        if not line:
            continue
        parts = re.split(r"\s+", line)
        if len(parts) >= 3 and parts[0].isdigit():
            containers.append(
                {
                    "vmid": int(parts[0]),
                    "status": parts[1].lower(),
                    "name": parts[-1].lower(),
                }
            )
    return containers


def find_lxc_container(
    app_name: str,
    node: Optional[str] = None,
    nodes: Optional[List[str]] = None,
) -> Optional[Tuple[str, int, str, str]]:
    """Locate container matching app_name across Proxmox nodes.

    Returns (node, vmid, container_name, status) or None if not found.
    """
    search_nodes = [node] if node else (nodes or DEFAULT_NODES)
    target = app_name.lower().strip()

    for n in search_nodes:
        ret, stdout, stderr = run_ssh_command(n, ["pct", "list"])
        if ret != 0:
            log_warn(f"Failed to query {n}: {stderr.strip() or 'unreachable'}")
            continue

        containers = parse_pct_list(stdout)
        # Exact match first
        for ct in containers:
            if ct["name"] == target:
                return n, ct["vmid"], ct["name"], ct["status"]

        # Substring / partial match fallback
        for ct in containers:
            if target in ct["name"] or ct["name"] in target:
                return n, ct["vmid"], ct["name"], ct["status"]

    return None


def get_update_script_path(app_name: str) -> str:
    """Determine relative path of update script inside container repo."""
    clean_name = app_name.lower().strip()
    root_dir = Path.cwd()
    if (root_dir / "pve" / clean_name / "update.sh").exists():
        return f"{REMOTE_REPO_PATH}/pve/{clean_name}/update.sh"
    return f"{REMOTE_REPO_PATH}/lxc/{clean_name}/update.sh"


def build_pct_exec_cmd(
    node: str, vmid: int, inner_cmd: List[str]
) -> List[str]:
    """Construct full SSH pct exec command list."""
    return [
        "ssh",
        node,
        "pct",
        "exec",
        str(vmid),
        "--",
        *inner_cmd,
    ]


def update_lxc(
    app_name: str,
    version: Optional[str] = None,
    node: Optional[str] = None,
    vmid: Optional[int] = None,
    pull: bool = True,
    dry_run: bool = False,
) -> bool:
    """Orchestrate container discovery, git update, and update script execution."""
    log_info(f"Initiating update for '{app_name}'...")

    status = "running"
    container_name = app_name

    if vmid is None or node is None:
        found = find_lxc_container(app_name, node=node)
        if not found:
            log_error(f"Could not find container for '{app_name}' on any Proxmox node.")
            return False
        node, vmid, container_name, status = found

    log_info(f"Target found: Node '{node}', VMID {vmid} ({container_name}, status: {status})")

    if status != "running":
        log_error(f"Container {vmid} on {node} is not running (status: {status}). Please start it first.")
        return False

    update_script = get_update_script_path(container_name)

    # 1. Git pull inside container repo
    if pull:
        pull_cmd = build_pct_exec_cmd(
            node,
            vmid,
            ["git", "-C", REMOTE_REPO_PATH, "pull", "origin", "main"],
        )
        if dry_run:
            log_info(f"[DRY-RUN] Would run: {' '.join(pull_cmd)}")
        else:
            log_info("Pulling latest git changes inside container...")
            proc = subprocess.run(pull_cmd, text=True, capture_output=True, check=False)
            if proc.returncode != 0:
                log_warn(f"git pull had non-zero exit ({proc.returncode}): {proc.stderr.strip()}")
            else:
                log_info(f"Git pull: {proc.stdout.strip() or 'Already up to date.'}")

    # 2. Build update command
    exec_args = ["bash", update_script]
    if version:
        exec_args.extend(["-v", version])

    update_cmd = build_pct_exec_cmd(node, vmid, exec_args)

    if dry_run:
        log_info(f"[DRY-RUN] Would execute: {' '.join(update_cmd)}")
        log_success(f"[DRY-RUN] Verification complete for {container_name}")
        return True

    log_info(f"Executing update script inside container ({' '.join(exec_args)})...")
    proc = subprocess.run(update_cmd, text=True, capture_output=False, check=False)
    if proc.returncode != 0:
        log_error(f"Update script exited with status {proc.returncode}")
        return False

    log_success(f"Successfully updated '{container_name}' on {node} (VMID {vmid})!")
    return True


def list_all_lxc_apps() -> None:
    """Print all discovered LXC containers across nodes with update script status."""
    log_info("Scanning Proxmox nodes for LXC containers...")
    root_dir = Path.cwd()

    for node in DEFAULT_NODES:
        ret, stdout, _ = run_ssh_command(node, ["pct", "list"])
        if ret != 0:
            continue
        containers = parse_pct_list(stdout)
        print(f"\nNode: {BLUE}{node}{RESET} ({len(containers)} containers)")
        print(f"{'VMID':<8} {'Status':<10} {'Name':<20} {'Update Script'}")
        print("-" * 60)
        for ct in containers:
            name = ct["name"]
            has_lxc_script = (root_dir / "lxc" / name / "update.sh").exists()
            has_pve_script = (root_dir / "pve" / name / "update.sh").exists()
            script_status = (
                f"{GREEN}Available{RESET}"
                if (has_lxc_script or has_pve_script)
                else f"{YELLOW}None{RESET}"
            )
            print(f"{ct['vmid']:<8} {ct['status']:<10} {name:<20} {script_status}")


def main() -> None:
    """Entry point for CLI execution."""
    parser = argparse.ArgumentParser(
        description="Update Proxmox LXC applications by triggering remote update scripts."
    )
    parser.add_argument(
        "app_name",
        nargs="?",
        help="Name of the LXC application to update (e.g. drawio, bentopdf, vaultwarden)",
    )
    parser.add_argument(
        "-v",
        "--version",
        help="Specific target version to install (passed to update script if supported)",
    )
    parser.add_argument(
        "-n",
        "--node",
        help="Proxmox node name (default: auto-detected across pve04, pve03, pve01)",
    )
    parser.add_argument(
        "--vmid",
        type=int,
        help="Specific container VMID (default: auto-detected)",
    )
    parser.add_argument(
        "--no-pull",
        action="store_true",
        help="Skip git pull inside container before running update script",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show commands that would be executed without making changes",
    )
    parser.add_argument(
        "-l",
        "--list",
        action="store_true",
        help="List all LXC containers discovered across cluster nodes",
    )

    args = parser.parse_args()

    if args.list:
        list_all_lxc_apps()
        sys.exit(0)

    if not args.app_name:
        parser.print_help()
        sys.exit(1)

    success = update_lxc(
        app_name=args.app_name,
        version=args.version,
        node=args.node,
        vmid=args.vmid,
        pull=not args.no_pull,
        dry_run=args.dry_run,
    )

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
