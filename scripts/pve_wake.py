#!/usr/bin/env python3
"""Proxmox Node Wake & Health Check Automation Tool.

Verifies whether a Proxmox VE node (default: pve03) is online and reachable.
If offline, sends Wake-on-LAN magic packets and polls until the host and
its cluster services are restored.
"""

import argparse
import json
import socket
import subprocess
import sys
import time
from typing import Any, Dict, Optional, Tuple

# Catppuccin Mocha Colors
BLUE = "\033[38;2;137;180;250m"
RED = "\033[38;2;243;139;168m"
GREEN = "\033[38;2;166;227;161m"
YELLOW = "\033[38;2;249;226;175m"
CYAN = "\033[38;2;148;226;213m"
GRAY = "\033[38;2;108;112;134m"
BOLD = "\033[1m"
RESET = "\033[0m"

# Known Homelab Nodes Configuration
KNOWN_NODES: Dict[str, Dict[str, str]] = {
    "pve03": {
        "ip": "192.168.1.141",
        "mac": "1c:69:7a:a6:86:d5",
        "broadcast": "192.168.1.255",
    },
    "pve01": {
        "ip": "192.168.1.128",
        "mac": "",
        "broadcast": "192.168.1.255",
    },
    "pve04": {
        "ip": "192.168.1.66",
        "mac": "",
        "broadcast": "192.168.1.255",
    },
}

DEFAULT_NODE = "pve03"


def log_info(msg: str) -> None:
    print(f"{BLUE}INFO{RESET}: {msg}")


def log_success(msg: str) -> None:
    print(f"{GREEN}SUCC{RESET}: {msg}")


def log_warn(msg: str) -> None:
    print(f"{YELLOW}WARN{RESET}: {msg}")


def log_error(msg: str) -> None:
    print(f"{RED}ERROR{RESET}: {msg}")


def ping_node(ip: str, timeout: int = 1) -> bool:
    """Send ICMP ping packet to test node reachability."""
    try:
        res = subprocess.run(
            ["ping", "-c", "1", "-W", str(timeout), ip],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return res.returncode == 0
    except Exception:
        return False


def run_ssh(host: str, cmd: str, timeout: int = 5) -> Tuple[int, str, str]:
    """Execute command over SSH with strict timeout."""
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
            timeout=timeout + 3,
        )
        return proc.returncode, proc.stdout.strip(), proc.stderr.strip()
    except subprocess.TimeoutExpired:
        return 124, "", f"SSH command timed out after {timeout}s"
    except Exception as e:
        return 1, "", str(e)


def send_wol_packet(mac_address: str, broadcast_ip: str = "192.168.1.255", port: int = 9) -> bool:
    """Send a Wake-on-LAN magic packet over UDP broadcast."""
    cleaned_mac = mac_address.replace(":", "").replace("-", "")
    if len(cleaned_mac) != 12:
        log_error(f"Invalid MAC address: {mac_address}")
        return False

    try:
        mac_bytes = bytes.fromhex(cleaned_mac)
        magic_packet = b"\xff" * 6 + mac_bytes * 16

        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
            sock.sendto(magic_packet, (broadcast_ip, port))
            # Also send to global broadcast as fallback
            try:
                sock.sendto(magic_packet, ("255.255.255.255", port))
            except Exception:
                pass
        return True
    except Exception as e:
        log_error(f"Failed sending WOL packet: {e}")
        return False


def send_wol_via_helper(helper_node: str, mac_address: str, broadcast_ip: str = "192.168.1.255") -> bool:
    """Send WOL packet from another online Proxmox node to ensure multi-segment broadcast."""
    cleaned_mac = mac_address.replace(":", "").replace("-", "")
    python_cmd = (
        f"import socket; s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); "
        f"s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1); "
        f"s.sendto(b'\\xff'*6 + bytes.fromhex('{cleaned_mac}')*16, ('{broadcast_ip}', 9)); s.close()"
    )
    rc, _, _ = run_ssh(helper_node, f"python3 -c \"{python_cmd}\"", timeout=4)
    return rc == 0


def get_node_details(node_name: str) -> Dict[str, Any]:
    """Retrieve operational details once node is online."""
    details: Dict[str, Any] = {
        "uptime": None,
        "load": None,
        "cluster_quorate": False,
        "active_guests": 0,
        "total_guests": 0,
    }
    rc, out, _ = run_ssh(node_name, "uptime; echo '===SECTION==='; pvecm status 2>/dev/null; echo '===SECTION==='; pct list 2>/dev/null; qm list 2>/dev/null")
    if rc == 0:
        parts = [p.strip() for p in out.split("===SECTION===")]
        if len(parts) >= 1 and parts[0]:
            details["uptime"] = parts[0]
        if len(parts) >= 2 and "Quorate:          Yes" in parts[1]:
            details["cluster_quorate"] = True
        if len(parts) >= 3 and parts[2]:
            lines = [l for l in parts[2].splitlines() if l.strip() and not l.startswith("VMID")]
            details["total_guests"] += len(lines)
            details["active_guests"] += sum(1 for l in lines if "running" in l.lower())
    return details


