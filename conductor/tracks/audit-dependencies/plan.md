# Implementation Plan: /audit dependencies

## Phase 1: Registry Interaction [checkpoint: 5b1ec92]
- [x] Determine API methods for querying Docker Hub and GHCR for tags. (5b1ec92)
- [x] Identify tools (e.g., `skopeo`) that might simplify registry inspection. (5b1ec92)

## Phase 2: Implementation
- [x] Create `.gemini/commands/audit_deps.md`.
- [~] Develop `scripts/audit_deps.py` to scan files and report discrepancies.

## Phase 3: Validation
- [ ] Test scanning a single `compose.yaml`.
- [ ] Test reporting across the entire `docker/` directory.
