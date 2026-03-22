# /traefik update

Update the `traefik` edge router by syncing configuration changes and restarting the service.

## Description
Syncs the `traefik` configuration via SSH and restarts the service to apply changes.

## Protocol

1. **Identify Configuration:**
   - The configuration is in `pve/traefik/`.

2. **Sync Configuration:**
   - The traefik LXC (vmid 111) on pve04 has the repo in `/root/git/nicholaswilde/homelab/`.
   - **Step:** Execute a `git pull` inside the LXC via SSH.
   - **Command:** `ssh root@192.168.2.46 "cd /root/git/nicholaswilde/homelab && git pull origin main"`

3. **Restart Service:**
   - **Step:** Restart the `traefik` service inside the LXC via SSH.
   - **Command:** `ssh root@192.168.2.46 "systemctl restart traefik"`

4. **Verify:**
   - Announce: "Traefik configuration synced and service restarted."