def ensure_node_on(
    node_name: str = DEFAULT_NODE,
    timeout_sec: int = 60,
    check_only: bool = False,
    force_wake: bool = False,
) -> Dict[str, Any]:
    """Ensure node is powered on, waking it via WOL if offline."""
    node_cfg = KNOWN_NODES.get(node_name, {})
    ip = node_cfg.get("ip", node_name)
    mac = node_cfg.get("mac", "")
    broadcast = node_cfg.get("broadcast", "192.168.1.255")

    result: Dict[str, Any] = {
        "node": node_name,
        "ip": ip,
        "mac": mac,
        "initially_online": False,
        "woken_up": False,
        "final_online": False,
        "details": {},
    }

    # 1. Initial Reachability Check
    is_pingable = ping_node(ip)
    is_sshable = False
    if is_pingable:
        rc, _, _ = run_ssh(node_name, "hostname", timeout=3)
        is_sshable = (rc == 0)

    result["initially_online"] = is_pingable and is_sshable

    if result["initially_online"] and not force_wake:
        result["final_online"] = True
        result["details"] = get_node_details(node_name)
        return result

    if check_only:
        result["final_online"] = result["initially_online"]
        return result

    # 2. Node is Offline or Force Wake Requested
    if not mac:
        log_error(f"Cannot wake {node_name}: No MAC address configured")
        return result

    log_info(f"Node {node_name} ({ip}) is offline. Broadcasting Wake-on-LAN packet to {mac}...")
    send_wol_packet(mac, broadcast_ip=broadcast)

    # Also broadcast via pve01 as helper if reachable
    if node_name != "pve01" and ping_node("192.168.1.128"):
        send_wol_via_helper("pve01", mac, broadcast_ip=broadcast)

    result["woken_up"] = True

    # 3. Poll Until Node Comes Online
    log_info(f"Waiting up to {timeout_sec}s for {node_name} to boot and respond...")
    start_time = time.time()
    while time.time() - start_time < timeout_sec:
        time.sleep(3)
        if ping_node(ip):
            rc, _, _ = run_ssh(node_name, "hostname", timeout=3)
            if rc == 0:
                result["final_online"] = True
                log_success(f"Node {node_name} is online and accepting SSH commands!")
                result["details"] = get_node_details(node_name)
                return result

    log_error(f"Node {node_name} did not come online within {timeout_sec} seconds.")
    return result


def print_status(res: Dict[str, Any]) -> None:
    """Print Catppuccin Mocha formatted output."""
    node = res["node"]
    ip = res["ip"]
    online = res["final_online"]

    print(f"\n{BOLD}=== Proxmox Node Status: {node} ==={RESET}")
    state_str = f"{GREEN}ONLINE{RESET}" if online else f"{RED}OFFLINE{RESET}"
    print(f"Target: {node} ({ip}) | State: {state_str}")

    if res.get("woken_up"):
        print(f"Action: {YELLOW}Wake-on-LAN magic packet transmitted{RESET}")

    details = res.get("details", {})
    if details.get("uptime"):
        print(f"Uptime: {details['uptime']}")
    if details.get("cluster_quorate"):
        print(f"Cluster Quorum: {GREEN}Quorate (Active member){RESET}")
    if details.get("total_guests", 0) > 0:
        act = details.get("active_guests", 0)
        tot = details.get("total_guests", 0)
        print(f"LXC Containers: {GREEN}{act}/{tot} running{RESET}")

    print("---------------------------------------------")
    if online:
        print(f"{GREEN}{BOLD}Result: SUCCESS (Node {node} is operational){RESET}\n")
    else:
        print(f"{RED}{BOLD}Result: FAILED (Node {node} remains offline){RESET}\n")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Verify that a Proxmox node is on and send WOL if offline."
    )
    parser.add_argument(
        "--node",
        default=DEFAULT_NODE,
        help=f"Target Proxmox node name (default: {DEFAULT_NODE})",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=60,
        help="Max seconds to wait for node boot (default: 60)",
    )
    parser.add_argument(
        "--check-only",
        action="store_true",
        help="Check status only, do not send WOL if offline",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Send WOL packet even if node currently responds",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output JSON summary",
    )

    args = parser.parse_args()

    res = ensure_node_on(
        node_name=args.node,
        timeout_sec=args.timeout,
        check_only=args.check_only,
        force_wake=args.force,
    )

    if args.json:
        print(json.dumps(res, indent=2))
    else:
        print_status(res)

    return 0 if res["final_online"] else 1


if __name__ == "__main__":
    sys.exit(main())
