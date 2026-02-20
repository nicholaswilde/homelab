# Implementation Plan: /audit dependencies

## Phase 1: Registry Interaction
- [ ] Determine API methods for querying Docker Hub and GHCR for tags.
- [ ] Identify tools (e.g., `skopeo`) that might simplify registry inspection.

## Phase 2: Implementation
- [ ] Create `.gemini/commands/audit_deps.md`.
- [ ] Develop `scripts/audit_deps.py` to scan files and report discrepancies.

## Phase 3: Validation
- [ ] Test scanning a single `compose.yaml`.
- [ ] Test reporting across the entire `docker/` directory.
