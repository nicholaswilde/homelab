---
tags:
  - lxc
  - vm
  - proxmox
  - docker
---
# Pinchflat

[Pinchflat][1] is a self-hosted app for downloading YouTube content built using [`yt-dlp`][2].

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: 8383

    :material-information-outline: Configuration path: 

!!! code "`homelab/docker/pinchflat`"

    === "Task"

        ```shell
        task up
        ```

    === "Docker Compose"

        ```shell
        docker compose up
        ```

## :gear: Config

!!! abstract "`homelab/docker/pinchflat/.env`"

    ```ini
    --8<-- "pinchflat/.env.tmpl"
    ```

??? abstract "`homelab/docker/pinchflat/compose.yaml`"

    ```yaml
    --8<-- "pinchflat/compose.yaml"
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/pinchflat.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/pinchflat.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "pinchflat/task-list.txt"
    ```

## :link: References

[1]: <https://github.com/kieraneglin/pinchflat>
[2]: <>
