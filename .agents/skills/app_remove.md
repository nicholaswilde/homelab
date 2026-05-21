# /app remove `<name>`

Automate the removal of a service from the homelab, including Traefik, DNS, and Homepage.

## Description
Removes a service's Traefik configuration, DNS rewrites, and dashboard entry, then synchronizes changes.

## Protocol

1. **Verify Existence:**
   - Check if `pve/traefik/conf.d/<name>.yaml` exists.
   - Check if `<name>` exists in `pve/homepage/config/services.yaml`.
   - List DNS rewrites to confirm if a rewrite exists for `<name>.l.nicholaswilde.io`.

2. **Removal:**
   - **Traefik:** Delete `pve/traefik/conf.d/<name>.yaml` (if it exists).
   - **Dashboard:** Use `scripts/dashboard_remove.py <name>` to remove the entry from the homepage.
   - **DNS:** Use `mcp_adguardhome_manage_dns` with `action: remove_rewrite` to delete the rewrite.

3. **Synchronization:**
   - Git add, commit, and push the configuration changes.
   - Execute `/traefik update` to refresh the edge router.
   - Execute `/homepage update` to refresh the dashboard.

4. **Verify:**
   - Announce: "Service `<name>` has been fully removed and configurations synchronized."
