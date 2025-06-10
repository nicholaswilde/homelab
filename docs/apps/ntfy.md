---
tags:
  - lxc
  - notifications
  - proxmox
---
# :simple-ntfy: ntfy

[ntfy][1] is a simple HTTP-based pub-sub notification service. It allows you to send notifications to your phone or desktop via scripts from any computer, and/or using a REST API.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `80`

    :material-information-outline: Configuration path: `/etc/ntfy/`

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

[1]: <https://ntfy.sh/>
