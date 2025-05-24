---
tags:
  - lxc
  - proxmox
  - docker
---
# ![ConvertX](https://raw.githubusercontent.com/C4illin/ConvertX/refs/heads/main/public/android-chrome-192x192.png){ width="32" } ConvertX

[ConvertX][1] is a self-hosted online file convert. Supports 1000+ formats.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `3000`

!!! code "`homelab/docker/convertx`"

    === "Task"
    
        ```shell
        task up
        ```

    === "Docker Compose"
    
        ```shell
        docker compose up
        ```

## :gear: Config

!!! abstract "`homelab/docker/convertx/.env`"

    ```ini
    --8<-- "convertx/.env.tmpl"
    ```

??? abstract "`homelab/docker/convertx/compose.yaml`"

    ```yaml
    --8<-- "convertx/compose.yaml"
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/convertx.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/convertx.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "convertx/task-list.txt"
    ```

## :link: References

- <https://github.com/C4illin/ConvertX>

[1]: <https://github.com/C4illin/ConvertX>
