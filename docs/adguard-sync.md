---
tags:
  - lxc
  - proxmox
---
# :simple-adguard: Adguard Home Sync

[AdGuard Home Sync][1] is used to sync settings between my [AdGuard Home][2] instances.

It is installed only on the primary instance and is scheduled to run once a day, which is scheduled in the config file.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8080`
    
    :material-information-outline: Configuration path: `/opt/adguardhome-sync`

```shell title="Install or Update"
(
  [ -d /opt/adguardhome-sync ] || mkdir -p /opt/adguardhome-sync && \
  cd /opt/adguardhome-sync && \
  curl https://installer.l.nicholaswilde.io/bakito/adguardhome-sync | bash
)
```

## :gear: Config

```ini title="/opt/adguardhome-sync/adguardhome-sync.service"
[Unit]
Description = AdGuardHome Sync
After = network.target

[Service]
ExecStart = /opt/adguardhome-sync/adguardhome-sync --config /opt/adguardhome-sync/adguardhome-sync.yaml run

[Install]
WantedBy = multi-user.target
```

```shell
(
 cp /opt/adguardhome-sync/adguardhome-sync.service /etc/systemd/system/ && \
 systemctl enable adguardhome-sync.service && \
 systemctl start adguardhome-sync.service && \
 systemctl status adguardhome-sync.service
) 
```


## :link: References

- <https://github.com/bakito/adguardhome-sync>

[1]: <https://github.com/bakito/adguardhome-sync>
[2]: <./adguard.md>
