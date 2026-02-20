# /pve sync

Trigger synchronization tasks and verify that DNS rewrites and configurations are consistent across multiple Proxmox nodes.

## Protocol

1. **Trigger AdGuard Home Sync:**
   - Execute `run_shell_command` to restart the `adguardhome-sync.service` on the master node: `sudo systemctl restart adguardhome-sync.service`.
   - Announce: "AdGuard Home synchronization triggered."

2. **Verify Traefik Configuration Consistency:**
   - For each Proxmox node (`pve01`, `pve03`, `pve04`):
     - Identify all YAML configuration files in `/etc/traefik/conf.d/` on each node (via appropriate shell commands).
     - Compare the list of files and their contents with the master repository in `pve/traefik/conf.d/`.
     - Summarize any discrepancies (missing files, different contents).
   - Announce: "Traefik configuration consistency check complete."

3. **Check AdGuard Home DNS Rewrites Consistency:**
   - Use `manage_dns` (with `action="list_rewrites"`) for each AdGuard Home instance (e.g., `primary`, `replica1`, etc. - I'll need to check how to target different instances).
   - Compare the list of rewrites across all instances.
   - Summarize any discrepancies.
   - Announce: "AdGuard Home DNS rewrites consistency check complete."

4. **Present Unified Sync Report:**
   - Output a combined report detailing the status of the sync and any inconsistencies found in Traefik or AdGuard Home.
   - If any inconsistencies are found, provide recommendations for manual resolution.
