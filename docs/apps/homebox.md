---
tags:
  - lxc
  - vm
  - proxmox
  - docker
---
# :simple-homebox: Homebox

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `7745`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/ct/homebox.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(curl -sL https://github.com/asylumexp/Proxmox/raw/main/ct/homebox.sh)"
        ```

## :gear: Config

!!! abstract "`homelab/lxc/homebox/.env`"

    ```ini
    --8<-- "homebox/.env.tmpl"
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/homebox.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/homebox.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "homebox/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=homebox>
- <https://pimox-scripts.com/scripts?id=homebox>