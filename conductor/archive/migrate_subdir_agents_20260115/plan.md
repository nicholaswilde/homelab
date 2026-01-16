# Implementation Plan - Migrate Subdirectory AGENTS.md to Conductor

## Phase 1: Discovery and Archival [checkpoint: ff1507e]
- [x] Task: Discovery and Archival ff1507e
    - [x] Search for all `AGENTS.md` files in subdirectories using `find . -mindepth 2 -name "AGENTS.md"`.
    - [x] Create an archival directory `conductor/archive/subdirectory_agents/`.
    - [x] Move each found `AGENTS.md` file to the archival directory, renaming them to include their original path (e.g., `docker_AGENTS.md`).
- [x] Task: Conductor - User Manual Verification 'Discovery and Archival' (Protocol in workflow.md)

## Phase 2: Content Integration - Guidelines
- [x] Task: Integrate Guidelines and Persona
    - [x] Analyze archived `docker_AGENTS.md` and `lxc_AGENTS.md` for specific boundaries or personas.
    - [x] Update `conductor/product-guidelines.md` with sections for "Docker Application Guidelines" and "Proxmox LXC Guidelines".
    - [x] Ensure any unique "Always", "Ask", "Never" rules from subdirectories are incorporated.
- [x] Task: Conductor - User Manual Verification 'Content Integration - Guidelines' (Protocol in workflow.md)

## Phase 3: Content Integration - Tech Stack and Workflow
- [x] Task: Integrate Tech Stack and Workflow
    - [x] Extract "Tech Stack" details from subdirectory agents (e.g., image tagging conventions, resource defaults).
    - [x] Update `conductor/tech-stack.md` and `conductor/workflow.md` with these specific technical constraints.
    - [x] Update `conductor/index.md` to reference any newly added specialized guideline sections.
- [x] Task: Conductor - User Manual Verification 'Content Integration - Tech Stack and Workflow' (Protocol in workflow.md)

## Phase 4: Final Cleanup and Validation
- [x] Task: Final Validation
    - [x] Verify that no functional instructions were lost during the migration.
    - [x] Run `task lint` to ensure documentation consistency.
    - [x] Confirm that all subdirectory `AGENTS.md` files are successfully archived and removed from their original locations.
- [x] Task: Conductor - User Manual Verification 'Final Cleanup and Validation' (Protocol in workflow.md)
