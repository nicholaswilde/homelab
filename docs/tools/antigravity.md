---
tags:
  - tool
  - ai
---

# :robot: Antigravity

Antigravity is the primary AI agent and toolset used for managing this homelab. It provides a CLI interface and custom commands to automate various administrative tasks.

!!! note "Migration from Google Gemini"

    The homelab management has migrated away from using Google Gemini (and the Gemini CLI) to Antigravity. This migration ensures a more focused and customized AI experience for homelab operations.

## :gear: Components

Antigravity consists of two main parts:

- **[Antigravity CLI](antigravity-cli.md)**: The core command-line interface that integrates with AI models and MCP servers.
- **[Antigravity Commands](antigravity-commands.md)**: A suite of custom commands specifically designed for homelab management tasks.

## :pencil: Usage Overview

Antigravity is used to:

1.  **Manage Services**: Deploy, update, and remove Docker and LXC applications.
2.  **Monitor Lab**: Check the status of Proxmox nodes, containers, and conductor tracks.
3.  **Documentation**: Automate the creation and maintenance of documentation.
4.  **Secrets Management**: Securely handle credentials and rotate secrets.

For detailed command references, see [Antigravity Commands](antigravity-commands.md).
