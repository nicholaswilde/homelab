# Security & Sensitive Data Invariants

## Strict Prohibition on Sensitive Data
- **NEVER stage or commit sensitive data** to version control under any circumstances.
  - This includes: passwords, API keys, access tokens, private keys, SSH keys, certificates, database credentials, authentication tokens, and webhook secrets.
- **Never commit unencrypted environment or configuration files**:
  - Never commit `.env` files.
  - Never commit unencrypted secrets files (e.g. `secret.txt`, `creds.json`).
  - Never commit config or settings files that contain embedded plain-text passwords or secret tokens (e.g. `settings.yaml`, `config.json`).
- **Use SOPS for Secret Storage**:
  - All secret files must be encrypted with SOPS (`.env.enc`, `secret.txt.enc`, etc.) before being committed.
  - Commit only the `.enc` files and template files (`.env.tmpl`).
- **Pre-Commit Verification**:
  - Before running `git commit`, inspect staged diffs with `rtk git diff --staged` or run `uv run python scripts/check_secrets.py` to ensure no sensitive files or plaintext tokens are included.
