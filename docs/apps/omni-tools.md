---
tags:
  - lxc
  - vm
  - proxmox
---
# :simple-omni-tools: omni-tools

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `80`


!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/ct/omni-tools.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(curl -sL https://github.com/asylumexp/Proxmox/raw/main/ct/omni-tools.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "omni-tools/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=omni-tools>
- <https://pimox-scripts.com/scripts?id=omni-tools>