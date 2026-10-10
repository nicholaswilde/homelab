---
name: pve-wake
description: Check if Proxmox VE nodes (default pve03) are online and automatically send Wake-on-LAN magic packets to wake them if offline.
---

# Proxmox Node Wake & Health Check

Workflow and CLI automation to ensure that Proxmox cluster nodes (specifically `pve03`) are online, and send Wake-on-LAN magic packets when offline after power outages or accidental shutdowns.

## When to Use
- User asks: "check on pve03 status"
- User asks: "is pve03 on?" or "wake up pve03"
- Services hosted on `pve03` (`apt-cacher-ng`, `authentik`, `gitea`, `vaultwarden`, `immich`, `wallos`, etc.) are unreachable.
- After a power outage to verify and restore cluster node quorum.

## Quick CLI Automation
Always run with `rtk` and `uv`:

```bash
# Verify pve03 is on; wake via Wake-on-LAN if offline and wait for boot
rtk uv run python scripts/pve_wake.py

# Check status without sending WOL if offline
rtk uv run python scripts/pve_wake.py --check-only

# Force transmission of WOL magic packet even if responding
rtk uv run python scripts/pve_wake.py --force

# Output structured JSON for automation
rtk uv run python scripts/pve_wake.py --json
```

## Node Details
- **Node**: `pve03`
- **IP**: `192.168.1.141`
- **MAC Address**: `1c:69:7a:a6:86:d5`
- **Broadcast IP**: `192.168.1.255`
- **Port**: UDP 9 / 7
- **Cluster**: Member of cluster `pxe01` with `pve01` and QDevice (`192.168.1.250`).
