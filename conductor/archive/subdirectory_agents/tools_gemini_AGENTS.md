# Gemini Tools

## Project Overview

This directory (`/root/git/nicholaswilde/homelab/tools/gemini`) contains tools and configurations for integrating various Homelab services with the **Model Context Protocol (MCP)**. This enables AI agents (like Gemini) to interact directly with infrastructure components such as Proxmox VE and UniFi Network.

## Directory Structure

*   **`.` (Root)**: Contains the main `Taskfile.yml` for managing shared dependencies and Python-based MCP tools.
*   **`proxmox-mcp-plus/`**: A containerized setup for the `ProxmoxMCP-Plus` server.
    *   **`Dockerfile`**: Multi-stage build for the Proxmox MCP Python server.
    *   **`Taskfile.yml`**: Automation for building, encrypting/decrypting secrets, and deploying the container.
    *   **`pve01/` & `pve04/`**: Directory specific configurations for different Proxmox nodes/clusters.
    *   **`config.json.tmpl`**: Template for Proxmox configuration.

## Key Tools

### 1. UniFi Network MCP
*   **Source**: [sirkirby/unifi-network-mcp](https://github.com/sirkirby/unifi-network-mcp)
*   **Type**: Python Package (installed via `uv`).
*   **Purpose**: Manage and monitor UniFi networks (devices, clients, etc.).

### 2. Proxmox MCP Plus
*   **Source**: [nicholaswilde/proxmox-mcp-plus](https://github.com/nicholaswilde/proxmox-mcp-plus)
*   **Type**: Docker Container.
*   **Purpose**: Manage Proxmox VE clusters, nodes, VMs, and storage.

### 3. Gitea MCP
*   **Source**: [gitea/gitea-mcp](https://gitea.com/gitea/gitea-mcp)
*   **Type**: Binary (downloaded via `download-gitea-mcp.sh`).
*   **Purpose**: Interact with Gitea instances via MCP.

## Building and Running

This project uses `task` (Go-Task) for automation.

### Prerequisites
*   `task`
*   `docker`
*   `sops` (for secret management)
*   `uv` (installed via `task deps`)

### Root Commands (`/`)

| Command | Description |
| :--- | :--- |
| `task deps` | Installs `uv` (required for Python MCP tools). |
| `task install:unifi` | Installs `unifi-network-mcp` using `uv`. |
| `task update:unifi` | Updates `unifi-network-mcp` to the latest version. |
| `task install:gitea` | Installs `gitea-mcp` using the download script. |
| `task update:gitea` | Updates `gitea-mcp` to the latest version. |

### Proxmox Commands (`proxmox-mcp-plus/`)

Run these from the `proxmox-mcp-plus` directory or use `task -d proxmox-mcp-plus <command>`.

| Command | Description |
| :--- | :--- |
| `task build` | Builds the Docker image `ghcr.io/nicholaswilde/proxmox-mcp-plus:latest` from upstream. |
| `task load` | Builds the image and loads it into the local Docker daemon. |
| `task decrypt` | Decrypts configuration secrets (SOPS) for `pve01` and `pve04`. |
| `task encrypt` | Encrypts configuration secrets (SOPS). |
| `task init` | Creates a `config.json` from the template. |

## Configuration & Secrets

*   **Secrets**: Sensitive configuration files (like `config.json`) are encrypted using **SOPS**.
*   **Workflow**:
    1.  Decrypt: `task -d proxmox-mcp-plus decrypt`
    2.  Edit: Modify `proxmox-mcp-plus/pveXX/config.json`.
    3.  Encrypt: `task -d proxmox-mcp-plus encrypt`
    4.  Verify: `task -d proxmox-mcp-plus verify-secrets` ensures encrypted and decrypted files match.

## Development Conventions

*   **Automation**: All standard operations should be defined in `Taskfile.yml`.
*   **Python Management**: Use `uv` for managing Python environments and tools.
*   **Infrastructure**: Docker is used for complex dependencies (like the Proxmox MCP server).
