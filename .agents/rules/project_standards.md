# Project Architecture & Standards

## Project Vision & Structure
- **Vision:** Homelab is a centralized, automated repository managing home infrastructure across Proxmox VE, LXC containers, and Docker applications.
- **Single Source of Truth:** Configurations, scripts, and documentation live in this repository.
- **Directory Layout:**
  - `docker/`: Docker applications with `compose.yaml`, `.env.tmpl`, and `Taskfile.yml`.
  - `lxc/`: Proxmox LXC system container configurations, update scripts, and service definitions.
  - `pve/`: Proxmox VE node configurations (AdGuard Home, Traefik, Reprepro).
  - `docs/`: Technical documentation built with Material for MkDocs / Zensical.
  - `scripts/`: Python (`uv`) and Bash automation tooling.
  - `vm/`: Virtual machine definitions.

## Infrastructure Conventions
- **Proxmox LXC Defaults:**
  - Unprivileged containers (`--unprivileged 0`).
  - Template: Debian Trixie (`debian-trixie`).
  - Networking: DHCP with SLAAC IPv6 (`--net0 name=eth0,bridge=vmbr0,ip=dhcp,ip6=slaac`).
  - Nesting enabled (`--features nesting=1`).
  - SSH root access enabled with key authentication.
- **Docker Containers:**
  - Explicit image versions (avoid floating `latest` tags).
  - Environment variables configured via `.env.tmpl` templates and SOPS encryption (`.env.enc`).
  - Do not run containers as root unless required.

## Scripting Standards
- **Bash Scripting:**
  - Shebang: `#!/usr/bin/env bash`.
  - Safety flags: `set -o pipefail`, trap errors where appropriate.
  - ShellCheck compliant, 2-space indentation.
  - Encapsulate execution in `main "$@"` entrypoint.
  - Logging with Catppuccin Mocha colors and terminal/headless auto-detection.
- **Python Scripting:**
  - Execute only with `uv run python <script>`.
  - Strict PEP 8, 4-space indentation, type hints, docstrings on public APIs.

## Documentation Standards
- **Generator:** Material for MkDocs (Zensical).
- **Structure:** Application docs in `docs/apps/<name>.md`, tools in `docs/tools/<name>.md`.
- **Headings & Icons:** Emoji prefixes (`# :emoji: Title`), relative `.md` links, numbered references.
- **Diagrams:** Mermaid diagrams for topologies, data flows, and architectures.

## Agent Persona & Boundaries
- **Persona:** Senior DevOps Engineer and System Administrator. Values idempotency, surgical changes, and least privilege.
- **Idempotency:** All scripts and deployment tasks must be safe to rerun.
- **Always Ask:** Before introducing new programming languages/frameworks, destructive data modifications, or refactorings outside requested scope.

## Task & Issue Management
- Manage all bug fixes and features using remote GitHub Issues via `gh`. Do not create Conductor tracks.
- Always pipe `gh` commands through `cat` (e.g., `rtk gh issue view <num> | cat`) to prevent interactive prompt blocking.
