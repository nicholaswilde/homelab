# /omv nfs

Check and remediate OpenMediaVault external USB hard drive connection, bind mounts, and NFS service.

## Description
When power outages or storage disconnections occur, the external USB hard drive on OpenMediaVault (`omv`) on Proxmox node `pve01` may lose its bind mounts or the `nfs-server` service may enter an inactive state. This skill automates the diagnosis and restoration of the storage mounts and NFS export services.

## Protocol

1. **Check Status**:
   - Run the health check tool:
     ```bash
     rtk uv run python scripts/omv_nfs.py
     ```
   - For machine-readable output:
     ```bash
     rtk uv run python scripts/omv_nfs.py --json
     ```

2. **Evaluate Output**:
   - Check if host USB is detected on `pve01`.
   - Check if OMV sees the disk partition (`UUID=5260fcea-c15a-4e0f-8b31-95bca0dc0d63`).
   - Check if base mount and `/export` bind mounts are mounted.
   - Check if `nfs-server` is active and port 2049 is open.

3. **Remediate (if degraded)**:
   - Run automated fix:
     ```bash
     rtk uv run python scripts/omv_nfs.py --fix
     ```
   - This ensures USB passthrough on `pve01`, mounts filesystems via `mount -a` in OMV, and restarts `nfs-server.service`.
