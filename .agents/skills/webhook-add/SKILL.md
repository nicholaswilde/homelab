---
name: webhook-add
description: Scaffold, deploy, and connect automated webhook update listeners and ChangeDetection watches for homelab LXC web applications.
---

# /webhook add `<app_name>` `<github_repo>`

Automate the end-to-end setup of webhook listener daemons and ChangeDetection release tracking for any homelab LXC web application.

## Description

This skill provisions incoming webhook listeners (`adnanh/webhook` on port `9000`) for LXC containers running web apps. When a new release tag appears in upstream GitHub Atom feeds, ChangeDetection.io automatically sends an HTTP POST trigger to the webhook listener, which runs `update.sh -s` to upgrade the application idempotently and notify the user.

## Protocol

1. **Scaffold Local Files:**
   - **Step:** Generate `hooks.json`, `<app_name>-webhook.service`, and inject `wh:*` tasks into `lxc/<app_name>/Taskfile.yml`.
   - **Command:** `rtk uv run python scripts/lxc_webhook.py scaffold <app_name>`
   - **Verify:** Ensure `lxc/<app_name>/hooks.json` and `lxc/<app_name>/<app_name>-webhook.service` exist.

2. **Deploy to Proxmox LXC Container:**
   - **Step:** Ensure `webhook` package is installed inside container, install `<app_name>-webhook.service`, and activate it.
   - **Command:** `rtk uv run python scripts/lxc_webhook.py deploy <app_name>`
   - **Verify:** Systemd reports `<app_name>-webhook` is `active`.

3. **Register ChangeDetection Release Watch:**
   - **Step:** Create or update the upstream GitHub Atom feed watch (`https://github.com/<github_repo>/releases.atom`) in ChangeDetection.io on `pve04` (container 116).
   - **Command:** `rtk uv run python scripts/lxc_webhook.py cd-watch <app_name> --repo <github_repo>`
   - **Verify:** Watch created with title `release-<app_name>` and notification URL `post://<container_ip>:9000/hooks/update-app?method=POST&header=Content-Type:application/json`.

4. **Verify Webhook Execution:**
   - **Step:** Send a test trigger to verify container response.
   - **Command:** `rtk uv run python scripts/lxc_webhook.py test <app_name>`
   - **Verify:** Webhook responds with HTTP 200 `Updating <app_name>...`.

5. **Commit and Sync:**
   - Stage and commit generated scaffolding files:
     ```shell
     rtk git add lxc/<app_name>/hooks.json lxc/<app_name>/<app_name>-webhook.service lxc/<app_name>/Taskfile.yml
     rtk git commit -m "feat(<app_name>): add webhook listener and update automation"
     ```
   - Use `/app sync <app_name>` if container needs local repository changes pulled.
