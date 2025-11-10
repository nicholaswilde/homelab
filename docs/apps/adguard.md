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

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/adguard.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/adguard.sh)"
        ```

## :gear: Config

!!! abstract "/opt/AdGuardHome/AdGuardHome.yaml"

    ```yaml
    rewrites:
        - domain: adguard02.l.nicholaswilde.io
          answer: 192.168.3.250
    ```

### :handshake: Service

!!! abstract "`/etc/systemd/system/AdGuardHome.service`"

    === "Automatic"

        ```shell
        cat > /etc/systemd/system/AdGuardHome.service <<EOF
        --8<-- "adguardhome/AdGuardHome.service"
        EOF
        ```

    === "Download"

        ```shell
        wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/adguardhome/AdGuardHome.service -O /etc/systemd/system/AdGuardHome.service
        ```
        
    === "Manual"

        ```ini
        --8<-- "adguardhome/AdGuardHome.service"
        ```
    
!!! code "Enable service"

    === "Manual"
    
        ```shell
        (
         systemctl enable AdGuardHome.service && \
         systemctl start AdGuardHome.service && \
         systemctl status AdGuardHome.service
        ) 
        ```

## :rocket: Upgrade

Upgrading the app is done [via the web GUI][3].

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "adguardhome/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=adguard>
- <https://pimox-scripts.com/scripts?id=adguard>

[1]: <https://adguard.com/en/adguard-home/overview.html>
[2]: <./adguard-sync.md>
[3]: <https://github.com/adguardteam/adguardhome/wiki/Getting-Started#update>
