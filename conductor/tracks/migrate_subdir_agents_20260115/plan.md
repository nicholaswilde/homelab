# Implementation Plan - Migrate Subdirectory AGENTS.md to Conductor

## Phase 1: Discovery and Archival [checkpoint: ff1507e]
- [x] Task: Discovery and Archival ff1507e
    - [x] Search for all `AGENTS.md` files in subdirectories using `find . -mindepth 2 -name "AGENTS.md"`.
    - [x] Create an archival directory `conductor/archive/subdirectory_agents/`.
    - [x] Move each found `AGENTS.md` file to the archival directory, renaming them to include their original path (e.g., `docker_AGENTS.md`).
- [x] Task: Conductor - User Manual Verification 'Discovery and Archival' (Protocol in workflow.md)

## Phase 2: Content Integration - Guidelines
- [ ] Task: Integrate Guidelines and Persona
    - [ ] Analyze archived `docker/AGENTS.md` and `lxc/AGENTS.md` for specific boundaries or personas.
    - [ ] Update `conductor/product-guidelines.md` with sections for "Docker Application Guidelines" and "Proxmox LXC Guidelines".
    - [ ] Ensure any unique "Always", "Ask", "Never" rules from subdirectories are incorporated.
- [ ] Task: Conductor - User Manual Verification 'Content Integration - Guidelines' (Protocol in workflow.md)

## Phase 3: Content Integration - Tech Stack and Workflow
- [ ] Task: Integrate Tech Stack and Workflow
    - [ ] Extract "Tech Stack" details from subdirectory agents (e.g., image tagging conventions, resource defaults).
    - [ ] Update `conductor/tech-stack.md` and `conductor/workflow.md` with these specific technical constraints.
    - [ ] Update `conductor/index.md` to reference any newly added specialized guideline sections.
- [ ] Task: Conductor - User Manual Verification 'Content Integration - Tech Stack and Workflow' (Protocol in workflow.md)

## Phase 4: Final Cleanup and Validation
- [ ] Task: Final Validation
    - [ ] Verify that no functional instructions were lost during the migration.
    - [ ] Run `task lint` to ensure documentation consistency.
    - [ ] Confirm that all subdirectory `AGENTS.md` files are successfully archived and removed from their original locations.
- [ ] Task: Conductor - User Manual Verification 'Final Cleanup and Validation' (Protocol in workflow.md)
