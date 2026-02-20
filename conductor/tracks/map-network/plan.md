# Implementation Plan: /map network

## Phase 1: Data Extraction
- [ ] Analyze Traefik configuration structure for router/service mapping.
- [ ] Identify how to extract network metadata from `compose.yaml` files.

## Phase 2: Implementation
- [ ] Create `.gemini/commands/map_network.md`.
- [ ] Develop `scripts/map_network.py` to generate Mermaid source from the configurations.

## Phase 3: Validation
- [ ] Test generating a map for a single complex application.
- [ ] Test generating a global network map.
- [ ] Verify Mermaid syntax validity.
