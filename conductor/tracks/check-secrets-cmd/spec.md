# Spec: /check secrets command

## :dart: Goal
Verify the encryption status of all sensitive files project-wide to prevent accidental leaks.

## :gear: Requirements
- Scan for patterns like `.env`, `*.yaml`, and `*.enc`.
- Run `sops -d` comparisons against all `.enc` files.
- Report any unencrypted files that should be protected.
