---
tags:
  - lxc
  - vm
  - proxmox
  - docker
---
# :computer: cheat.sh

[cheat.sh][1] is used as a set of cheat sheets that can be accessed via the command line.

The hopes is to be able to add my own commands that I can reference in the cheat sheets without having to contribute to
the community repos.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8002`

    :material-information-outline: Configuration path: `homelab/docker/cheatsh/etc/config.yml`
    
!!! code "`homelab/docker/cheatsh`"

    === "Task"
    
        ```shell
        task up
        ```

    === "Docker Compose"
    
        ```shell
        docker compose up
        ```

## :gear: Config

!!! abstract "`homelab/docker/cheatsh/.env`"

    ```ini
    --8<-- "cheatsh/.env.tmpl"
    ```

??? abstract "`homelab/docker/cheatsh/compose.yaml`"

    ```yaml
    --8<-- "cheatsh/compose.yaml"
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/cheatsh.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/cheatsh.yaml"
    ```

## :pencil: Usage

!!! code ""

    ```shell
    curl localhost:8002/ssh
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "cheatsh/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=cheatsh>
- <https://pimox-scripts.com/scripts?id=cheatsh>

[1]: <https://github.com/chubin/cheat.sh>
