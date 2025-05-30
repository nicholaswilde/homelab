---
tags:
  - lxc
  - proxmox
---
# :simple-homepage: aria2

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `6880`
    
    :material-information-outline: Within the LXC console, run `cat rpc.secret` to display the rpc-secret. Copy this token and paste it into the Aria2 RPC Secret Token box within the AriaNG Settings. Then, click the reload AriaNG button.

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/aria2.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/aria2.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/aria2.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/aria2.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "aria2/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=aria2>
- <https://pimox-scripts.com/scripts?id=aria2>
