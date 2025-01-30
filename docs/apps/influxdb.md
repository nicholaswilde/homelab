---
tags:
  - lxc
  - proxmox
---
# :simple-influxdb: InfluxDB

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8086`

!!! quote ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/influxdb.sh)"
        ```

    === "ARM64"

         ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/influxdb.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=influxdb>
- <https://pimox-scripts.com/scripts?id=InfluxDB>
