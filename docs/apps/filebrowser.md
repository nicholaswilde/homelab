---
tags:
  - lxc
  - vm
  - proxmox
---
# :simple-file browser: File Browser

[File Browser][1] is a web file browser.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8080`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/filebrowser.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/filebrowser.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "file browser/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=filebrowser>
- <https://pimox-scripts.com/scripts?id=filebrowser>

[1]: <https://filebrowser.org/>
