# Core Architecture & Map

Centralized homelab configuration, IaC provisioning, automation, and documentation repo.

## Directory Structure
- `docker/`: Docker Compose application definitions (`docker/<app>/compose.yaml`, `.env.tmpl`). Use `docker/.template` for scaffolding.
- `lxc/`: Proxmox LXC container configurations and scripts. Use `lxc/.template` for new containers.
- `pve/`: Proxmox VE cluster/node configs (Traefik dynamic configs `pve/traefik/conf.d/`, Homepage dashboard `pve/homepage/config/`).
- `vm/`: Virtual machine definitions.
- `scripts/`: Shell and Python automation utilities.
- `docs/`: Knowledge base documentation (Apps, Tools, Hardware) built with MkDocs/Zensical.
- `conductor/`: Project governance, tracks, workflow specs, and tech stack definitions.

## Key Invariants
- Never commit sensitive data, secrets, passwords, tokens, API keys, private keys, `.env` files, or unencrypted credential/config files containing secrets. Always use SOPS encryption (`*.enc`).
- Python execution must use `uv run python <script>` with `uv` for dependency management.
- For OMV networking changes, update the database via `omv-confdbadm` and deploy via `omv-salt deploy run systemd-networkd`; never edit `/etc/netplan` directly.
- Conductor tracks completion: completed tracks must be archived automatically (`conductor/archive/`) without prompting.
- LXC provisioning defaults: unprivileged (`--unprivileged 0`), template `debian-trixie`, `ip6=slaac`, nesting enabled (`nesting=1`).
- RTK optimization: prefix shell commands with `rtk` where applicable.
- LXC App Updates:
  - When asked to update `drawio`, immediately run `rtk uv run python scripts/lxc_update.py drawio [-v <version>]` directly without probing.
  - When asked to update `localsend`, immediately run `rtk uv run python scripts/lxc_update.py localsend` directly without probing.
  - When asked to update `wallos`, immediately run `rtk uv run python scripts/lxc_update.py wallos --node pve03` directly without probing.
  - When asked to update `changedetection`, immediately run `rtk uv run python scripts/lxc_update.py changedetection --node pve04` directly without probing.
  - When asked to update `stirling-pdf`, immediately run `rtk uv run python scripts/lxc_update.py stirling-pdf --node pve04 [-v <version>]` directly without probing.
  - When asked to update `homepage`, immediately run `rtk uv run python scripts/lxc_update.py homepage --node pve04 [-v <version>]` directly without probing.
  - When asked to update `convertx`, immediately run `rtk uv run python scripts/lxc_update.py convertx --node pve04 [-v <version>]` directly without probing.
  - When asked to update `reactive-resume`, immediately run `rtk uv run python scripts/lxc_update.py reactive-resume --node pve04 [-v <version>]` directly without probing.
  - When asked to update `withoutbg`, immediately run `rtk uv run python scripts/lxc_update.py withoutbg --node pve03 [-v <version>]` directly without probing.
  - When asked to update `gitea`, immediately run `rtk uv run python scripts/lxc_update.py gitea --node pve03 [-v <version>]` directly without probing.
  - When asked to update `bentopdf`, immediately run `rtk uv run python scripts/lxc_update.py bentopdf --node pve03` directly without probing.
  - When asked to update `pocket-id`, immediately run `rtk uv run python scripts/lxc_update.py pocket-id --node pve03` directly without probing.
  - When asked to update `homebox`, immediately run `rtk uv run python scripts/lxc_update.py homebox --node pve03` directly without probing.
  - When asked to update `omni-tools`, immediately run `rtk uv run python scripts/lxc_update.py omni-tools --node pve04` directly without probing.
  - When asked to update `gatus`, immediately run `rtk uv run python scripts/lxc_update.py gatus --node pve04` directly without probing.
  - When asked to update `vaultwarden`, immediately run `rtk uv run python scripts/lxc_update.py vaultwarden --node pve03` directly without probing.
  - When updating any unsaved web app, set up its `update.sh` and immediately persist across 3 layers (Rules in `AGENTS.md` / `.agents/rules/`, Serena memories in `mem:core` / `mem:suggested_commands`, and RTK filters in `.rtk/filters.toml`).

## Domain References
- Stack details and runtimes: `mem:tech_stack`
- Daily operations, task runner, and dev commands: `mem:suggested_commands`
- Code styling, scripting standards, and documentation guidelines: `mem:conventions`
- Quality gates, test checks, and task completion verification: `mem:task_completion`
