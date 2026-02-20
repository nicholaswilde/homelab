# Implementation Plan: /task summary command

## Phase 1: Summary Format Analysis
- [x] Review `conductor/workflow.md` task summary requirements.
- [x] Study existing Git Note formats in the repository (`git notes show`).

## Phase 2: Implementation
- [x] Create `.gemini/commands/task_summary.md`.
- [x] Implement `plan.md` parsing and status update.
- [x] Implement Git Note draft generation.
- [x] Implement phase completion check logic.

## Phase 3: Validation
- [x] Test summary generation for a dummy task.
- [x] Test `plan.md` update.
- [x] Ensure Git Note content meets quality standards.
- [x] Document in `docs/tools/gemini-commands.md`.
