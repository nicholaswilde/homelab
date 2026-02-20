# Implementation Plan: /dashboard integration

## Phase 1: Configuration Analysis
- [x] Analyze `pve/homepage/config/services.yaml` structure and grouping.
- [x] Define standard dashboard templates for Docker and LXC apps.

## Phase 2: Implementation
- [x] Create `.gemini/commands/dashboard_add.md`.
- [x] Develop `scripts/dashboard_add.py` to parse and update the YAML config.
- [x] Integrate the script as an optional step in `/deploy`.

## Phase 3: Validation
- [x] Test adding a new service to a specific group.
- [x] Verify `homepage` correctly renders the new entry.
- [x] Test duplicate detection logic.
