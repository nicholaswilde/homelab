---
tags:
  - proxmox
---
# :simple-proxmox: Proxmox

## :hammer_and_wrench: Post Installation

!!! example ""

    :material-console-network: Default Port: `8006`

### Post Install

=== "AMD64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/post-pve-install.sh)"
    ```

=== "ARM64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/misc/post-pve-install.sh)"
    ```

### Add LXC IP Tag

=== "AMD64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/add-lxc-iptag.sh)"
    ```

=== "ARM64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/add-lxc-iptag.sh)"
    ```

### Update

=== "AMD64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/update-lxcs.sh)"
    ```

=== "ARM64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/add-lxc-iptag.sh)"
    ```

## :material-ip-network: Static IP

WIP

## simple-authentik: Authentik

WIP

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=homepage>
- <https://pimox-scripts.com/scripts?id=Homepage>
