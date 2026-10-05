---
name: check-app-version
description: Compare installed version of a homelab LXC web app (stirling-pdf, drawio, wallos, changedetection, localsend) against its latest upstream release without modifying containers or updating. Triggers when checking if apps are up-to-date or comparing versions.
---

# Check App Version

Quickly compare currently installed version of a homelab LXC web app to its upstream release without running updates.

## When to Use
- User asks: "what version of `<app>` is installed?"
- User asks: "is `<app>` up to date?"
- User asks: "compare installed vs released version of `<app>`"
- User asks: "check if updates are available for `<app>`"

## Command Reference
Always run with `rtk`:

```bash
# Check a single app
rtk uv run python scripts/check_app_version.py <app_name>

# Check all registered apps
rtk uv run python scripts/check_app_version.py --all

# Output structured JSON
rtk uv run python scripts/check_app_version.py <app_name> --json
```

## Known Supported Apps
- `stirling-pdf`: Node `pve04`, VMID 133
- `drawio`: Node `pve04`, VMID 136
- `changedetection`: Node `pve04`, VMID 116
- `wallos`: Node `pve03`, VMID 116
- `localsend`: Node `pve04`, VMID 103
- `homepage`: Node `pve04`, VMID 110
