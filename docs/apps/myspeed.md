---
tags:
  - lxc
  - proxmox
---
# :simple-speedtest: MySpeed

[MySpeed][1] is used to test internet download and upload speeds.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `5216`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/myspeed.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/myspeed.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/myspeed.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/myspeed.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "myspeed/task-list.txt"
    ```

## :link: References

[1]: <https://myspeed.dev/>
