# Specification: Migrate AGENTS.md to Conductor

## Context
The project currently uses `AGENTS.md` as a central instruction file for AI agents. With the adoption of Conductor, this information needs to be migrated to the standardized Conductor structure (`product.md`, `product-guidelines.md`, `tech-stack.md`, `workflow.md`) to avoid duplication and ensure a single source of truth.

## Goals
1.  **Consolidate Knowledge:** Move relevant sections from `AGENTS.md` to their corresponding Conductor files.
2.  **Preserve Custom Instructions:** Ensure specific "Persona", "Boundaries", and "MCP Servers" instructions are preserved in the appropriate context.
3.  **Redirect:** Update `AGENTS.md` to point agents to the Conductor documentation for general project context, while keeping it as a lightweight entry point or strictly for specific agent prompts not covered by Conductor.
4.  **Standardize:** Ensure all sub-directory `AGENTS.md` files (e.g., in `docker/`, `docs/`) are acknowledged and referenced or integrated if appropriate, though the primary focus is the root `AGENTS.md`.

## Detailed Migration Map
- **Persona & Boundaries:** Move to `conductor/product-guidelines.md` (or `workflow.md` if process-related).
- **Tech Stack:** Move to `conductor/tech-stack.md`.
- **Project Structure & Common Commands:** Move to `conductor/workflow.md`.
- **MCP Servers:** Move to `conductor/tech-stack.md` (Integrations section) or a dedicated section in `workflow.md` if they define operational tools.

## Non-Goals
- We are not deleting `AGENTS.md` entirely yet; we are reducing it to a reference pointer or specific runtime instruction file.
- We are not refactoring the entire codebase, only the documentation structure.
