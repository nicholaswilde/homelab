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
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/ct/apt-cacher-ng.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(curl -sL https://github.com/asylumexp/Proxmox/raw/main/ct/apt-cacher-ng.sh)"
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

## :material-test-tube: Testing

To test the Apt-Cacher NG setup, perform the following steps:

1.  **From a remote host**, use the following command to download a package through the cache:

    !!! code ""

        ```shell
        sudo apt clean && time sudo apt install --download-only --reinstall libreoffice
        ```

2.  **On the ACNG host**, watch the logs to confirm that the package download was cached:

    !!! code ""

        ```shell
        tail -f /var/log/apt-cacher-ng/apt-cacher.log
        ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/aptcache.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/aptcache.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "apt-cacher-ng/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=apt-cacher-ng>
- <https://pimox-scripts.com/scripts?id=Apt-Cacher-NG>

[1]: <https://www.unix-ag.uni-kl.de/~bloch/acng/>
