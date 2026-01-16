# Specification: Migrate Subdirectory AGENTS.md to Conductor

## Overview
This track focuses on consolidating the documentation currently stored in various `AGENTS.md` files located in subdirectories (e.g., `docker/`, `docs/`, `lxc/`, `scripts/`) into the centralized Conductor documentation structure.

## Goals
1.  **Repository-Wide Consolidation:** Identify all `AGENTS.md` files across all subdirectories.
2.  **Information Extraction:** Extract relevant "Persona", "Tech Stack", "Boundaries", and "Guidelines" from these files.
3.  **Conductor Integration:** Merge the extracted information into the appropriate global Conductor files (`tech-stack.md`, `product-guidelines.md`, `workflow.md`).
4.  **Archival:** Move the original subdirectory `AGENTS.md` files to an archive location or a sub-path within `conductor/archive/` to maintain a history of the original instructions while removing them from their active locations.

## Functional Requirements
- Recursive scan of all subdirectories (respecting `.gitignore`) for files named `AGENTS.md`.
- Semantic merging of content: avoid duplicate general instructions but preserve specific directory-level rules (e.g., Docker image tagging rules, LXC disk size defaults).
- Update `conductor/index.md` if any new categories or specialized guidelines are created during consolidation.

## Non-Functional Requirements
- **Consistency:** Ensure the merged content matches the existing Conductor style and formatting.
- **Traceability:** Maintain a clear record of where the original information came from (e.g., using comments in the Conductor files or a migration log).

## Acceptance Criteria
- All subdirectory `AGENTS.md` files have been moved to an archival location.
- The root Conductor documentation reflects the directory-specific guidelines (e.g., "Docker Guidelines", "LXC Guidelines").
- No information loss: all unique boundaries and technical constraints from the original files are present in Conductor.

## Out of Scope
- Refactoring the actual code or folder structures described in the documentation.
- Updating documentation files other than `AGENTS.md`.
