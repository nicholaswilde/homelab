---
tags:
  - lxc
  - vm
  - proxmox
---
# ![filebrowser](https://cdn.jsdelivr.net/gh/selfhst/icons/svg/file-browser.svg){ width="32" } File Browser

[File Browser][1] is a web file browser.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8080`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/ct/filebrowser.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(curl -sL https://github.com/asylumexp/Proxmox/raw/main/ct/filebrowser.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/filebrowser.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/filebrowser.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "filebrowser/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=filebrowser>
- <https://pimox-scripts.com/scripts?id=filebrowser>

[1]: <https://filebrowser.org/>