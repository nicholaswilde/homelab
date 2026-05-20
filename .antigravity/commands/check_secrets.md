# /check secrets

Verify the encryption status of all sensitive files project-wide to prevent accidental leaks.

## Protocol

1. **Scan for Sensitive Files:**
   - Use `scripts/check_secrets.py` to identify all potentially sensitive files.
   - Patterns to check: `.env`, `*.enc`, and files containing `secret` or `creds`.

2. **Verify Encryption Integrity:**
   - For every `.enc` file found:
     - Attempt to decrypt using `sops -d`.
     - If a corresponding unencrypted file exists (e.g., `.env` for `.env.enc`), compare their contents.
     - Report if the unencrypted version is out-of-sync with the encrypted one.

3. **Identify Unprotected Files:**
   - Report any `.env` or other sensitive files that are NOT tracked by `.gitignore` and do NOT have a corresponding `.enc` file.
   - Warn about any sensitive files that are staged but not encrypted.

4. **Summary Report:**
   - Output a list of:
     - ✅ Healthy (Encrypted and in-sync)
     - ⚠️ Out-of-sync (Unencrypted differs from Encrypted)
     - ❌ Unprotected (Unencrypted, no Encrypted version, not ignored)
     - 🔒 Missing Key/Error (Decryption failed)

5. **Recommendations:**
   - Provide commands to fix issues (e.g., `sops -e .env > .env.enc`).
