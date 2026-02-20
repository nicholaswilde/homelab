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

## :material-math-log: /pve log `<node>` `[service]`

Fetch and summarize recent logs from a specific Proxmox node or service.

### :pencil: Usage

```bash
/pve log pve04 pveupdate
```

### :gear: Implementation

The command uses `scripts/pve_log.py` to:
1. **Fetch Logs:** Retrieves cluster logs via Proxmox API.
2. **Filter:** Filters by node and optional service keyword.
3. **Summarize:** Formats entries with level-based coloring and timestamps.

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

## :lock: /check secrets

Verify the encryption status of all sensitive files project-wide to prevent accidental leaks.

### :pencil: Usage

```bash
/check secrets
```

### :gear: Implementation

The command uses `scripts/check_secrets.py` to:
1. **Scan:** Identifies `.env`, `*.enc`, and files with `secret` or `creds` in their name.
2. **Verify:** Decrypts `.enc` files and compares them with unencrypted versions if they exist.
3. **Audit:** Reports unencrypted sensitive files that are not ignored by Git.
4. **Report:** Provides a summarized status of all sensitive files.

## :arrows_counterclockwise: /homelab update `<app_name>`

Pull updates and restart services for Docker and LXC applications.

### :pencil: Usage

```bash
/homelab update my-app
```

### :gear: Implementation

The command uses `scripts/homelab_update.py` to:
1. **Identify App:** Locates the application in `docker/`, `lxc/`, or `pve/`.
2. **Execute Update:**
    - For Docker: Runs `docker compose pull` and `docker compose up -d`.
    - For LXC: Executes the application's `update.sh` script.
3. **Report:** Provides a status summary of the update process.

## :floppy_disk: /homelab backup `<target>`

Trigger manual backups for specific applications or configurations.

### :pencil: Usage

```bash
/homelab backup agh
```

### :gear: Implementation

The command uses `scripts/homelab_backup.py` to:
1. **Resolve Target:** Maps aliases (e.g., `agh`, `patchmon`) or direct names to directories.
2. **Execute Backup:** Runs the `task backup` command in the target directory.
3. **Verify:** Checks for the update of `.enc` files to confirm the backup was successful and encrypted.