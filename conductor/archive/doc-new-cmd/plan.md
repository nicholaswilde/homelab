# Implementation Plan: /doc new command

## Phase 1: Template Analysis
- [x] Review `docs/.template-docker.md.j2`, `docs/.template-tool.md.j2`, and `docs/.template.md.j2`.
- [x] Identify common variables across templates.

## Phase 2: Implementation
- [x] Create `.gemini/commands/doc_new.md`.
- [x] Develop `scripts/doc_new.py` to handle Jinja2 substitution and file placement.
- [x] Implement automatic navigation update logic.

## Phase 3: Validation
- [x] Test creating a new app doc.
- [x] Test creating a new tool doc.
- [x] Verify MkDocs build after new doc creation.
