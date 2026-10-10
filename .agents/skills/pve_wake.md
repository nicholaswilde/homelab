# /pve wake [node]

Ensure that Proxmox VE nodes (default: `pve03`) are powered on and reachable, sending Wake-on-LAN packets if offline.

## Description
Following power events, unexpected physical button presses, or shutdowns, secondary Proxmox nodes such as `pve03` may remain offline while the primary node boots. This command checks ping and SSH reachability, sends a Wake-on-LAN magic packet if offline, and polls until the node, its cluster membership, and its guest containers are restored.

## Protocol

1. **Run Check & Wake**:
   ```bash
   rtk uv run python scripts/pve_wake.py
   ```
   Or check only without waking:
   ```bash
   rtk uv run python scripts/pve_wake.py --check-only
   ```

2. **Evaluate Output**:
   - `ONLINE`: Node is up and accepting SSH commands. Reports uptime, quorum, and active guest counts.
   - `WOL Sent`: Magic packet broadcast to `1c:69:7a:a6:86:d5`. Script waits up to 60s for boot.
   - `FAILED`: Node failed to respond within timeout. Physical power button check required.
