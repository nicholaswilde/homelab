---
tags:
  - lxc
  - proxmox
---
# :simple-adguard: AdguardHome sync

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8080`
    
    :material-information-outline: Configuration path: `/opt/adguardhome-sync`

```shell title="Download and decompress to tmp dir"
bash -c "$(wget -qLO - https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/adguardhome-sync/download.sh)"
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
