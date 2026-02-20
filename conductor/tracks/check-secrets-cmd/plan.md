# Implementation Plan: /check secrets command

## Phase 1: Pattern Definition
- [ ] Identify all file naming conventions for sensitive data in the repo.
- [ ] List directories that typically contain secrets.

## Phase 2: Implementation
- [ ] Create `.gemini/commands/check_secrets.md`.
- [ ] Develop `scripts/check_secrets.py` to perform the sops-based verification.

## Phase 3: Validation
- [ ] Test with a known out-of-sync secret file.
- [ ] Test with a new unencrypted `.env` file.
