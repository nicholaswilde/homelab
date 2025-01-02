---
tags:
  - lxc
  - proxmox
---
# :simple-adguard: AdGuard Home

[AdGuard Home][1] (AGH) is used to filter ads and as my DNS rewites (assign hostnames to IP addresses).

I have two instances of AGH running: one as an LXC and one on a bare metal Raspberry Pi 2.

Syncing between the instances are done using [AdGuard Home Sync][2]

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `3000`

    :material-information-outline: Configuration path: `/opt/AdGuardHome`
    
=== "AMD64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/adguard.sh)"
    ```

=== "ARM64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/adguard.sh)"
    ```

## :gear: Config

```yaml title="/opt/AdGuardHome/AdGuardHome.yaml"
rewrites:
    - domain: adguard02.l.nicholaswilde.io
      answer: 192.168.3.250
```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=adguard>
- <https://pimox-scripts.com/scripts?id=adguard>

[1]: <https://adguard.com/en/adguard-home/overview.html>
[2]: <./adguard-sync.md>
