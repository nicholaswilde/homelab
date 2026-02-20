# Spec: /homelab status command

## :dart: Goal
Provide a "bird's eye view" of the lab, checking Proxmox node health, listing active Docker containers, and reporting on active Conductor tracks.

## :gear: Requirements
- Check connectivity and status of Proxmox nodes (pve01, pve03, pve04).
- List active containers across all `docker/` subdirectories.
- Report current status of `conductor/tracks.md`.

## :link: References
- [Proxmox API](https://pve.proxmox.com/wiki/Proxmox_VE_API)
- [Docker Compose CLI](https://docs.docker.com/compose/reference/)
