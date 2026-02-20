# /rotate secret <service> <key>

Securely rotate sensitive credentials by generating new high-entropy values and updating encrypted files.

## Protocol

1. **Verify Service & Key:**
   - Confirm that the requested `<service>` and `<key>` exist in the mapping.
   - Use `scripts/rotate_secret.py --list` to see available secrets.

2. **Generate New Secret:**
   - Generate a new high-entropy secret (e.g., 32 characters, mixed case, alphanumeric).
   - For specific types (like passwords), use a format suitable for the service.

3. **Update Environment Files:**
   - Locate the target `.env` file for the service (e.g., `docker/<service>/.env`).
   - If `.env` doesn't exist but `.env.enc` does, decrypt `.env.enc` temporarily.
   - Replace the value of `<key>` with the new secret.

4. **Re-encrypt and Cleanup:**
   - Use SOPS to re-encrypt the updated `.env` file: `sops -e .env > .env.enc`.
   - Securely delete the temporary unencrypted `.env` file.

5. **Restart Service:**
   - Prompt the user to restart the affected service to apply changes.
   - Provide the specific `task` command if available.

6. **Final Verification:**
   - Confirm that `.env.enc` is updated and valid.
   - Remind the user to update any external systems (like LastPass or Bitwarden) if necessary.
