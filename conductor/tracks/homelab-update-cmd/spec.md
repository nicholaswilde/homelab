# Spec: /homelab update command

## :dart: Goal
Provide a unified command to pull updates and restart services for Docker and LXC applications.

## :gear: Requirements
- Detects application type (Docker vs. LXC).
- For Docker: Runs `docker compose pull` and `docker compose up -d`.
- For LXC: Executes the application's `update.sh` script.
- Support a `--all` flag to update all active services.
