---
tags:
  - lxc
  - proxmox
---
# :material-cached: Apt-Cacher NG

[Apt-Cacher NG][1] is used as a cache system for the debian based apt management system.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Interface: `3142/acng-report.html`
    
    :material-information-outline: Configuration path: `/etc/apt-cacher-ng`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/apt-cacher-ng.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/apt-cacher-ng.sh)"
        ```

    === "apt"

        ```shell
        apt install apt-cacher-ng
        ```

## :gear: Config

!!! warning

    For some reason, apt-cacher-ng doesn't work when the `acng.conf` file is symlinked to the repo directly
    and so the config file needs to be manually synced.

!!! abstract "/etc/apt-cacher-ng/acng.conf"

    === "Manual"

        ```ini
        CacheDir: /mnt/storage/aptcache
        ```

!!! code "/mnt/storage/aptcache"

    ```shell
    (
      chown -R apt-cacher-ng:apt-cacher-ng /mnt/storage/aptcache
      systemctl restart apt-cacher-ng.service
      systemctl status apt-cacher-ng.service
      journalctl -xeu apt-cacher-ng.service
    )
    ```

    ```
    http://aptcache.l.nicholaswilde.io:3142/acng-report.html
    ```

## :material-laptop: Client

!!! abstract "/etc/apt/apt.conf.d/00aptproxy"

    === "Automated"

        ```shell
        (
          echo 'Acquire::http::Proxy "http://aptcache.l.nicholaswilde.io:3142";' | tee /etc/apt/apt.conf.d/00aptproxy && \
          apt update
        )
        ```
    === "Manual"

        ```ini
        Acquire::http::Proxy "http://192.168.2.40:3142";
        ```
## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/aptcache.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/aptcache.yaml"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=apt-cacher-ng>
- <https://pimox-scripts.com/scripts?id=Apt-Cacher-NG>

[1]: <https://www.unix-ag.uni-kl.de/~bloch/acng/>
