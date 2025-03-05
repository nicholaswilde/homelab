---
tags:
  - lxc
  - proxmox
  - docker
---
# :simple-docker: Registry 

[Registry][1] is a being used as a Docker pull through cache for my network.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `5000`

    :material-information-outline: Configuration path: `/etc/docker`

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

    === "Automatic"
    
        ```shell
        cat << EOF > ./docker/registry/compose.yaml
        --8<-- "registry/compose.yaml"
        EOF
        ```
        
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

    === "Task"

        ```shell
        task restart
        ```

    === "Manual"
    
        ```shell
        (
          systemctl daemon-reload
          systemctl restart docker.service
        )
        ```

## :pencil: Usage

### :computer: Client

!!! quote ""

    === "Pull Through"

        ```shell
        docker pull ubuntu
        ```

    === "Secure pull from local"

        ```shell
        docker pull https://registry.l.nicholaswilde.io/library/ubuntu
        ```

    === "Insecure pull from local"

        ```shell
        docker pull 192.168.2.81:5000/library/ubuntu
        ```
WIP

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

## :stethoscope: Troubleshooting

Watch the logs on the server during a pull to ensure that the image is being pulled through the local registry.

!!! quote "`homelab/docker/registry`"

    === "Task"

        ```shell
        task logs
        ```
        
    === "Manual"

        ```shell
        docker logs registry -f
        ```

## :link: References

- <https://docs.docker.com/docker-hub/image-library/mirror/>
- <https://youtu.be/Bm7g0saAC9k>

[1]: <https://hub.docker.com/_/registry>
