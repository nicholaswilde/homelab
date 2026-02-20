# Implementation Plan: /rotate secrets

## Phase 1: Secret Identification [checkpoint: 243525b]
- [x] (243525b) Define which secret types are rotatable (e.g., standard .env keys).
- [x] (243525b) Map services to their sensitive environment variables.

## Phase 2: Implementation [checkpoint: 77e1b50]
- [x] (77e1b50) Create `.gemini/commands/rotate_secret.md`.
- [x] (77e1b50) Develop `scripts/rotate_secret.py` to handle generation, replacement, and encryption.

## Phase 3: Validation
- [ ] Test rotating a dummy secret in a test app.
- [ ] Verify that the file remains properly encrypted and the value is updated.
