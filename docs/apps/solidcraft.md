---
tags:
  - lxc
  - proxmox
---
# :simple-rust: SolidCraft

[SolidCraft][1] is an open-source, parametric 3D CAD application built entirely in pure Rust, running in the browser via WebAssembly with a history-based feature timeline and custom B-rep kernel.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Web UI Port: `80`
    :material-webhook: Webhook Port: `9000`
    :material-information-outline: Installation Directory: `/srv/solidcraft`

SolidCraft Web runs as a client-side WebAssembly single-page application served by Nginx in a Debian 13 (Trixie) LXC container on `pve03` (VMID 138).

## :gear: Config

### Webhook Automation

A webhook listener runs on port `9000` to handle automated deployment and update triggers:

```shell
curl -X POST http://localhost:9000/hooks/update-app
```

## :rocket: Upgrade

!!! code ""

    === "Task"

        ```shell
        task update
        ```

    === "CLI Helper"

        ```shell
        uv run python scripts/lxc_update.py solidcraft --node pve03
        ```

    === "Manual"

        ```shell
        /root/git/nicholaswilde/homelab/lxc/solidcraft/update.sh
        ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "solidcraft/task-list.txt"
    ```

## :link: References

- [SolidCraft GitHub Repository][1]
- [SolidCraft Official Website][2]

[1]: <https://github.com/tangency-labs/solidcraft>
[2]: <https://solidcraft.pro>
