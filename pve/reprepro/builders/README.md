# :hammer_and_wrench: Reprepro Builders System

The unified, modular builder system compiles, packages, and prepares `.deb` packages for custom homelab services across multiple target architectures (e.g., `amd64`, `armv6`, `armhf`, `arm64`).

---

## :file_folder: Directory Structure

- **`projects/`**: Subdirectories for each managed application (e.g., `btop/`, `fzf/`, `restic/`, `sops/`, `neovim/`, `lnav/`). Each project contains:
  - `Taskfile.yml`: Custom build instructions (Red/Green phases, TDD structure, or compilation scripts).
  - `nfpm.yaml` (optional): Clean, non-interactive NFPM configuration for packaging built binaries.
- **`scripts/`**: Automation and synchronization glue:
  - `check_version.sh`: Query GitHub releases to compare the latest version with local reprepro version.
  - `sync.sh`: Periodically query, compile, package, and upload all registered projects.
  - `webhook_trigger.sh`: Endpoint script called by webhooks to check and build a specific package.
- **`webhook/`**: Webhook service configuration:
  - `hooks.json`: Webhook routing definitions for incoming HTTP POST payloads.
  - `reprepro-webhook.service`: Systemd service template for deployment to `/etc/systemd/system/`.

---

## :hammer_and_wrench: Task Runner Commands

Manage the builders workspace from the `builders/` directory:

- **List available tasks**: `task` or `task -l`
- **Run full check & sync**: `task sync` (Queries and builds any outdated packages)
- **Build all packages**: `task build-all` (Forces local build of all registered packages)
- **Clean workspace**: `task clean-all` (Nukes local `build/`, `dist/`, and `.cache/` directories)
- **Clean Rust compilers**: `task clean-targets` (Prunes heavy Cargo `target/` builds to free up space)
- **Prune old caches**: `task prune` (Prunes `.deb` cache older than 7 days)
- **Check storage status**: `task status` (Shows disk usage for cache, builds, and output packages)

---

## :rocket: Webhook Architecture

Automated builds and repository syncs are handled by a `webhook` daemon running on port **`9000`**.

### Available Webhook Endpoints:
1. **`/hooks/sync`** or **`/hooks/update-app`**:
   - Triggers the master `builders/scripts/sync.sh` script.
   - Iterates through all registered builders to fetch, compile, and upload any outdated packages automatically.
2. **`/hooks/build-app`** or **`/hooks/rebuild-amd64`**:
   - Triggers a check-update and build for a specific application passed inside the HTTP POST payload (`"app": "<app-name>"`).
   - Maps the application name to the corresponding builder, runs the build task, and uploads the `.deb` file.

---

## :pencil: Adding a New Project

To register a new project in the modular builder framework, follow these steps:

### 1. Scaffold the Project Directory
Create `projects/<project-name>` containing a `Taskfile.yml` and `nfpm.yaml` (if packaging a custom binary). 

### 2. Define the Build Tasks
The project's local `Taskfile.yml` must define a `build` task that outputs the final `.deb` packages to the shared `dist/` directory.

### 3. Register in Master `Taskfile.yml`
Include your project in the master `pve/reprepro/builders/Taskfile.yml`:
```yaml
includes:
  <project-name>: ./projects/<project-name>/Taskfile.yml
```
Also, append the build target under `build-all` task:
```yaml
  build-all:
    cmds:
      ...
      - task: <project-name>:build
```

### 4. Register in Check-Update Sync Script
Open `pve/reprepro/builders/scripts/sync.sh` and add your project to the `PROJECTS` list:
```bash
PROJECTS=(
  ...
  "<project-name>:<package-name>:<github-owner>/<github-repo>"
)
```

### 5. Register in Webhook Script (If Triggered Individually)
If the project needs to support dedicated webhook triggers, map the incoming payload name in `pve/reprepro/builders/scripts/webhook_trigger.sh`:
```bash
case "$APP" in
    ...
    "<app-name>") REPO="<github-owner>/<github-repo>" ;;
esac
```
