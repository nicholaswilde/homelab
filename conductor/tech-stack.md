# Technology Stack

## Core Infrastructure

- **Hypervisor:** Proxmox VE (Virtual Environment)
- **Containerization:** Docker, Docker Compose
- **Container Orchestration:** Docker Compose (Single node), Proxmox LXC (System containers)
- **Operating Systems:** Debian Linux (Primary), Ubuntu, Alpine Linux

## Automation & Scripting

- **Task Runner:** Task (`go-task`) - Primary entry point for all operations.
- **Gemini CLI Commands:** Custom interactive commands for status and deployment.
- **Shell Scripting:** Bash - Used for system maintenance, updates, and glue code. (ShellCheck compliant)
- **Programming:** Python (>=3.11) - Used for complex automation, MCP tools, and data processing. (PEP 8 compliant)
- **Templating:** Jinja2 (for `.tmpl.j2` files)
- **Dependency Management:** `uv` (for Python)
- **YAML Processing:** `ruamel.yaml` (for comment-preserving YAML manipulation)
- **Configuration Management:** Ansible (via external repo/submodule usage patterns), Cloud-Init
- **CLI Utilities:** `tabulate` (fancy_grid format for tables), `markitdown` (file to Markdown conversion)

## Documentation

- **Static Site Generator:** MkDocs
- **Theme:** Material for MkDocs
- **Extensions:** `pymdown-extensions`, Zensical syntax extensions
- **Diagrams:** Mermaid
- **Linting:** Markdownlint, Yamllint, Linkcheck

## Networking & Security

- **Reverse Proxy:** Traefik
- **DNS & Ad Blocking:** AdGuard Home, Unbound
- **VPN:** WireGuard
- **Secrets Management:** SOPS (Mozilla SOPS), GnuPG (GPG)

## Integrations

- **Model Context Protocol (MCP):**
  - **Proxmox MCP Plus:** Docker container; manages Proxmox clusters, nodes, VMs, and storage.
    - **pve01 Cluster:** Prefix `pve01__`.
    - **pve04 Node:** No prefix.
  - **UniFi Network MCP:** Python package (via `uv`); manages UniFi network devices and clients. Prefix `unifi_`.
  - **Gitea MCP:** Binary; interacts with Gitea instances.
  - **AdGuard Home MCP:** Manages DNS rewrites and filtering rules. No prefix.