# Implementation Plan: Proxmox LXC Automation

## Phase 1: Research & Scaffolding
- [x] Task: Research Proxmox API/CLI for architecture detection and node listing.
- [x] Task: Create a new Bash script `scripts/lxc_create.sh` using the template defined in `workflow.md`.
- [x] Task: Add a new `Taskfile` task `lxc:create` to call the script.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Research & Scaffolding' (Protocol in workflow.md)

## Phase 2: Implementation (TDD)
- [x] Task: Write a failing test for node selection (e.g., mock `pvesh` output).
- [x] Task: Implement node selection logic and make tests pass.
- [x] Task: Write a failing test for architecture detection.
- [x] Task: Implement architecture detection and make tests pass.
- [x] Task: Write failing tests for resource and network configuration inputs.
- [x] Task: Implement input prompts and configuration logic and make tests pass.
- [x] Task: Write a failing test for the `pct create` command generation.
- [x] Task: Implement the container creation command logic and make tests pass.
- [x] Task: Conductor - User Manual Verification 'Phase 2: Implementation' (Protocol in workflow.md)

## Phase 3: Implementation - Post-Creation Setup (TDD)
- [x] Task: Write a failing test for APT update/upgrade command generation.
- [x] Task: Implement system update and upgrade task and make tests pass.
- [x] Task: Write a failing test for essential package installation command generation.
- [x] Task: Implement utility package installation task and make tests pass.
- [x] Task: Write a failing test for user and SSH key configuration commands.
- [x] Task: Implement user setup and SSH key deployment logic and make tests pass.
- [x] Task: Write a failing test for hostname and timezone configuration commands.
- [x] Task: Implement hostname and timezone configuration and make tests pass.
- [x] Task: Conductor - User Manual Verification 'Phase 3: Implementation - Post-Creation Setup' (Protocol in workflow.md)

## Phase 4: Integration & Manual Verification
- [x] Task: Integrate `pass show default-lxc-password` for password retrieval.
- [x] Task: Verify script handles unprivileged container creation correctly.
- [x] Task: Manually verify LXC creation and setup on an x86_64 node.
- [x] Task: Manually verify LXC creation and setup on an aarch64 node (if available).
- [x] Task: Conductor - User Manual Verification 'Phase 4: Integration & Manual Verification' (Protocol in workflow.md)
