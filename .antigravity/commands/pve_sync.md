# /pve sync

Trigger synchronization tasks and verify that DNS rewrites and configurations are consistent across multiple Proxmox nodes and Syncthing instances.

## Protocol

1. **Trigger AdGuard Home Sync:**
   - Execute `mcp_adguardhome_sync_instances` to synchronize configuration from the master to replica instances.
   - Announce: "AdGuard Home synchronization triggered via MCP."

2. **Verify Traefik Configuration Consistency:**
   - For each Proxmox node (`pve01`, `pve03`, `pve04`):
     - Identify all YAML configuration files in `/etc/traefik/conf.d/` on each node (via appropriate shell commands).
     - Compare the list of files and their contents with the master repository in `pve/traefik/conf.d/`.
     - Summarize any discrepancies (missing files, different contents).
   - Announce: "Traefik configuration consistency check complete."

3. **Check AdGuard Home DNS Rewrites Consistency:**
   - Use `mcp_adguardhome_manage_dns` (with `action="list_rewrites"`) for each AdGuard Home instance (e.g., `primary`, `replica1`).
   - Compare the list of rewrites across all instances.
   - Summarize any discrepancies.
   - Announce: "AdGuard Home DNS rewrites consistency check complete."

4. **Verify Syncthing Configuration Consistency:**
   - Use `syncthing_diff_instance_configs` to compare configurations between Syncthing instances (if multiple instances are configured).
   - Use `syncthing_get_global_dashboard` to ensure all instances are online and synced.
   - Announce: "Syncthing configuration consistency check complete."

5. **Present Unified Sync Report:**
   - Output a combined report detailing the status of the sync and any inconsistencies found in Traefik, AdGuard Home, or Syncthing.
   - If any inconsistencies are found, provide recommendations for manual resolution.
