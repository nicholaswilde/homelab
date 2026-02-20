# Implementation Plan: /task summary command

## Phase 1: Summary Format Analysis
- [ ] Review `conductor/workflow.md` task summary requirements.
- [ ] Study existing Git Note formats in the repository (`git notes show`).

## Phase 2: Implementation
- [ ] Create `.gemini/commands/task_summary.md`.
- [ ] Implement `plan.md` parsing and status update.
- [ ] Implement Git Note draft generation.
- [ ] Implement phase completion check logic.

## Phase 3: Validation
- [ ] Test summary generation for a dummy task.
- [ ] Test `plan.md` update.
- [ ] Ensure Git Note content meets quality standards.
- [ ] Document in `docs/tools/gemini-commands.md`.
