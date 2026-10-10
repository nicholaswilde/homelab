# LXC Application Update Invariants

When asked to update applications deployed on Proxmox LXC containers:

- **Do NOT manually probe or SSH into containers** to search for paths, package managers, or versions.
- **Always run the generic updater directly** with `rtk`:
  ```bash
  rtk uv run python scripts/lxc_update.py <app_name> [-v <version>]
  ```
- **Known Apps:**
  - `drawio`: `rtk uv run python scripts/lxc_update.py drawio [-v <version>]` (Node: `pve04`, VMID: `136`).
  - `localsend`: `rtk uv run python scripts/lxc_update.py localsend` (Node: `pve04`, VMID: `103`).
  - `wallos`: `rtk uv run python scripts/lxc_update.py wallos --node pve03` (Node: `pve03`, VMID: `116`, IP: `192.168.1.46`).
  - `changedetection`: `rtk uv run python scripts/lxc_update.py changedetection --node pve04` (Node: `pve04`, VMID: `116`, IP: `192.168.1.72`).
  - `stirling-pdf`: `rtk uv run python scripts/lxc_update.py stirling-pdf --node pve04 [-v <version>]` (Node: `pve04`, VMID: `133`, IP: `192.168.1.219`).
  - `homepage`: `rtk uv run python scripts/lxc_update.py homepage --node pve04 [-v <version>]` (Node: `pve04`, VMID: `110`, IP: `192.168.1.47`).
  - `convertx`: `rtk uv run python scripts/lxc_update.py convertx --node pve04 [-v <version>]` (Node: `pve04`, VMID: `105`, IP: `192.168.1.23`).
  - `reactive-resume`: `rtk uv run python scripts/lxc_update.py reactive-resume --node pve04 [-v <version>]` (Node: `pve04`, VMID: `134`, IP: `192.168.1.201`).
  - `withoutbg`: `rtk uv run python scripts/lxc_update.py withoutbg --node pve03 [-v <version>]` (Node: `pve03`, VMID: `103`, IP: `192.168.1.118`).
  - `gitea`: `rtk uv run python scripts/lxc_update.py gitea --node pve03 [-v <version>]` (Node: `pve03`, VMID: `108`, IP: `192.168.1.29`).
  - `bentopdf`: `rtk uv run python scripts/lxc_update.py bentopdf --node pve03` (Node: `pve03`, VMID: `104`).
  - `pocket-id`: `rtk uv run python scripts/lxc_update.py pocket-id --node pve03` (Node: `pve03`, VMID: `113`).
  - `homebox`: `rtk uv run python scripts/lxc_update.py homebox --node pve03` (Node: `pve03`, VMID: `106`).
  - `omni-tools`: `rtk uv run python scripts/lxc_update.py omni-tools --node pve04` (Node: `pve04`, VMID: `104`).
  - `gatus`: `rtk uv run python scripts/lxc_update.py gatus --node pve04` (Node: `pve04`, VMID: `102`).
- The script automatically handles node discovery, git pulling on the container, executing container-native `update.sh`, and restarting the service.

## Unsaved Web App Protocol
When asked to update a web app not yet saved:
1. Ensure the app has an operational `update.sh` inside `lxc/<app>/` (or `pve/<app>/`) and verify via `rtk uv run python scripts/lxc_update.py <app_name>`.
2. Persist knowledge across the **3 Layers** immediately:
   - **Layer 1 (Rules):** Add app to Known Apps in [AGENTS.md](file:///home/nicholas/git/nicholaswilde/homelab/AGENTS.md) and [.agents/rules/lxc_updates.md](file:///home/nicholas/git/nicholaswilde/homelab/.agents/rules/lxc_updates.md).
   - **Layer 2 (Serena Memories):** Record node, VMID, and update command in `mem:core` and `mem:suggested_commands`.
   - **Layer 3 (RTK Filters):** Ensure any verbose build noise patterns are filtered in [.rtk/filters.toml](file:///home/nicholas/git/nicholaswilde/homelab/.rtk/filters.toml).

## Webhook & Auto-Update Provisioning
When setting up automated updates triggered by upstream releases:
- Run `rtk uv run python scripts/lxc_webhook.py scaffold <app>` to generate `hooks.json`, `<app>-webhook.service`, and `wh:*` tasks.
- Run `rtk uv run python scripts/lxc_webhook.py deploy <app>` to configure and start the webhook listener inside the LXC container.
- Run `rtk uv run python scripts/lxc_webhook.py cd-watch <app> --repo <owner/repo>` to connect ChangeDetection.io on `pve04`.
- Alternatively invoke the `/webhook add <app> <owner/repo>` skill.
