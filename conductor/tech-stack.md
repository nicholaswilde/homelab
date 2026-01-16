# Technology Stack

## Core Infrastructure
- **Hypervisor:** Proxmox VE (Virtual Environment)
- **Containerization:** Docker, Docker Compose
- **Container Orchestration:** Docker Compose (Single node), Proxmox LXC (System containers)
- **Operating Systems:** Debian Linux (Primary), Ubuntu, Alpine Linux

## Automation & Scripting
- **Task Runner:** Task (`go-task`) - Primary entry point for all operations.
- **Shell Scripting:** Bash - Used for system maintenance, updates, and glue code. (ShellCheck compliant)
- **Programming:** Python (>=3.11) - Used for complex automation, MCP tools, and data processing. (PEP 8 compliant)
- **Dependency Management:** `uv` (for Python)
- **Configuration Management:** Ansible (via external repo/submodule usage patterns), Cloud-Init

## Documentation
- **Static Site Generator:** MkDocs
- **Theme:** Material for MkDocs
- **Syntax Extensions:** Zensical
- **Diagrams:** Mermaid
- **Linting:** Markdownlint, Yamllint, Linkcheck

## Networking & Security
- **Reverse Proxy:** Traefik
- **DNS & Ad Blocking:** AdGuard Home, Unbound
- **VPN:** WireGuard
- **Secrets Management:** SOPS (Mozilla SOPS)

## Integrations
- **Model Context Protocol (MCP):** Custom servers for Proxmox, UniFi, and other tools to interface with AI agents.
    - **Proxmox MCP Plus:**
        - **pve01 Cluster:** Prefix `pve01__`. Manages nodes, VMs, containers, and storage on the `pve01` cluster.
        - **pve04 Node:** No prefix. Manages nodes, VMs, containers, and storage on the `pve04` node.
    - **UniFi Network MCP:** Prefix `unifi_`. Manages and monitors UniFi network devices, clients, and configurations.
    - **AdGuard Home MCP:** No prefix. Manages AdGuard Home DNS rewrites and filtering rules.
