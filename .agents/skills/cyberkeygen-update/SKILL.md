---
name: cyberkeygen-update
description: Update CyberKeyGen on Proxmox LXC container 132 (pve04), rebuild the Vite static bundle, recreate the nginx container, and verify HTTP health.
---

# /cyberkeygen update

Update `cyberkeygen` inside its Proxmox LXC container by pulling upstream source changes, rebuilding the static Vite
bundle, recreating the nginx Docker container, and verifying HTTP health.

## Description

Targets container `132` (`cyberkeygen`, `192.168.1.202`) on `pve04`, pulling latest repository changes and running
`docker/cyberkeygen/update.sh` via `scripts/lxc_update.py`.

## Protocol

1. **Run LXC Updater:**

    - Execute the generic LXC updater directly:

      ```bash
      rtk uv run python scripts/lxc_update.py cyberkeygen --node pve04
      ```

    - Optionally pass `-v <ref>` to build a specific tag or commit:

      ```bash
      rtk uv run python scripts/lxc_update.py cyberkeygen --node pve04 -v <tag>
      ```

    - Inside container `132`, `docker/cyberkeygen/update.sh`:
        - Installs `nodejs` and `npm` via `apt-get` if missing.
        - Fetches `origin` in `/opt/cyberkeygen` and resets to `origin/main` (or `<ref>`).
        - Runs `npm install` and `npm run build` to populate `/opt/cyberkeygen/dist`.
        - Pulls and recreates the `cyberkeygen` nginx container via `docker/cyberkeygen/compose.yaml`.
        - Verifies `http://localhost:8080/` returns HTTP `200`/`301`/`302`.

2. **Verify Service Health:**

    - Confirm the `cyberkeygen` Docker container is running and serving HTTP `200`:

      ```bash
      ssh root@pve04 "pct exec 132 -- bash -c 'docker ps --filter name=cyberkeygen && curl -s -o /dev/null -w \"%{http_code}\n\" http://localhost:8080/'"
      ```

3. **Announce Completion:**

    - Report the updated `/opt/cyberkeygen` commit SHA and `cyberkeygen` container / HTTP status.
