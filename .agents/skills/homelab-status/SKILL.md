---
name: homelab-status
description: Provide a bird's eye view of the homelab, checking Proxmox node health, Docker containers, AdGuard Home, Syncthing, and GitHub issues.
---

# /homelab status

Provide a "bird's eye view" of the lab, checking Proxmox node health, listing active Docker containers, and reporting on AdGuard Home, Syncthing, and open GitHub issues.

## Protocol

1. **Check Proxmox Status:**
   - Execute `pve01__get_cluster_status` to get the overall cluster state.
   - Execute `pve01__list_nodes` to get the status of individual nodes (`pve01`, `pve03`, `pve04`).
   - Summarize node status (online/offline) and resource usage if available.

2. **Check Docker Container Status:**
   - Identify all directories in `docker/` that contain a `compose.yaml` file.
   - For each directory, run `docker compose ps --format json` (or similar) to check the status of containers.
   - Summarize which applications are "Up" and which are "Down" or "Exited".

3. **Check Core Services Status:**
   - **AdGuard Home:** Execute `mcp_adguardhome_manage_system` with `action: "get_status"` to verify version and protection state.
   - **Syncthing:** Execute `syncthing_get_global_dashboard` to check instance connectivity and aggregated bandwidth.

4. **Check Open Issues Status:**
   - Run `rtk gh issue list -L 10 | cat`.
   - Summarize top active open issues or feature requests.

5. **Present Unified Status Report:**
   - Output a combined report with sections for Proxmox, Docker, Core Services (AdGuard, Syncthing), and GitHub Issues.
   - Highlight any offline nodes, stopped containers, or urgent issues.
