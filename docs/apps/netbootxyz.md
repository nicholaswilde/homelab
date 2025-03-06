---
tags:
  - lxc
  - vm
  - proxmox
  - docker
---
# :simple-netbootxyz: netboot.xyz

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `3000`

!!! quote "`homelab/docker/netbootxyz`"

    === "Task"
    
        ```shell
        task up
        ```

    === "Docker Compose"
    
        ```shell
        docker compose up
        ```

## :gear: Config

!!! abstract "`homelab/docker/netbootxyz/.env`"

    ```ini
    --8<-- "netbootxyz/.env.tmpl"
    ```

??? abstract "`homelab/docker/netbootxyz/compose.yaml`"

    ```yaml
    --8<-- "netbootxyz/compose.yaml"
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/netbootxyz.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/netbootxyz.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "netbootxyz/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=netbootxyz>
- <https://pimox-scripts.com/scripts?id=netbootxyz>
