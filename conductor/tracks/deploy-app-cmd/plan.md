# Implementation Plan: /deploy <app_name> command

## Phase 1: Template Analysis

- [x] Review `docker/.template` and `lxc/.template` file structures.
- [x] Identify variables that need substitution.

## Phase 2: Implementation

- [x] Create `.gemini/commands/deploy.md`.
- [x] Implement directory creation and template copying.
- [x] Implement interactive substitution for `.env.tmpl`.
- [x] Implement automatic track creation for the new deployment.

## Phase 3: Validation

- [x] Test deployment of a dummy Docker app.
- [x] Test deployment of a dummy LXC app.
- [x] Ensure `conductor/workflow.md` compliance.
