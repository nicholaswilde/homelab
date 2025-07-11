---
tags:
  - lxc
  - proxmox
---
# :simple-qbittorrent: qBittorrent

[qBittorent][1] is used to download torrents.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8090`

    :fontawesome-solid-user: Username: `admin`

    :material-key: Password: `changeme`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/qbittorrent.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/qbittorrent.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/qbittorrent.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/qbittorrent.yaml"
    ```

## :link: References

[1]: <https://www.qbittorrent.org/>

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "qbittorrent/task-list.txt"
    ```
