# Implementation Plan: /check secrets command

## Phase 1: Pattern Definition
- [x] Identify all file naming conventions for sensitive data in the repo.
- [x] List directories that typically contain secrets.

## Phase 2: Implementation
- [x] Create `.gemini/commands/check_secrets.md`.
- [x] Develop `scripts/check_secrets.py` to perform the sops-based verification.

## Phase 3: Validation
- [x] Test with a known out-of-sync secret file.
- [x] Test with a new unencrypted `.env` file.
