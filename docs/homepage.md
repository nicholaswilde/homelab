---
tags:
  - lxc
  - proxmox
---
# :simple-homepage: Homepage

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `3000`
    
    :material-information-outline: Configuration (bookmarks.yaml, services.yaml, widgets.yaml) path: `/opt/homepage/config/`

=== "AMD64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/homepage.sh)"
    ```

=== "ARM64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/homepage.sh)"
    ```

## :gear: Config

Make symlinks to repo.

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=homepage>
- <https://pimox-scripts.com/scripts?id=Homepage>
