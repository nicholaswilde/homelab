# Implementation Plan: /dashboard integration

## Phase 1: Configuration Analysis
- [ ] Analyze `pve/homepage/config/services.yaml` structure and grouping.
- [ ] Define standard dashboard templates for Docker and LXC apps.

## Phase 2: Implementation
- [ ] Create `.gemini/commands/dashboard_add.md`.
- [ ] Develop `scripts/dashboard_add.py` to parse and update the YAML config.
- [ ] Integrate the script as an optional step in `/deploy`.

## Phase 3: Validation
- [ ] Test adding a new service to a specific group.
- [ ] Verify `homepage` correctly renders the new entry.
- [ ] Test duplicate detection logic.
