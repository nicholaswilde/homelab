# Implementation Plan: /homelab status command

## Phase 1: Research & Discovery [checkpoint: f1cbb8c]
- [x] Research `proxmox-mcp-rs` capabilities for status checks.
- [x] Map all `docker/` subdirectories to check for `compose.yaml` presence.
- [x] Study `conductor/tracks.md` parsing logic.

## Phase 2: Implementation [checkpoint: d615a33]
- [x] Create `.gemini/commands/homelab_status.md`.
- [x] Implement Proxmox status checks using `pve04__get_cluster_status` or similar tools.
- [x] Implement Docker container discovery and status check using `run_shell_command`.
- [x] Implement Track status summary check.

## Phase 3: Validation [checkpoint: c817216]
- [x] Verify command output format and readability.
- [x] Test command under various node/container states.
- [x] Document usage in `docs/tools/gemini-commands.md`.
