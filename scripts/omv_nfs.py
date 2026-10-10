#!/usr/bin/env python3
"""OpenMediaVault (OMV) External Drive & NFS Automation Tool.

Verifies and fixes USB passthrough, filesystem mounts, and NFS services
for the OpenMediaVault VM following power outages or storage disconnections.
"""

import argparse
import json
import subprocess
import sys
from typing import Any, Dict, List, Optional, Tuple

# Catppuccin Mocha Colors
BLUE = "\033[38;2;137;180;250m"
RED = "\033[38;2;243;139;168m"
GREEN = "\033[38;2;166;227;161m"
YELLOW = "\033[38;2;249;226;175m"
CYAN = "\033[38;2;148;226;213m"
GRAY = "\033[38;2;108;112;134m"
BOLD = "\033[1m"
RESET = "\033[0m"

# Default Homelab Environment Parameters
DEFAULT_OMV_HOST = "omv"
DEFAULT_PVE_NODE = "pve01"
DEFAULT_PVE_VMID = "100"
DEFAULT_USB_ID = "0bc2:ab31"  # Seagate Backup+ Desk (5TB)
DEFAULT_DISK_UUID = "5260fcea-c15a-4e0f-8b31-95bca0dc0d63"
DEFAULT_BASE_MOUNT = f"/srv/dev-disk-by-uuid-{DEFAULT_DISK_UUID}"
DEFAULT_BIND_MOUNTS = [
    "/export/storage",
    "/export/pve-backups",
    "/export/pve-shared",
]


def log_info(msg: str) -> None:
    print(f"{BLUE}INFO{RESET}: {msg}")


def log_success(msg: str) -> None:
    print(f"{GREEN}SUCC{RESET}: {msg}")


def log_warn(msg: str) -> None:
    print(f"{YELLOW}WARN{RESET}: {msg}")


def log_error(msg: str) -> None:
    print(f"{RED}ERROR{RESET}: {msg}")


def run_ssh(host: str, cmd: str, timeout: int = 10) -> Tuple[int, str, str]:
    """Execute command over SSH with strict timeouts."""
    try:
        proc = subprocess.run(
            [
                "ssh",
                "-o",
                "BatchMode=yes",
                "-o",
                f"ConnectTimeout={timeout}",
                host,
                cmd,
            ],
            capture_output=True,
            text=True,
            timeout=timeout + 5,
        )
        return proc.returncode, proc.stdout.strip(), proc.stderr.strip()
    except subprocess.TimeoutExpired:
        return 124, "", f"Command timed out after {timeout}s"
    except Exception as e:
        return 1, "", str(e)


