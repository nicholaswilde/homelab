---
tags:
  - lxc
  - vm
  - proxmox
---
# :simple-freshrss: FreshRSS

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `80`


!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/ct/freshrss.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(curl -sL https://github.com/asylumexp/Proxmox/raw/main/ct/freshrss.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "freshrss/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=freshrss>
- <https://pimox-scripts.com/scripts?id=FreshRSS>