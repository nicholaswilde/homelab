# /homepage update

Update the `homepage` dashboard by syncing configuration changes and restarting the service.

## Description
Syncs the `homepage` dashboard configuration via SSH and restarts the service to apply changes.

## Protocol

1. **Identify Configuration:**
   - The local configuration is in `pve/homepage/config/`.

2. **Sync Configuration:**
   - The homepage LXC (vmid 110) on pve04 has the configs symlinked to `/root/git/nicholaswilde/homelab/pve/homepage/config/`.
   - **Step:** Execute a `git pull` inside the LXC via SSH.
   - **Command:** `ssh root@192.168.2.47 "cd /root/git/nicholaswilde/homelab && git pull origin main"`

3. **Restart Service:**
   - **Step:** Restart the `homepage` service inside the LXC via SSH.
   - **Command:** `ssh root@192.168.2.47 "systemctl restart homepage"`

4. **Verify:**
   - Announce: "Homepage configuration synced and service restarted."
