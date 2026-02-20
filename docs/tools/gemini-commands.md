# :gem: Gemini CLI Commands

This document describes the custom commands available in the Gemini CLI for the Homelab project.

## :house: /homelab status

Provide a "bird's eye view" of the lab, checking Proxmox node health, listing active Docker containers, and reporting on active Conductor tracks.

### :pencil: Usage

```bash
/homelab status
```

### :gear: Implementation

The command performs the following checks:
1. **Proxmox Status:** Uses `pve04__get_cluster_status` and `pve04__list_nodes` to report node health and resource usage.
2. **Docker Status:** Maps subdirectories in `docker/` containing `compose.yaml` and lists running containers using `docker ps`.
3. **Conductor Status:** Parses `conductor/tracks.md` to identify active tracks and their progress.

### :link: References
- [Conductor Workflow](../../conductor/workflow.md)
- [Proxmox API](https://pve.proxmox.com/wiki/Proxmox_VE_API)

## :rocket: /deploy `<app_name>` `<type>`

Automate the creation of a new application directory in `docker/` or `lxc/` based on existing templates.

### :pencil: Usage

```bash
/deploy my-new-app docker
```

### :gear: Implementation

The command uses `scripts/deploy.py` to:
1. **Scaffold Directory:** Creates `docker/<app_name>` or `lxc/<app_name>`.
2. **Copy Templates:** Uses `docker/.template` or `lxc/.template`.
3. **Substitution:** Replaces Jinja2 variables (e.g., `{{ APP_NAME }}`) in `.j2` files.
4. **Register Track:** Automatically creates a new Conductor track for the deployment.

## :material-sync: /pve sync

Trigger synchronization tasks and verify that DNS rewrites and configurations are consistent across multiple Proxmox nodes.

### :pencil: Usage

```bash
/pve sync
```

### :gear: Implementation

The command uses `scripts/pve_sync.py` to:
1. **AdGuard Sync:** Restarts `adguardhome-sync.service`.
2. **Traefik Check:** Scans `pve/traefik/conf.d/` for consistency.
3. **DNS Check:** Encourages manual rewrite verification via `manage_dns`.

## :memo: /task summary

Automatically summarize work done in the current task and update the project plan.

### :pencil: Usage

```bash
/task summary
```

### :gear: Implementation

The command uses `scripts/task_summary.py` to:
1. **Identify Task:** Finds the task marked as `[~]` in the active track's `plan.md`.
2. **Draft Note:** Generates a Git Note draft with modified files and a summary placeholder.
3. **Update Status:** Changes the task status to `[x]` in `plan.md`.
4. **Checkpoint Check:** Alerts if a phase or track is complete and requires a checkpoint.