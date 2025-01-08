---
tags:
  - lxc
  - proxmox
---
# :material-cached: Apt-Cacher NG

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Interface: `3142/acng-report.html`
    
    :material-information-outline: Configuration path: `/etc/apt-cacher-ng`

=== "AMD64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/apt-cacher-ng.sh)"
    ```

=== "ARM64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/apt-cacher-ng.sh)"
    ```

## :gear: Config

```ini title="/etc/apt-cacher-ng/acng.conf"
CacheDir: /mnt/storage/aptcache
```

```shell
chown -R apt-cacher-ng:apt-cacher-ng /mnt/storage/aptcache
systemctl restart apt-cacher-ng.service
systemctl status apt-cacher-ng.service
journalctl -xeu apt-cacher-ng.service
```

```
http://aptcache.l.nicholaswilde.io:3142/acng-report.html
```

## :material-laptop: Client

```shell title="/etc/apt/apt.conf.d/00aptproxy"
(
  echo 'Acquire::http::Proxy "http://192.168.2.40:3142";' | tee /etc/apt/apt.conf.d/00aptproxy && \
  apt update
)
```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=apt-cacher-ng>
- <https://pimox-scripts.com/scripts?id=Apt-Cacher-NG>
