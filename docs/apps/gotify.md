---
tags:
  - lxc
  - notifications
  - proxmox
---
# ![gotify](https://cdn.jsdelivr.net/gh/selfhst/icons/png/gotify.png){ width="32" } Gotify

[Gotify][1] is a simple server for sending and receiving messages

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `80`

    :material-information-outline: Configuration path: `/opt/gotify/config.yml`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/gotify.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/gotify.sh)"
        ```

## :gear: Config

!!! abstract "`homelab/docker/gotify/.env`"

    ```ini
    --8<-- "gotify/.env.tmpl"
    ```

??? abstract "`homelab/pve/gotify/config.yml`"

    ```yaml
    --8<-- "gotify/config.yml.tmpl"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "gotify/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=gotify>
- <https://pimox-scripts.com/scripts?id=gotify>

[1]: <https://gotify.net/>
