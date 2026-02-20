---
tags:
  - lxc
  - proxmox
  - docker
---
# ![it-tools](https://github.com/CorentinTh/it-tools/raw/refs/heads/main/public/safari-pinned-tab.svg){ width="32" } IT-TOOLS

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8080`

!!! code ""

    === "Docker"

        ```shell
        docker run -d --name it-tools --restart unless-stopped -p 8080:80 ghcr.io/corentinth/it-tools:latest
        ```

## :gear: Config

Make symlinks to repo.

## :rocket: Upgrade

!!! warning

    The below commands purge any unused Docker images! Use at your own risk!

!!! code "`homelab/docker/it-tools`"

    === "Task"

        ```shell
        task upgrade
        ```
        
    === "Manual"
    
        ```shell
        (
          git pull origin
          docker compose up --force-recreate --build -d
          docker image prune -a -f
        )
        ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/it-tools.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/it-tools.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "it-tools/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=alpine-it-tools>