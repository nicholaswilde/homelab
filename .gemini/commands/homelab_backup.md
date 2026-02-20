# /homelab backup `<target>`

Trigger manual backups for specific applications or configurations.

## Protocol

1. **Identify Target:**
   - Use `scripts/homelab_backup.py` to resolve `<target>` to a directory.
   - Support aliases: `agh`, `adguard`, `patchmon`, `changedetection`.
   - Support direct application names in `docker/`.

2. **Execute Backup:**
   - Change directory to the target directory.
   - Run `task backup`.
   - Monitor the output for success or failure.

3. **Verify Encryption:**
   - After the backup task completes, check for the existence or update of an `.enc` file (e.g., `*.yaml.enc` or `*.env.enc`).
   - If multiple `.enc` files exist, ensure the relevant one has a recent timestamp.

4. **Announce Completion:**
   - Inform the user that the backup is complete and which files were updated.
