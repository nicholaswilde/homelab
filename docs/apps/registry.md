---
tags:
  - lxc
  - proxmox
  - docker
---
# :simple-docker: Registry 

Registry is a being used as a Docker pull through cache for my network.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `5000`


!!! quote "`homelab/docker/registry`"

    === "Task"
    
        ```shell
        task up
        ```

    === "Docker Compose"
    
        ```shell
        docker compose up
        ```
## :rocket: Upgrade

!!! warning

    The below commands purge any unused Docker images! Use at your own risk!

!!! quote "`homelab/docker/registry`"

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

## :gear: Config

### :desktop_computer: Server

!!! quote "Init .env"

    === "Task"
    
        ```shell
        task init
        ```

    === "Manual"

        ```shell
        cp .env.tmpl .env
        ```

Edit `.env`

!!! abstract "`homelab/docker/registry/compose.yaml`"

    === "Manual"
    
        ```yaml
        --8<-- "registry/compose.yaml"
        ```

### :computer: Client

!!! tip

    `registry-mirrors` must start with `http` or `https` else an error will be thrown when trying to restart the docker service.
    
!!! abstract "`/etc/docker/daemon.json`"

    === "Automatic"

        ```shell
        cat <<EOF > /etc/docker/daemon.json
        --8<-- "registry/daemon.json"
        EOF
        ```
        
    === "Download"

        ```shell
        (
          [ ! -d /etc/docker ] && mkdir -p /etc/docker
          wget https://raw.githubusercontent.com/nicholaswilde/homelab/refs/heads/main/docker/registry/daemon.json -O /etc/docker/daemon.json
        )
        ```

    === "Manual"
    
        ```json
        --8<-- "registry/daemon.json"
        ```

!!! quote "Restart the Docker service"

    ```shell
    (
      systemctl daemon-reload
      systemctl restart docker.service
    )
    ```
## :pencil: Usage

### :computer: Client

WIP

## :link: References

- <https://docs.docker.com/docker-hub/image-library/mirror/>
- <https://youtu.be/Bm7g0saAC9k>
