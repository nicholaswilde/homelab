# /gatus update

Update the `gatus` dashboard by syncing configuration changes, decrypting secrets, and restarting the service.

## Description
Syncs the `gatus` dashboard configuration via SSH, decrypts the `config.yaml` and `.env` files, and restarts the service to apply changes.

## Protocol

1. **Identify Configuration:**
   - The local configuration is in `lxc/gatus/`.

2. **Sync Configuration:**
   - The gatus LXC has the configs symlinked to `/root/git/nicholaswilde/homelab/lxc/gatus/`.
   - **Step:** Execute a `git pull` inside the LXC via SSH.
   - **Command:** `ssh root@192.168.2.220 "cd /root/git/nicholaswilde/homelab && git pull origin main"`

3. **Decrypt Secrets:**
   - **Step:** Run the `task decrypt` command inside the gatus directory via SSH.
   - **Command:** `ssh root@192.168.2.220 "cd /root/git/nicholaswilde/homelab/lxc/gatus && task decrypt"`

4. **Restart Service:**
   - **Step:** Restart the `gatus` service inside the LXC via SSH.
   - **Command:** `ssh root@192.168.2.220 "systemctl restart gatus"`

5. **Verify:**
   - Announce: "Gatus configuration synced, secrets decrypted, and service restarted."
