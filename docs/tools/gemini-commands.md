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
