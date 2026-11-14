---
name: changedetection-update
description: Update ChangeDetection.io, Playwright, and Browserless on Proxmox LXC container 116 (pve04) and verify service health.
---

# /changedetection update

Update `changedetection.io`, `playwright`, and `browserless` inside the ChangeDetection LXC container and verify both
services come back active.

## Description

Targets container `116` (`changedetection`, `192.168.1.72`) on `pve04`, pulling latest repository changes and running
`pve/changedetection/update.sh` via `scripts/lxc_update.py`.

## Protocol

1. **Check Version (Optional):**

    - Compare installed vs latest upstream release:

      ```bash
      rtk uv run python scripts/check_app_version.py changedetection
      ```

2. **Run LXC Updater:**

    - Execute the generic LXC updater directly:

      ```bash
      rtk uv run python scripts/lxc_update.py changedetection --node pve04
      ```

    - This pulls `origin/main` inside `/root/git/nicholaswilde/homelab` on container `116` and runs
      `pve/changedetection/update.sh`:
        - Upgrades `changedetection.io` and `playwright` via `pipx`.
        - Updates `/opt/browserless` from git, runs `npm update`, installs Playwright deps/browsers (`chromium`,
          `firefox`, `webkit`), builds (`npm run build`, `npm run build:function`), and prunes.
        - Restarts `browserless` and `changedetection` systemd services.
    - **Timeout Note:** Browserless `npm update`, Playwright browser downloads, and TypeScript builds can take over
      2 minutes. If a caller times out, check whether `update.sh` is still running before re-invoking:

      ```bash
      ssh root@pve04 "pct exec 116 -- pgrep -af 'update.sh|npm|playwright'"
      ```

3. **Verify Services & Version:**

    - Confirm both `changedetection` and `browserless` are `active`:

      ```bash
      ssh root@pve04 "pct exec 116 -- systemctl is-active changedetection browserless"
      ```

    - Confirm installed version matches upstream:

      ```bash
      rtk uv run python scripts/check_app_version.py changedetection
      ```

    - If `browserless` fails to start due to missing `/opt/browserless/build/index.js` or missing browser binaries
      (`ChromiumCDP`, `FirefoxPlaywright`, `WebKit`), rebuild and install browsers inside container `116`:

      ```bash
      ssh root@pve04 "pct exec 116 -- bash -c 'npm run build --prefix /opt/browserless && /opt/browserless/node_modules/playwright-core/cli.js install --with-deps chromium firefox webkit && systemctl restart browserless'"
      ```

4. **Announce Completion:**

    - Report the updated `changedetection.io` version and `active` status of `changedetection` and `browserless`.
