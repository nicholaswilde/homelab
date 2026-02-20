# /homelab update `<app_name>`

Pull updates and restart services for Docker and LXC applications.

## Protocol

1. **Identify Application:**
   - Search for `<app_name>` in `docker/`, `lxc/`, and `pve/`.
   - If not found, announce an error and halt.
   - If multiple matches found, ask the user to clarify.

2. **Determine Type:**
   - If in `docker/`, type is `docker`.
   - If in `lxc/`, type is `lxc`.
   - If in `pve/`, check for `compose.yaml` (docker) or `update.sh` (lxc).

3. **Execute Update:**
   - Use `scripts/homelab_update.py` to:
     - For `docker`: Run `docker compose pull` and `docker compose up -d`.
     - For `lxc`: Run `./update.sh`.
     - Log all output.

4. **Update All (Optional):**
   - If `--all` flag is provided, iterate through all active services and perform the update.

5. **Announce Completion:**
   - Inform the user that the update is complete and provide status summary.
