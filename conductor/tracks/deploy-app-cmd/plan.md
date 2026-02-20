# Implementation Plan: /deploy <app_name> command

## Phase 1: Template Analysis
- [ ] Review `docker/.template` and `lxc/.template` file structures.
- [ ] Identify variables that need substitution.

## Phase 2: Implementation
- [ ] Create `.gemini/commands/deploy.md`.
- [ ] Implement directory creation and template copying.
- [ ] Implement interactive substitution for `.env.tmpl`.
- [ ] Implement automatic track creation for the new deployment.

## Phase 3: Validation
- [ ] Test deployment of a dummy Docker app.
- [ ] Test deployment of a dummy LXC app.
- [ ] Ensure `conductor/workflow.md` compliance.
