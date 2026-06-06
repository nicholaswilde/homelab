---
tags:
  - lxc
  - proxmox
---
# TapMap

[TapMap][1] is a network connection visualizer daemon that plots active network connections on a 3D world map in real-time.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8050`

    :material-information-outline: Binary path: `/opt/tapmap/tapmap`

TapMap is built from source for both `amd64` and `arm64` via Docker + PyInstaller using our reprepro builder, and installed as a `.deb` package from our local [reprepro][2] repository.

!!! code ""

    === "Debian/Ubuntu"

        ```shell
        apt update
        apt install tapmap
        ```

## :gear: Config

### :material-sync: Stow Symlinks

Configure the environment file by decrypting secrets and symlinking the `.env` using Stow.

!!! code ""

    === "Decrypt Secrets"

        ```shell
        task decrypt
        ```

    === "Symlink .env"

        ```shell
        task stow
        ```

!!! abstract "`homelab/lxc/tapmap/.env.tmpl`"

    ```ini
    --8<-- "tapmap/.env.tmpl"
    ```

### :globe_with_meridians: GeoLite2 Database Setup

TapMap uses the MaxMind GeoLite2 databases to map IP addresses to physical coordinates.

!!! code ""

    === "Setup & Configure"

        ```shell
        task geolite2:setup
        ```

    === "Manual Database Update"

        ```shell
        task geolite2:update
        ```

### :gears: Systemd Service

!!! abstract "/etc/systemd/system/tapmap.service"

    ```ini
    --8<-- "tapmap/tapmap.service"
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/tapmap.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/tapmap.yaml"
    ```

## :rocket: Upgrade

To upgrade the application, you can pull the latest changes and run the update script, or use the webhook service.

!!! code ""

    === "Task"

        ```shell
        task upgrade
        ```

    === "Manual"

        ```shell
        ./update.sh
        ```

### :material-webhook: Webhook Service

TapMap includes a webhook listener service to trigger updates automatically.

!!! code ""

    === "Install"

        ```shell
        task wh:install
        ```

    === "Check Status"

        ```shell
        task wh:status
        ```

    === "View Logs"

        ```shell
        task wh:logs
        ```

    === "Test Webhook"

        ```shell
        task wh:test
        ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "tapmap/task-list.txt"
    ```

## :link: References

- [TapMap GitHub Repository][1]
- [Local Reprepro Repository][2]

[1]: <https://github.com/olalie/tapmap>
[2]: <./reprepro.md>
