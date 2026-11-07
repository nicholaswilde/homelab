# Agent Skills Catalog

Catalog of custom Antigravity agent skills available in `homelab`.

| Skill | Description | Task / Command |
|---|---|---|
| [`app-remove`](skills/app-remove/SKILL.md) | Automate the removal of a service from the homelab, including Traefik configs, DNS rewrites, and Homepage dashboard entries. | `/app remove <name>` |
| [`app-sync`](skills/app-sync/SKILL.md) | Sync local configuration changes to a remote Proxmox LXC container via git pull and restart the service. | `/app sync <app_name>` |
| [`audit-deps`](skills/audit-deps/SKILL.md) | Audit Docker image dependencies across all compose.yaml files and report outdated or vulnerable versions. | `/audit deps` |
| [`builder-add`](skills/builder-add/SKILL.md) | Automate adding a new application builder to the reprepro modular builders system, supporting standard and Raspberry Pi architectures (armv6, armv7). | `/builder add <project> <url>` |
| [`check-app-version`](skills/check-app-version/SKILL.md) | Compare installed version of a homelab LXC web app against its latest upstream release without modifying containers or updating. | `rtk uv run python scripts/check_app_version.py <app>` |
| [`check-notify-apps`](skills/check-notify-apps/SKILL.md) | Compare GitHub release notifications with homelab web application versions across Proxmox LXC containers and Docker apps. | `rtk uv run python scripts/check_notify_apps.py` |
| [`check-notify-tools`](skills/check-notify-tools/SKILL.md) | Compare GitHub release notifications with locally installed developer tools (e.g. zensical, task, shuck, uv, lnav). | `rtk uv run python scripts/check_notify_tools.py` |
| [`check-secrets`](skills/check-secrets/SKILL.md) | Verify encryption status of all sensitive and .env files project-wide using SOPS to prevent accidental leaks. | `/check secrets` |
| [`dashboard-add`](skills/dashboard-add/SKILL.md) | Automate the addition of a new service with verified icons and URLs to the Homepage dashboard. | `/dashboard add <app_name> <group>` |
| [`deploy-app`](skills/deploy-app/SKILL.md) | Automate the creation and templating of a new application directory in docker/ or lxc/ and optionally open a tracking GitHub issue. | `/deploy <app_name> <type>` |
| [`doc-new`](skills/doc-new/SKILL.md) | Automate the creation of new documentation files using existing templates consistent with Zensical style guide. | `/doc new <name> <category>` |
| [`gatus-update`](skills/gatus-update/SKILL.md) | Update the Gatus dashboard by syncing configuration changes, decrypting secrets, and restarting the service. | `/gatus update` |
| [`homelab-backup`](skills/homelab-backup/SKILL.md) | Trigger manual backups for specific homelab applications or configurations and verify SOPS encryption. | `/homelab backup <target>` |
| [`homelab-status`](skills/homelab-status/SKILL.md) | Provide a bird's eye view of the homelab, checking Proxmox node health, Docker containers, AdGuard Home, Syncthing, and GitHub issues. | `/homelab status` |
| [`homelab-update`](skills/homelab-update/SKILL.md) | Pull updates and restart services for Docker and Proxmox LXC web applications. | `/homelab update <app_name>` |
| [`homepage-update`](skills/homepage-update/SKILL.md) | Update the Homepage dashboard by syncing configuration changes via SSH and restarting the service. | `/homepage update` |
| [`omv-nfs`](skills/omv-nfs/SKILL.md) | Verify and restore OpenMediaVault (OMV) external USB hard drive connection, bind mounts, and NFS service after power outages or disconnections. | `rtk uv run python scripts/omv_nfs.py` |
| [`pve-log`](skills/pve-log/SKILL.md) | Fetch and summarize recent system and cluster logs from a specific Proxmox node or service. | `/pve log <node> [service]` |
| [`pve-sync`](skills/pve-sync/SKILL.md) | Trigger synchronization tasks and verify consistency across Proxmox nodes, AdGuard Home DNS rewrites, Traefik configs, and Syncthing. | `/pve sync` |
| [`pve-wake`](skills/pve-wake/SKILL.md) | Check if Proxmox VE nodes (default pve03) are online and automatically send Wake-on-LAN magic packets to wake them if offline. | `rtk uv run python scripts/pve_wake.py` |
| [`rotate-secret`](skills/rotate-secret/SKILL.md) | Securely rotate sensitive credentials by generating new high-entropy values and updating SOPS encrypted files. | `/rotate secret <service> <key>` |
| [`task-summary`](skills/task-summary/SKILL.md) | Automatically summarize work done in the current task and draft Git commit/note content. | `/task summary` |
| [`traefik-update`](skills/traefik-update/SKILL.md) | Update the Traefik edge router by syncing configuration changes via SSH and restarting the service. | `/traefik update` |
| [`webhook-add`](skills/webhook-add/SKILL.md) | Scaffold, deploy, and connect automated webhook update listeners and ChangeDetection watches for homelab LXC web applications. | `/webhook add <app_name> <repo>` |
