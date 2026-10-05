# /app version `<app_name>`

Compare installed version of a homelab LXC web app to its latest upstream release.

## Description
Checks the current running/installed version of an application (such as `stirling-pdf`, `drawio`, `wallos`, `changedetection`, `localsend`) against its latest release on GitHub / upstream repository without modifying the system or triggering an update.

## Protocol

1. **Run Version Check:**
   - Execute token-optimized version checker:
     ```bash
     rtk uv run python scripts/check_app_version.py <app_name>
     ```
   - To check all known homelab web applications:
     ```bash
     rtk uv run python scripts/check_app_version.py --all
     ```
   - To force a specific Proxmox node:
     ```bash
     rtk uv run python scripts/check_app_version.py <app_name> --node <pve_node>
     ```
   - For JSON output:
     ```bash
     rtk uv run python scripts/check_app_version.py <app_name> --json
     ```

2. **Evaluate Output:**
   - Compare `Installed` against `Latest`.
   - Statuses:
     - `Up to date`: Current installation matches latest upstream release.
     - `Update available`: New upstream version detected (`<installed>` -> `<latest>`).
     - `Installed only` / `Latest only`: One side detected, inspect network or container.
     - `Not configured`: App needs upstream repo mapping in `scripts/check_app_version.py` or `update.sh`.

3. **Follow-up Action:**
   - If update is available and user requests an upgrade, run:
     ```bash
     rtk uv run python scripts/lxc_update.py <app_name>
     ```
