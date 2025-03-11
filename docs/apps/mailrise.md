---
tags:
  - lxc
  - proxmox
  - docker
---
# ![mailrise](https://raw.githubusercontent.com/YoRyan/mailrise/refs/heads/main/src/mailrise/asset/mailrise-info-128x128.png){ width="32" } mailrise

[mailrise][1] An SMTP gateway for Apprise notifications.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8025`

!!! code "`homelab/docker/mailrise`"

    === "Task"
    
        ```shell
        task up
        ```

    === "Docker Compose"
    
        ```shell
        docker compose up
        ```

## :gear: Config

!!! abstract "`homelab/docker/mailrise/.env`"

    ```ini
    --8<-- "mailrise/.env.tmpl"
    ```

??? abstract "`homelab/docker/mailrise/compose.yaml`"

    ```yaml
    --8<-- "mailrise/compose.yaml"
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/mailrise.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/mailrise.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "mailrise/task-list.txt"
    ```

## :link: References

- <https://hub.docker.com/r/yoryan/mailrise>

[1]: <https://github.com/YoRyan/mailrise>
