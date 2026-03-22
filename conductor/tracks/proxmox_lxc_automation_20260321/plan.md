# Implementation Plan: Proxmox LXC Automation

## Phase 1: Research & Scaffolding
- [ ] Task: Research Proxmox API/CLI for architecture detection and node listing.
- [ ] Task: Create a new Bash script `scripts/lxc_create.sh` using the template defined in `workflow.md`.
- [ ] Task: Add a new `Taskfile` task `lxc:create` to call the script.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Research & Scaffolding' (Protocol in workflow.md)

## Phase 2: Implementation (TDD)
- [ ] Task: Write a failing test for node selection (e.g., mock `pvesh` output).
- [ ] Task: Implement node selection logic and make tests pass.
- [ ] Task: Write a failing test for architecture detection.
- [ ] Task: Implement architecture detection and make tests pass.
- [ ] Task: Write failing tests for resource and network configuration inputs.
- [ ] Task: Implement input prompts and configuration logic and make tests pass.
- [ ] Task: Write a failing test for the `pct create` command generation.
- [ ] Task: Implement the container creation command logic and make tests pass.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Implementation' (Protocol in workflow.md)

## Phase 3: Integration & Manual Verification
- [ ] Task: Integrate `pass show default-lxc-password` for password retrieval.
- [ ] Task: Verify script handles unprivileged container creation correctly.
- [ ] Task: Manually verify LXC creation on an x86_64 node.
- [ ] Task: Manually verify LXC creation on an aarch64 node (if available).
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Integration & Manual Verification' (Protocol in workflow.md)
