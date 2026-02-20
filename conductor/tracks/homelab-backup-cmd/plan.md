# Implementation Plan: /homelab backup command

## Phase 1: Target Mapping
- [ ] List all directories with a `backup` task in their `Taskfile.yml`.
- [ ] Define aliases for common targets (e.g., `agh` -> `pve/adguardhome`).

## Phase 2: Implementation
- [ ] Create `.gemini/commands/homelab_backup.md`.
- [ ] Develop `scripts/homelab_backup.py` to trigger and verify backups.

## Phase 3: Validation
- [ ] Test backup of AdGuard Home.
- [ ] Test backup of a Docker app with volume backup.
