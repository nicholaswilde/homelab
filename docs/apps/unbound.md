---
tags:
  - lxc
  - proxmox
---
# ![unbound][1]{ width="32" } Unbound

[Unbound][2] is used as a recursive DNS resolver and cacher.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `5335`
    
    :material-information-outline: Configuration path: `/etc/unbound/unbound.conf.d/unbound.conf`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/unbound.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/unbound.sh)"
        ```

## :gear: Config

!!! abstract "`/etc/unbound/unbound.conf.d/unbound.conf`"

    === "Manual"

        ```yaml
        --8<-- "unbound/unbound.conf.d/unbound.conf"
        ```

### :simple-adguard: AdGuard Home

!!! example ""

    Upstream DNS Servers: `192.168.2.23:5335`

    Disable Cache Size

    Disable DNSSEC

## :link: References

- <https://medium.com/@life-is-short-so-enjoy-it/homelab-adguard-setup-unbound-as-iterative-dns-6048d5072276>

[1]: <https://cdn.jsdelivr.net/gh/selfhst/icons/svg/unbound.svg>
[2]: <https://www.nlnetlabs.nl/projects/unbound/about/>

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "unbound/task-list.txt"
    ```
