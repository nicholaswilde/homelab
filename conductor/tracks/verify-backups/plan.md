# Implementation Plan: /verify backups

## Phase 1: Verification Logic
- [ ] Define what constitutes a "verified" backup (e.g., successful decryption + valid content type).
- [ ] List all backup locations.

## Phase 2: Implementation
- [ ] Create `.gemini/commands/verify_backups.md`.
- [ ] Develop `scripts/verify_backups.py` to automate the check.

## Phase 3: Validation
- [ ] Test with a healthy backup.
- [ ] Test with a purposefully corrupted or mis-encrypted file.
