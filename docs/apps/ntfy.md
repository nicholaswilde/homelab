---
tags:
  - lxc
  - vm
  - proxmox
---
# :simple-ntfy: ntfy

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `80`


!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/ntfy.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/ntfy.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "ntfy/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=ntfy>
- <https://pimox-scripts.com/scripts?id=ntfy>
