# Implementation Plan: /pve log command

## Phase 1: API Analysis
- [x] Investigate `get_cluster_log` and `get_node_stats` tool outputs.
- [x] Determine how to fetch service-specific logs (e.g., `journalctl` via exec).

## Phase 2: Implementation
- [x] Create `.gemini/commands/pve_log.md`.
- [x] Develop `scripts/pve_log.py` to fetch and summarize logs.

## Phase 3: Validation
- [x] Test fetching logs for a specific node.
- [x] Test fetching logs for a specific service.
