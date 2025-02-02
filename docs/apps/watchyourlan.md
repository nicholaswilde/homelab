---
tags:
  - lxc
  - vm
  - proxmox
---
# ![watchyourland](https://cdn.jsdelivr.net/gh/selfhst/icons/png/watchyourlan.png){ width="32"} WatchYourLAN

[WatchYourLAN][1] is used to monitor IP addresses on my network rather than logging into Unifi.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8840`

    :material-information-outline: Configuration path: `/etc/watchyourlan`
    
!!! quote ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/watchyourlan.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/watchyourlan.sh)"
        ```

## :gear: Config

!!! abstract "watchyourlan/config_v2.yaml"

    === "Manual"
    
        ```yaml
        --8<-- "watchyourlan/config_v2.yaml"
        ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=watchyourlan>
- <https://pimox-scripts.com/scripts?id=watchyourlan>

[1]: <https://github.com/aceberg/WatchYourLAN>
