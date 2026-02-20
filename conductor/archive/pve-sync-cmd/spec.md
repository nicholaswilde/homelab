# Spec: /pve sync command

## :dart: Goal
Trigger synchronization tasks and verify that DNS rewrites and configurations are consistent across multiple Proxmox nodes.

## :gear: Requirements
- Trigger `adguardhome-sync` or similar sync tools.
- Verify consistency of Traefik configs in `pve/traefik/conf.d/`.
- Check AdGuard Home DNS rewrites consistency across nodes.

## :link: References
- [AdGuard Home Sync](https://github.com/bakito/adguardhome-sync)
- [Traefik Configuration](https://doc.traefik.io/traefik/routing/providers/file/)
