# Spec: /homelab backup command

## :dart: Goal
Trigger manual backups for specific applications or configurations through a simple CLI interface.

## :gear: Requirements
- Accepts a target (e.g., `adguard`, `traefik`, or specific app name).
- Executes the `backup` task defined in the corresponding `Taskfile.yml`.
- Verifies that an encrypted `.enc` file is created/updated.
