# Implementation Plan - Migrate AGENTS.md to Conductor

## Phase 1: Analysis and Mapping [checkpoint: 2c0acaf]
- [x] Task: Analyze Root AGENTS.md 2c0acaf
    - [x] Sub-task: Read `AGENTS.md` and identify all distinct sections.
    - [x] Sub-task: Map each section to its target Conductor file (`product.md`, `tech-stack.md`, `product-guidelines.md`, `workflow.md`).
- [x] Task: Conductor - User Manual Verification 'Analysis and Mapping' (Protocol in workflow.md)

## Phase 2: Migration - Tech Stack & MCP [checkpoint: dbf6288]
- [x] Task: Migrate Tech Stack Section dbf6288
    - [x] Sub-task: Create a test plan (checklist) to verify `tech-stack.md` updates.
    - [x] Sub-task: Update `conductor/tech-stack.md` with detailed "Tech Stack" info from `AGENTS.md` (OS details, Containerization specifics).
    - [x] Sub-task: Verify updates against the test checklist.
- [x] Task: Migrate MCP Servers Section dbf6288
    - [x] Sub-task: Create a test plan (checklist) to verify MCP server info in `tech-stack.md`.
    - [x] Sub-task: Add an "MCP Servers" section to `conductor/tech-stack.md` with details on Proxmox, UniFi, and AdGuard Home MCPs.
    - [x] Sub-task: Verify updates against the test checklist.
- [x] Task: Conductor - User Manual Verification 'Migration - Tech Stack & MCP' (Protocol in workflow.md)

## Phase 3: Migration - Guidelines & Workflow
- [x] Task: Migrate Persona and Boundaries
    - [x] Sub-task: Create a test plan (checklist) to verify `product-guidelines.md` updates.
    - [x] Sub-task: Update `conductor/product-guidelines.md` with "Persona" and "Boundaries" (Always, Ask, Never) from `AGENTS.md`.
    - [x] Sub-task: Verify updates against the test checklist.
- [x] Task: Migrate Project Structure and Commands
    - [x] Sub-task: Create a test plan (checklist) to verify `workflow.md` updates.
    - [x] Sub-task: Update `conductor/workflow.md` with "Project Structure" and "Common Commands" (Taskfile operations).
    - [x] Sub-task: Verify updates against the test checklist.
- [x] Task: Conductor - User Manual Verification 'Migration - Guidelines & Workflow' (Protocol in workflow.md)

## Phase 4: Cleanup and Redirection
- [ ] Task: Refactor Root AGENTS.md
    - [ ] Sub-task: Create a test plan (verification step) to ensure `AGENTS.md` points to new docs.
    - [ ] Sub-task: Replace content of `AGENTS.md` with a summary and links to the Conductor files.
    - [ ] Sub-task: Verify `AGENTS.md` renders correctly and links are valid.
- [ ] Task: Conductor - User Manual Verification 'Cleanup and Redirection' (Protocol in workflow.md)
