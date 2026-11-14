---
name: vaultwarden-update
description: Update Vaultwarden server (cargo source build) and web-vault on Proxmox LXC container 112 (pve03) and verify /alive health.
---

# /vaultwarden update

Update `vaultwarden` and `bw_web_builds` web-vault inside its Proxmox LXC container and verify service health.

## Description

Targets container `112` (`vaultwarden`) on `pve03`, pulling latest repository changes and running
`pve/vaultwarden/update.sh` via `scripts/lxc_update.py`.

## Protocol

1. **Run LXC Updater:**

    - Execute the generic LXC updater directly:

      ```bash
      rtk uv run python scripts/lxc_update.py vaultwarden --node pve03
      ```

    - Optionally pass `-v <version>` to build a specific tag:

      ```bash
      rtk uv run python scripts/lxc_update.py vaultwarden --node pve03 -v <version>
      ```

    - Inside container `112`, `pve/vaultwarden/update.sh`:
        - Updates Rust stable toolchain via `rustup` and prunes non-stable toolchains.
        - Downloads `dani-garcia/vaultwarden` source tarball to `/tmp/vaultwarden-src` and builds with `cargo build`
          (`sqlite,mysql,postgresql`).
        - Backs up `/opt/vaultwarden/bin/vaultwarden` to `.bak` and replaces it with the newly built binary.
        - Updates `/opt/vaultwarden/web-vault` from `dani-garcia/bw_web_builds` when newer.
        - Starts `vaultwarden` and verifies `https://localhost:8000/alive` (or HTTP), rolling back to `.bak` on failure.
    - **Timeout Note:** `cargo build` from source takes several minutes. If a caller times out, check whether `cargo`
      or `update.sh` is still running before re-invoking:

      ```bash
      ssh root@pve03 "pct exec 112 -- pgrep -af 'update.sh|cargo|rustc|rustup'"
      ```

2. **Verify Service & Versions:**

    - Confirm `vaultwarden` is `active` and responding on `/alive`, and inspect installed server/web-vault versions:

      ```bash
      ssh root@pve03 "pct exec 112 -- bash -c 'systemctl is-active vaultwarden && /opt/vaultwarden/bin/vaultwarden --version && cat /opt/vaultwarden/web-vault/vw-version.json'"
      ```

3. **Announce Completion:**

    - Report the installed `vaultwarden` and `web-vault` versions and `vaultwarden` service status.
