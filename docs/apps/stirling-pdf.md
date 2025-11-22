---
tags:
  - lxc
  - proxmox
---
# ![Stirling PDF](https://cdn.jsdelivr.net/gh/selfhst/icons/webp/stirling-pdf.webp){ width="32" } Stirling PDF

[Stirling PDF][1] is a locally hosted web application that allows you to perform various operations on PDF files.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8080`

    :material-information-outline: Configuration path: `/opt/Stirling-PDF/.env`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/ct/stirling-pdf.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(curl -sL https://github.com/asylumexp/Proxmox/raw/main/ct/stirling-pdf.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "stirling-pdf/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=stirling-pdf>
- <https://pimox-scripts.com/scripts?id=stirling-pdf>

[1]: <https://github.com/Stirling-Tools/Stirling-PDF>
