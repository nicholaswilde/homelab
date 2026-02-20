# Implementation Plan: /homelab update command

## Phase 1: Analysis
- [ ] Map directories to service types (Docker vs LXC).
- [ ] Identify standard update tasks in `Taskfile.yml` files.

## Phase 2: Implementation
- [ ] Create `.gemini/commands/homelab_update.md`.
- [ ] Develop `scripts/homelab_update.py` to orchestrate updates.

## Phase 3: Validation
- [ ] Test updating a single Docker app.
- [ ] Test updating a single LXC app.
- [ ] Test the `--all` flag logic (dry-run).
