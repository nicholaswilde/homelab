---
tags:
  - lxc
  - proxmox
  - docker
---
# ![netboot.xyz](https://raw.githubusercontent.com/selfhst/icons/refs/heads/main/png/netboot-xyz-light.png){ width="32" } netboot.xyz

[netboot.xyz][1] enables me to boot into many types of operating
systems using lightweight tooling to get you up and running as soon as possible 
over my network.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `3000`

!!! code "`homelab/docker/netbootxyz`"

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

[1]: <https://netboot.xyz/>
