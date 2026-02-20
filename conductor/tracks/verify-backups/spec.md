# Spec: /verify backups

## :dart: Goal
Ensure data integrity and restore reliability by automating the verification of encrypted backups.

## :gear: Requirements
- Randomly or exhaustively select `.enc` backup files for verification.
- Attempt decryption using SOPS.
- Verify file integrity (e.g., via checksums or basic format validation after decryption).
- Report success/failure and alert on corruption.
