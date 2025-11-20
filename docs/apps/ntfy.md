---
tags:
  - lxc
  - notifications
  - proxmox
---
# :simple-ntfy: ntfy

[ntfy][1] is a simple HTTP-based pub-sub notification service. It allows you to send notifications to your phone or desktop via scripts from any computer, and/or using a REST API.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `80`

    :material-information-outline: Configuration path: `/etc/ntfy/`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/ct/ntfy.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(curl -sL https://github.com/asylumexp/Proxmox/raw/main/ct/ntfy.sh)"
        ```

## :gear: Config

### :desktop_computer: Server

!!! abstract "`homelab/docker/ntfy/.env`"

    ```ini
    --8<-- "ntfy/.env.tmpl"
    ```

??? abstract "`homelab/pve/ntfy/server.yml`"

    ```yaml
    --8<-- "ntfy/server.yml.tmpl"
    ```

### :computer: Client

??? abstract "`homelab/pve/ntfy/client.yml`"

    ```yaml
    --8<-- "ntfy/client.yml.tmpl"
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/ntfy.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/ntfy.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "ntfy/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=ntfy>
- <https://pimox-scripts.com/scripts?id=ntfy>

[1]: <https://ntfy.sh/>
