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

## :link: References

[1]: <https://www.qbittorrent.org/>