def check_status(
    omv_host: str = DEFAULT_OMV_HOST,
    pve_node: str = DEFAULT_PVE_NODE,
    vmid: str = DEFAULT_PVE_VMID,
    usb_id: str = DEFAULT_USB_ID,
    disk_uuid: str = DEFAULT_DISK_UUID,
    base_mount: str = DEFAULT_BASE_MOUNT,
    bind_mounts: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """Run comprehensive status checks across PVE host and OMV VM."""
    if bind_mounts is None:
        bind_mounts = DEFAULT_BIND_MOUNTS

    status: Dict[str, Any] = {
        "pve": {
            "node": pve_node,
            "vmid": vmid,
            "reachable": False,
            "vm_running": False,
            "host_usb_detected": False,
            "vm_passthrough_configured": False,
        },
        "omv": {
            "host": omv_host,
            "reachable": False,
            "usb_detected": False,
            "disk_detected": False,
            "base_mounted": False,
            "bind_mounts": {},
            "all_bind_mounts_ok": False,
            "nfs_active": False,
            "nfs_listening": False,
            "exports": [],
        },
        "healthy": False,
    }

    # 1. Check Proxmox Host
    pve_cmd = (
        f"qm status {vmid} 2>/dev/null; "
        f"echo '---'; "
        f"lsusb | grep -i '{usb_id}' 2>/dev/null; "
        f"echo '---'; "
        f"qm config {vmid} | grep -i '{usb_id}' 2>/dev/null"
    )
    rc, stdout, _ = run_ssh(pve_node, pve_cmd)
    if rc == 0:
        status["pve"]["reachable"] = True
        parts = [p.strip() for p in stdout.split("---")]
        if len(parts) >= 1 and "status: running" in parts[0]:
            status["pve"]["vm_running"] = True
        if len(parts) >= 2 and usb_id.lower() in parts[1].lower():
            status["pve"]["host_usb_detected"] = True
        if len(parts) >= 3 and usb_id.lower() in parts[2].lower():
            status["pve"]["vm_passthrough_configured"] = True

    # 2. Check OMV Guest VM
    bind_checks = " && ".join([f"mountpoint -q {bm}" for bm in bind_mounts])
    omv_cmd = (
        f"lsusb | grep -i '{usb_id}' 2>/dev/null; "
        f"echo '---'; "
        f"lsblk -o UUID | grep -i '{disk_uuid}' 2>/dev/null; "
        f"echo '---'; "
        f"mountpoint -q {base_mount} && echo 'mounted' || echo 'unmounted'; "
        f"echo '---'; "
        f"systemctl is-active nfs-server 2>/dev/null; "
        f"echo '---'; "
        f"ss -tulpn | grep -q ':2049 ' && echo 'listening' || echo 'down'; "
        f"echo '---'; "
        f"exportfs -v 2>/dev/null"
    )
    rc, stdout, _ = run_ssh(omv_host, omv_cmd)
    if rc == 0:
        status["omv"]["reachable"] = True
        parts = [p.strip() for p in stdout.split("---")]
        if len(parts) >= 1 and usb_id.lower() in parts[0].lower():
            status["omv"]["usb_detected"] = True
        if len(parts) >= 2 and disk_uuid.lower() in parts[1].lower():
            status["omv"]["disk_detected"] = True
        if len(parts) >= 3 and "mounted" in parts[2]:
            status["omv"]["base_mounted"] = True
        if len(parts) >= 4 and parts[3] == "active":
            status["omv"]["nfs_active"] = True
        if len(parts) >= 5 and "listening" in parts[4]:
            status["omv"]["nfs_listening"] = True
        if len(parts) >= 6 and parts[5]:
            status["omv"]["exports"] = [
                exp.strip() for exp in parts[5].splitlines() if exp.strip()
            ]

        # Check each bind mount individually
        all_bm = True
        for bm in bind_mounts:
            rc_bm, _, _ = run_ssh(omv_host, f"mountpoint -q {bm}")
            is_mounted = rc_bm == 0
            status["omv"]["bind_mounts"][bm] = is_mounted
            if not is_mounted:
                all_bm = False
        status["omv"]["all_bind_mounts_ok"] = all_bm

    # Evaluate Overall Health
    status["healthy"] = (
        status["omv"]["reachable"]
        and status["omv"]["usb_detected"]
        and status["omv"]["disk_detected"]
        and status["omv"]["base_mounted"]
        and status["omv"]["all_bind_mounts_ok"]
        and status["omv"]["nfs_active"]
        and status["omv"]["nfs_listening"]
    )

    return status


def fix_omv(
    omv_host: str = DEFAULT_OMV_HOST,
    pve_node: str = DEFAULT_PVE_NODE,
    vmid: str = DEFAULT_PVE_VMID,
    usb_id: str = DEFAULT_USB_ID,
    status_before: Optional[Dict[str, Any]] = None,
) -> Tuple[bool, List[str]]:
    """Remediate missing mounts and stopped NFS service."""
    actions_taken: List[str] = []

    if status_before is None:
        status_before = check_status(omv_host=omv_host, pve_node=pve_node, vmid=vmid, usb_id=usb_id)

    # 1. Hotplug USB on PVE host if detected on PVE but missing in OMV
    pve_info = status_before["pve"]
    omv_info = status_before["omv"]
    if pve_info.get("host_usb_detected") and not omv_info.get("usb_detected"):
        log_info(f"USB drive detected on {pve_node} but missing in VM {vmid}. Applying USB passthrough...")
        rc, _, stderr = run_ssh(pve_node, f"qm set {vmid} -usb0 host={usb_id}")
        if rc == 0:
            actions_taken.append(f"Hotplugged USB {usb_id} into VM {vmid} via {pve_node}")
        else:
            log_error(f"Failed to hotplug USB: {stderr}")

    # 2. Remount all fstab filesystems on OMV (base partition + bind mounts)
    if not (omv_info.get("base_mounted") and omv_info.get("all_bind_mounts_ok")):
        log_info("Remounting filesystems on OMV (`mount -a`)...")
        rc, _, stderr = run_ssh(omv_host, "mount -a")
        if rc == 0:
            actions_taken.append("Executed `mount -a` to mount storage and /export bind paths")
        else:
            log_error(f"Failed running mount -a: {stderr}")

    # 3. Start or restart NFS service
    log_info("Starting NFS server service on OMV...")
    rc, _, stderr = run_ssh(omv_host, "systemctl restart nfs-server")
    if rc == 0:
        actions_taken.append("Restarted `nfs-server.service`")
    else:
        log_error(f"Failed to restart nfs-server: {stderr}")

    # Re-check status
    status_after = check_status(omv_host=omv_host, pve_node=pve_node, vmid=vmid, usb_id=usb_id)
    return status_after["healthy"], actions_taken


def print_status(status: Dict[str, Any]) -> None:
    """Print clean Catppuccin Mocha terminal status view."""
    print(f"\n{BOLD}=== OpenMediaVault (OMV) NFS & Storage Status ==={RESET}")

    # Proxmox Host
    pve = status["pve"]
    pve_reach = f"{GREEN}Reachable{RESET}" if pve["reachable"] else f"{RED}Unreachable{RESET}"
    pve_usb = f"{GREEN}Detected{RESET}" if pve["host_usb_detected"] else f"{RED}Not Found{RESET}"
    pve_vm = f"{GREEN}Running{RESET}" if pve["vm_running"] else f"{RED}Stopped{RESET}"
    print(f"Host ({pve['node']}): {pve_reach} | VM {pve['vmid']}: {pve_vm} | Host USB: {pve_usb}")

    # OMV VM
    omv = status["omv"]
    omv_reach = f"{GREEN}Online{RESET}" if omv["reachable"] else f"{RED}Offline{RESET}"
    omv_usb = f"{GREEN}Detected{RESET}" if omv["usb_detected"] else f"{RED}Missing{RESET}"
    omv_disk = f"{GREEN}Present{RESET}" if omv["disk_detected"] else f"{RED}Missing{RESET}"
    omv_base = f"{GREEN}Mounted{RESET}" if omv["base_mounted"] else f"{RED}Unmounted{RESET}"
    print(f"OMV ({omv['host']}): {omv_reach} | Guest USB: {omv_usb} | Partition: {omv_disk} | Base Mount: {omv_base}")

    # Bind Mounts
    print(f"\n{BOLD}Bind Mounts (/export):{RESET}")
    for path, mounted in omv.get("bind_mounts", {}).items():
        state = f"{GREEN}Mounted{RESET}" if mounted else f"{RED}Unmounted{RESET}"
        print(f"  • {path}: {state}")

    # NFS Service
    nfs_act = f"{GREEN}Active{RESET}" if omv["nfs_active"] else f"{RED}Inactive / Dead{RESET}"
    nfs_port = f"{GREEN}Port 2049 Open{RESET}" if omv["nfs_listening"] else f"{RED}Port 2049 Closed{RESET}"
    print(f"\n{BOLD}NFS Service:{RESET} {nfs_act} | {nfs_port}")

    exports = omv.get("exports", [])
    if exports:
        print(f"Active Exports: {GREEN}{len(exports)} entries configured{RESET}")
    else:
        print(f"Active Exports: {RED}None{RESET}")

    print("--------------------------------------------------")
    if status["healthy"]:
        print(f"{GREEN}{BOLD}Overall State: HEALTHY (All mounts and NFS active){RESET}\n")
    else:
        print(f"{RED}{BOLD}Overall State: DEGRADED (Remediation needed via --fix){RESET}\n")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Verify and remediate OMV external drive and NFS service status."
    )
    parser.add_argument(
        "--host",
        default=DEFAULT_OMV_HOST,
        help=f"OMV SSH host (default: {DEFAULT_OMV_HOST})",
    )
    parser.add_argument(
        "--pve-node",
        default=DEFAULT_PVE_NODE,
        help=f"Proxmox host node (default: {DEFAULT_PVE_NODE})",
    )
    parser.add_argument(
        "--vmid",
        default=DEFAULT_PVE_VMID,
        help=f"OMV VM ID on Proxmox (default: {DEFAULT_PVE_VMID})",
    )
    parser.add_argument(
        "--fix",
        action="store_true",
        help="Automatically remount filesystems and start NFS server if down",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output structured JSON instead of formatted text",
    )

    args = parser.parse_args()

    status = check_status(omv_host=args.host, pve_node=args.pve_node, vmid=args.vmid)

    if args.fix and not status["healthy"]:
        log_info("Remediating OMV external drive mounts and NFS service...")
        healthy_after, actions = fix_omv(
            omv_host=args.host,
            pve_node=args.pve_node,
            vmid=args.vmid,
            status_before=status,
        )
        status = check_status(omv_host=args.host, pve_node=args.pve_node, vmid=args.vmid)
        if not args.json:
            for act in actions:
                log_success(act)

    if args.json:
        print(json.dumps(status, indent=2))
    else:
        print_status(status)

    return 0 if status["healthy"] else 1


if __name__ == "__main__":
    sys.exit(main())
