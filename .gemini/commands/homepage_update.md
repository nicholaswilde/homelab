# /homepage update

Update the `homepage` dashboard by syncing configuration changes and restarting the service.

## Description
Syncs the `homepage` dashboard configuration and restarts the service to apply changes.

## Protocol

1. **Identify Configuration:**
   - The local configuration is in `pve/homepage/config/`.

2. **Sync Configuration:**
   - The homepage LXC (vmid 110) on pve04 has the configs symlinked to `/root/git/nicholaswilde/homelab/pve/homepage/config/`.
   - Ensure local changes are committed and pushed.

3. **Restart Service:**
   - Execute `task restart` within the `pve/homepage` directory.
   - Alternatively, use `mcp_pve04_manage_resource_config` to execute `systemctl restart homepage` in LXC 110.

4. **Verify:**
   - Announce: "Homepage configuration updated and service restarted."
