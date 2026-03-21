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

!!! code "`homelab/docker/homebox`"

    === "Task"
    
        ```shell
        task up
        ```

    === "Docker Compose"
    
        ```shell
        docker compose up
        ```

## :gear: Config

!!! abstract "`homelab/docker/homebox/.env`"

    ```ini
    --8<-- "homebox/.env.tmpl"
    ```

??? abstract "`homelab/docker/homebox/compose.yaml`"

    ```yaml
    --8<-- "homebox/compose.yaml"
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