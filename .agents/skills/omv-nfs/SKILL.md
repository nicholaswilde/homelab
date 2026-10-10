---
name: omv-nfs
description: Verify and restore OpenMediaVault (OMV) external USB hard drive connection, bind mounts, and NFS service after power outages or disconnections.
---

# OMV NFS & External Storage Management

Runbook and automated workflow for checking and recovering OpenMediaVault external USB hard drives and NFS services after host reboots, power cuts, or storage disconnects.

## When to Use
- User states power went out or host rebooted and external hard drive needs checking.
- User asks: "is my hard drive plugged into OMV?"
- User asks: "is NFS running on OMV?"
- User asks: "fix or restore OMV NFS mounts".
- Storage client (Proxmox backup, media server) reports NFS connection or mount timeouts.

## Quick CLI Automation
Always run with `rtk` and `uv`:

```bash
# Check status (read-only verification across PVE and OMV)
rtk uv run python scripts/omv_nfs.py

# Check status with structured JSON
rtk uv run python scripts/omv_nfs.py --json

# Automatically remediate (hotplug USB if needed, mount -a, start nfs-server)
rtk uv run python scripts/omv_nfs.py --fix
```

## Architecture & Infrastructure Details
- **Proxmox Node**: `pve01` (192.168.1.128)
- **Guest VM**: ID `100` (`omv`, 192.168.1.203, user: `root`)
- **USB Hard Drive**: Seagate Backup+ Desk 5TB (`0bc2:ab31`)
- **Storage Filesystem**: `UUID=5260fcea-c15a-4e0f-8b31-95bca0dc0d63`
- **Base Mount Point**: `/srv/dev-disk-by-uuid-5260fcea-c15a-4e0f-8b31-95bca0dc0d63`
- **NFS Bind Mounts**:
  - `/export/storage` -> `/srv/.../storage`
  - `/export/pve-backups` -> `/srv/.../pve-backups`
  - `/export/pve-shared` -> `/srv/.../pve-shared`
- **NFS Service**: `nfs-server.service` (listening on port `2049`)

## Manual Recovery Steps (if needed without script)
1. Verify USB visibility on Proxmox host:
   ```bash
   ssh pve01 "lsusb | grep 0bc2:ab31"
   ```
2. If attached to host but missing in VM, attach USB passthrough:
   ```bash
   ssh pve01 "qm set 100 -usb0 host=0bc2:ab31"
   ```
3. Inside OMV guest, remount filesystems:
   ```bash
   ssh omv "mount -a"
   ```
4. Start NFS server and verify exports:
   ```bash
   ssh omv "systemctl start nfs-server && exportfs -v"
   ```
