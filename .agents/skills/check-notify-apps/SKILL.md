---
name: check-notify-apps
description: Compare GitHub release notifications with homelab web application versions across Proxmox LXC containers and Docker apps. Triggers when checking notifications for app releases or comparing notification updates.
---

# Check App Notifications

Compare GitHub release notifications against currently installed versions of homelab web applications deployed across Proxmox LXC containers and Docker.

## When to Use
- User asks: "compare github notifications with my web app versions"
- User asks: "are there any web app release notifications?"
- User asks: "check github notifications for homelab apps"
- User asks: "what apps have updates based on github notifications?"

## Command Reference
Always run with `rtk`:

```bash
# Compare unread release notifications with homelab web apps
rtk uv run python scripts/check_notify_apps.py

# Include read notifications in check
rtk uv run python scripts/check_notify_apps.py --all

# Output structured JSON
rtk uv run python scripts/check_notify_apps.py --json
```

## How It Works
1. Fetches unread notifications via `gh api notifications`.
2. Filters notifications where `subject.type == "Release"`.
3. Maps repository names (`owner/repo`) to homelab applications (via `APP_REGISTRY` in `scripts/check_app_version.py` and local `lxc/`, `pve/`, and `docker/` configurations).
4. Queries the installed version on the target container/host.
5. Formats a comparison table with:
   - App name, node, VMID
   - Currently installed version
   - Notified release version
   - Update status (`Up to date`, `Update available`)
   - Recommended update command (e.g. `rtk uv run python scripts/lxc_update.py <app> --node <node>`)
