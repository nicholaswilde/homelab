# Spec: /pve log command

## :dart: Goal
Fetch and summarize recent logs from a specific Proxmox node or service for rapid troubleshooting.

## :gear: Requirements
- Accepts a node name (e.g., `pve01`).
- Optionally accepts a service name.
- Uses Proxmox API or shell commands to retrieve the last 20-50 log lines.
- Summarizes and highlights errors/warnings.
