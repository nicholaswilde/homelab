# Implementation Plan: /homelab update command

## Phase 1: Analysis
- [x] Map directories to service types (Docker vs LXC).
- [x] Identify standard update tasks in `Taskfile.yml` files.

## Phase 2: Implementation
- [x] Create `.gemini/commands/homelab_update.md`.
- [x] Develop `scripts/homelab_update.py` to orchestrate updates.

## Phase 3: Validation
- [x] Test updating a single Docker app.
- [x] Test updating a single LXC app.
- [x] Test the `--all` flag logic (dry-run).
