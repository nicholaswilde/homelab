---
tags:
  - lxc
  - vm
  - proxmox
---
# :simple-withoutbg: withoutbg

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `3000` (Frontend), `8000` (Backend)


!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/ct/withoutbg.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(curl -sL https://github.com/asylumexp/Proxmox/raw/main/ct/withoutbg.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "withoutbg/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=withoutbg>
- <https://pimox-scripts.com/scripts?id=withoutbg>