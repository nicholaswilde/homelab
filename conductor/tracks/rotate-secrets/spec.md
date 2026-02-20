# Spec: /rotate secrets

## :dart: Goal
Simplify and secure the process of rotating sensitive credentials (passwords, API keys) within the homelab.

## :gear: Requirements
- Generate new high-entropy secrets using secure methods.
- Update target `.env` files with the new secret.
- Automatically re-encrypt updated `.env` files using SOPS.
- Prompt for service restarts after rotation.

## :file_folder: Rotatable Secret Types
The following secret types are considered rotatable:
- **PASSWORD**: Any key containing `PASSWORD` or `PASS`.
- **SECRET**: Any key containing `SECRET`.
- **API_KEY**: Any key containing `API_KEY` or `API_TOKEN`.
- **TOKEN**: Any key containing `TOKEN`.
- **OIDC_CLIENT_SECRET**: Specifically for OIDC integrations.
