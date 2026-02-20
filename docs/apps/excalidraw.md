---
tags:
  - lxc
  - proxmox
  - docker
---
# :simple-excalidraw: Excalidraw

[Excalidraw][1] is used as a whiteboard to sketch ideas.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `5000`

!!! code "`homelab/docker/excalidraw`"

    === "Task"
    
        ```shell
        task up
        ```

    === "Docker Compose"
    
        ```shell
        docker compose up
        ```

## :gear: Config

!!! abstract "`homelab/docker/excalidraw/.env`"

    ```ini
    --8<-- "excalidraw/.env.tmpl"
    ```

??? abstract "`homelab/docker/excalidraw/compose.yaml`"

    ```yaml
    --8<-- "excalidraw/compose.yaml"
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/excalidraw.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/excalidraw.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "excalidraw/task-list.txt"
    ```

## :link: References

[1]: <https://github.com/excalidraw/excalidraw>