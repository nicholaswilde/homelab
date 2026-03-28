# /app sync `<app_name>`

Sync local configuration changes to a remote Proxmox LXC and restart the service.

## Description
This command automates the workflow of committing local changes, pushing them to the remote repository, pulling them on the target Proxmox LXC container, and restarting the service to apply changes.

## Protocol

1. **Commit and Push:**
   - **Step:** Stage the changes for `<app_name>`.
   - **Step:** Commit the changes with a descriptive message (e.g., `chore(<app_name>): update configuration`).
   - **Step:** Push the changes to the remote repository (`git push origin main`).

2. **Identify Remote Target:**
   - **Step:** Use `mcp_pve03_list_containers` and `mcp_pve04_list_containers` to find the node and VMID for `<app_name>`.
   - **Note:** If the app name in Proxmox differs from `<app_name>`, search for close matches.

3. **Sync on Remote:**
   - **Step:** SSH into the Proxmox node and execute a `git pull` inside the LXC container.
   - **Command:** `ssh root@<node> "pct exec <vmid> -- git -C /root/git/nicholaswilde/homelab pull"`
   - **Note:** The repository path might vary; default to `/root/git/nicholaswilde/homelab/`.

4. **Restart Service:**
   - **Step:** Identify the service name (usually `<app_name>.service` or just `<app_name>`).
   - **Step:** Execute a restart command inside the LXC container via SSH.
   - **Command:** `ssh root@<node> "pct exec <vmid> -- systemctl restart <service_name>"`

5. **Verify:**
   - **Step:** Check the service status to ensure it restarted successfully.
   - **Command:** `ssh root@<node> "pct exec <vmid> -- systemctl status <service_name>"`
   - **Announce:** "Successfully synced and restarted `<app_name>` on `<node>` (VMID `<vmid>`)."
