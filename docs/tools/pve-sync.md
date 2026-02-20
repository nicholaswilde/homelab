---
tags:
  - automation
  - proxmox
  - adguardhome
  - traefik
---
# :material-sync: PVE Sync

The PVE Sync tool is used to trigger synchronization tasks across Proxmox nodes and verify configuration consistency for AdGuard Home and Traefik.

## :hammer_and_wrench: Installation

The sync script is located in `scripts/pve_sync.py`. It requires `python3`.

## :pencil: Usage

### :simple-gemini: Gemini CLI

You can trigger the sync process via the Gemini CLI:

```shell
/pve sync
```

### :material-console: Manual Execution

Alternatively, you can run the script directly:

```shell
python3 scripts/pve_sync.py
```

## :gear: How it Works

1. **AdGuard Home Sync:** Restarts the `adguardhome-sync.service` on the master node to trigger a synchronization of DNS rewrites and filters to replica instances.
2. **Traefik Consistency:** Scans the `pve/traefik/conf.d/` directory in the repository and (manually or via future automation) verifies that these files exist and match on all Proxmox nodes.
3. **DNS Rewrite Verification:** Encourages manual verification of DNS rewrites across all AdGuard Home instances using the `manage_dns` tool.

## :link: References

- [AdGuard Home Sync](https://github.com/bakito/adguardhome-sync)
- [Traefik File Provider](https://doc.traefik.io/traefik/routing/providers/file/)
