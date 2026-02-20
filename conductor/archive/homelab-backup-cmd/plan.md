# Implementation Plan: /homelab backup command

## Phase 1: Target Mapping
- [x] List all directories with a `backup` task in their `Taskfile.yml`.
- [x] Define aliases for common targets (e.g., `agh` -> `pve/adguardhome`).

## Phase 2: Implementation
- [x] Create `.gemini/commands/homelab_backup.md`.
- [x] Develop `scripts/homelab_backup.py` to trigger and verify backups.

## Phase 3: Validation
- [x] Test backup of AdGuard Home.
- [x] Test backup of a Docker app with volume backup.
