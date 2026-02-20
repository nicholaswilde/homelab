# /audit deps

Audit Docker image dependencies across all `compose.yaml` files and report outdated or vulnerable versions.

## Protocol

1. **Scan `compose.yaml` Files:**
   - Recursively search the `docker/` directory for all `compose.yaml` files.
   - For each file, parse and extract all unique image tags.
   - Map each image to its corresponding registry (Docker Hub, GHCR).

2. **Query Registries for Updates:**
   - For each identified image and tag:
     - Determine the registry (Docker Hub or GHCR).
     - Obtain an authentication token (anonymous for Docker Hub public images, or using `GITHUB_TOKEN` for GHCR).
     - Query the registry API to fetch the list of available tags for that image.
     - Identify if a newer tag exists based on semantic versioning or timestamp.

3. **Check for Security Advisories (Optional/Best Effort):**
   - If available, cross-reference image versions with known security advisory databases.

4. **Generate Audit Report:**
   - Present a consolidated table of all audited images.
   - Include columns for "Current Version", "Latest Version", "Status" (Up to Date/Outdated), and "Security" (if available).
   - Provide suggested update commands (e.g., `docker compose pull` or updating the file).
