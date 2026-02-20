# Spec: /rotate secrets

## :dart: Goal
Simplify and secure the process of rotating sensitive credentials (passwords, API keys) within the homelab.

## :gear: Requirements
- Generate new high-entropy secrets using secure methods.
- Update target `.env` files with the new secret.
- Automatically re-encrypt updated `.env` files using SOPS.
- Prompt for service restarts after rotation.
