---
name: withoutbg-update
description: Update withoutbg on Proxmox LXC container 103 (pve03), handling upstream web-monorepo release guards and verifying backend/frontend services.
---

# /withoutbg update

Update `withoutbg` inside its Proxmox LXC container and verify `withoutbg-backend` and `withoutbg-frontend` services.

## Description

Targets container `103` (`withoutbg`, `192.168.1.118`) on `pve03`, pulling latest repository changes and running
`lxc/withoutbg/update.sh` via `scripts/lxc_update.py`.

## Protocol

1. **Run LXC Updater:**

    - Execute the generic LXC updater directly:

      ```bash
      rtk uv run python scripts/lxc_update.py withoutbg --node pve03
      ```

    - Optionally pass `-v <version>` to target a specific release tag:

      ```bash
      rtk uv run python scripts/lxc_update.py withoutbg --node pve03 -v <version>
      ```

    - Inside container `103`, `lxc/withoutbg/update.sh`:
        - Reads `/opt/withoutbg/apps/web/frontend/package.json` for installed version and queries
          `withoutbg/withoutbg` on GitHub.
        - Guards against Python-SDK-only releases lacking `apps/web/frontend` (e.g., `1.5.0`+), keeping `1.4.0` when
          upstream omits the web monorepo.
        - When updating, backs up `.env.local`, stops `withoutbg-frontend` and `withoutbg-backend`, extracts tarball to
          `/opt/withoutbg`, runs `uv sync` (Python 3.12) in `apps/web/backend` and `npm install` + `npm run build` in
          `apps/web/frontend`, and restarts both services.

2. **Verify Services:**

    - Confirm `withoutbg-backend` and `withoutbg-frontend` are `active`:

      ```bash
      ssh root@pve03 "pct exec 103 -- systemctl is-active withoutbg-backend withoutbg-frontend"
      ```

3. **Announce Completion:**

    - Report installed/target `withoutbg` version (or upstream SDK-only guard notice) and status of
      `withoutbg-backend` and `withoutbg-frontend`.
