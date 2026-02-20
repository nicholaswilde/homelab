# Implementation Plan: /doc new command

## Phase 1: Template Analysis
- [ ] Review `docs/.template-docker.md.j2`, `docs/.template-tool.md.j2`, and `docs/.template.md.j2`.
- [ ] Identify common variables across templates.

## Phase 2: Implementation
- [ ] Create `.gemini/commands/doc_new.md`.
- [ ] Develop `scripts/doc_new.py` to handle Jinja2 substitution and file placement.
- [ ] Implement automatic navigation update logic.

## Phase 3: Validation
- [ ] Test creating a new app doc.
- [ ] Test creating a new tool doc.
- [ ] Verify MkDocs build after new doc creation.
