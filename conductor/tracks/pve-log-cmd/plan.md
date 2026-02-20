# Implementation Plan: /pve log command

## Phase 1: API Analysis
- [ ] Investigate `get_cluster_log` and `get_node_stats` tool outputs.
- [ ] Determine how to fetch service-specific logs (e.g., `journalctl` via exec).

## Phase 2: Implementation
- [ ] Create `.gemini/commands/pve_log.md`.
- [ ] Develop `scripts/pve_log.py` to fetch and summarize logs.

## Phase 3: Validation
- [ ] Test fetching logs for a specific node.
- [ ] Test fetching logs for a specific service.
