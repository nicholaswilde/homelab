---
tags:
  - lxc
  - vm
  - proxmox
  - docker
---
# ![shlink](https://cdn.jsdelivr.net/gh/selfhst/icons/svg/shlink.svg){ width="32" } Shlink

[Shlink][3] is used as an internal URL shortener.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8081`

!!! code "`homelab/docker/shlink`"

    === "Task"
    
        ```shell
        task up
        ```

    === "Docker Compose"
    
        ```shell
        docker compose up
        ```

## :gear: Config

Create an account at [GeoLite2][1] and generate a [license key][2].

!!! abstract "`homelab/docker/shlink/.env`"

    ```ini
    --8<-- "shlink/.env.tmpl"
    ```

I am running both the server and the optional web client.

The https://app.shlink.io/ also may be used.

The application runs 100% in the browser, so you can safely access any Shlink server from there.

??? abstract "`homelab/docker/shlink/compose.yaml`"

    ```yaml
    --8<-- "shlink/compose.yaml"
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/shlink.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/shlink.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "shlink/task-list.txt"
    ```

## :link: References

[1]: <https://www.maxmind.com/en/geolite2/signup>
[2]: <https://www.maxmind.com/en/accounts/current/license-key>
[3]: <https://shlink.io/>
