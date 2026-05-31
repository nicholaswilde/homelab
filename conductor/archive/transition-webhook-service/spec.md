# Spec: /transition webhook service

## :dart: Goal
Transition the live webhook systemd service configuration to run the new unified, modular `builders/` webhook architecture.

## :gear: Requirements
- Re-configure `reprepro-webhook.service` to invoke the webhook configuration defined in the `builders` workspace (`builders/webhook/hooks.json`).
- Ensure webhook triggers are correctly configured to execute `builders/scripts/sync.sh` on standard payloads.
- Test service interaction and logs reporting.
