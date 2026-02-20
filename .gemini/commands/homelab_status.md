# /homelab status

Provide a "bird's eye view" of the lab, checking Proxmox node health, listing active Docker containers, and reporting on active Conductor tracks.

## Protocol

1. **Check Proxmox Status:**
   - Execute `pve01__get_cluster_status` to get the overall cluster state.
   - Execute `pve01__list_nodes` to get the status of individual nodes (`pve01`, `pve03`, `pve04`).
   - Summarize node status (online/offline) and resource usage if available.

2. **Check Docker Container Status:**
   - Identify all directories in `docker/` that contain a `compose.yaml` file.
   - For each directory, run `docker compose ps --format json` (or similar) to check the status of containers.
   - Summarize which applications are "Up" and which are "Down" or "Exited".

3. **Check Conductor Track Status:**
   - Read `conductor/tracks.md`.
   - Parse the list of tracks and their statuses (`[ ]`, `[~]`, `[x]`).
   - Identify any track currently "In Progress" (`[~]`).

4. **Present Unified Status Report:**
   - Output a combined report with sections for Proxmox, Docker, and Conductor.
   - Highlight any offline nodes, stopped containers, or active tasks.
