# Implementation Plan: /transition webhook service

## Phase 1: Setup & Configuration
- [ ] Audit the `builders/webhook/hooks.json` configuration to confirm trigger scripts are properly defined.
- [ ] Review systemd service templates under `builders/webhook/` or `builders/Taskfile.yml`.

## Phase 2: Migration & Deployment
- [ ] Copy the systemd service configuration to `/etc/systemd/system/reprepro-webhook.service`.
- [ ] Reload systemd and restart the `reprepro-webhook` service.

## Phase 3: Validation
- [ ] Trigger the webhook locally using `task builders:wh:test` or curl payloads.
- [ ] Verify webhook logs via `journalctl -u reprepro-webhook` to ensure correct service behavior.
