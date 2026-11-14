---
name: drawio-update
description: Update Draw.io on Proxmox LXC container 136 (pve04) via WAR release download and verify Tomcat service health.
---

# /drawio update

Update `drawio` inside its Proxmox LXC container and verify `tomcat10` and installed version.

## Description

Targets container `136` (`drawio`) on `pve04`, pulling latest repository changes and running `lxc/drawio/update.sh`
via `scripts/lxc_update.py`.

## Protocol

1. **Check Version (Optional):**

    - Compare installed vs latest upstream release:

      ```bash
      rtk uv run python scripts/check_app_version.py drawio
      ```

2. **Run LXC Updater:**

    - Execute the generic LXC updater directly:

      ```bash
      rtk uv run python scripts/lxc_update.py drawio
      ```

    - Optionally pass `-v <version>` to install a specific release tag:

      ```bash
      rtk uv run python scripts/lxc_update.py drawio -v <version>
      ```

    - Inside container `136`, `lxc/drawio/update.sh`:
        - Compares `/var/lib/tomcat10/webapps/draw.version` against upstream `jgraph/drawio` release (or `<version>`).
        - Stops `tomcat10.service`, backs up `ROOT.war` to `ROOT.war.bak`, downloads `draw.war` to
          `/var/lib/tomcat10/webapps/ROOT.war`, writes `draw.version`, and restarts `tomcat10.service`.

3. **Verify Service & Version:**

    - Confirm `tomcat10` is `active` and installed version matches upstream:

      ```bash
      ssh root@pve04 "pct exec 136 -- systemctl is-active tomcat10"
      rtk uv run python scripts/check_app_version.py drawio
      ```

4. **Announce Completion:**

    - Report the installed `drawio` version and `tomcat10` service status.
