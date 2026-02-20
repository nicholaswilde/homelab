---
tags:
  - lxc
  - proxmox
---
# ![patchmon](https://cdn.jsdelivr.net/gh/selfhst/icons/png/patchmon.png){ width="32" } PatchMon

[PatchMon][1] is a web-based application designed to monitor and manage software patches and updates across multiple systems.

## :hammer_and_wrench: Installation

The application is installed by cloning the GitHub repository and running a series of `npm` commands to build the frontend and backend. The `update.sh` script handles the installation of a new version.

!!! example ""

    :material-console-network: Default Port: `3399`
    
    :material-information-outline: Installation path: `/opt/patchmon`

## :gear: Config

Configuration for PatchMon is managed through `.env` files for both the frontend and backend, and a `patchmon.creds` file for credentials.

!!! abstract "pve/patchmon/.env.tmpl"

    ```ini
    --8<-- "patchmon/.env.tmpl"
    ```

### :handshake: Service

PatchMon runs as a `systemd` service.

!!! abstract "pve/patchmon/patchmon-server.service"

    ```ini
    --8<-- "patchmon/patchmon-server.service"
    ```

To install the service, you can use the `service:install` task.

!!! code "Install Service"

    === "Task"

        ```shell
        task service:install
        ```

    === "Manual"

        ```shell
        sudo cp ./patchmon-server.service /etc/systemd/system/
        sudo systemctl enable --now patchmon-server.service
        ```

### :wrench: Settings

The `update-settings.js` script is used to configure the database settings for PatchMon.

!!! abstract "pve/patchmon/update-settings.js"

    ```javascript
    --8<-- "patchmon/update-settings.js"
    ```

This can be run using the `settings:install` task.

!!! code "Update Settings"

    === "Task"

        ```shell
        task settings:install
        ```

    === "Manual"

        ```shell
        sudo cp ./update-settings.js /opt/patchmon/backend/update-settings.js
        node /opt/patchmon/backend/update-settings.js
        ```

## :rocket: Upgrade

The `update.sh` script automates the process of downloading and installing the latest version of PatchMon. It checks for the latest release on GitHub, backs up existing configuration, downloads the new version, builds it, and restarts the service.

!!! code "Upgrade"

    === "Task"

        ```shell
        task update
        ```

    === "Manual"

        ```shell
        sudo ./update.sh
        ```

??? abstract "pve/patchmon/update.sh"

    ```bash
    --8<-- "patchmon/update.sh"
    ```

## :floppy_disk: Backup

The `backup.sh` script is used to back up the Redis database. It triggers a `BGSAVE`, waits for it to complete, and then encrypts the dump file using `sops`.

!!! code "Backup"

    === "Task"

        ```shell
        task backup
        ```

    === "Manual"

        ```shell
        sudo ./backup.sh
        ```

??? abstract "pve/patchmon/backup.sh"

    ```bash
    --8<-- "patchmon/backup.sh"
    ```
## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/patchmon.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/patchmon.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "patchmon/task-list.txt"
    ```

## :link: References

- <https://github.com/PatchMon/PatchMon>

[1]: <https://github.com/PatchMon/PatchMon>