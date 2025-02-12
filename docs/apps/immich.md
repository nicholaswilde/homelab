---
tags:
  - vm
  - proxmox
  - docker
---
# :simple-immich: Immich

Immich photos is an open source alternative to Google Photos.

[Immich Go][1] is a command line utility to assist with importing photos to Immich.


## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `2283`

!!! quote "`homelab/docker/immich`"

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

!!! quote "`homelab/docker/immich`"

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

Make symlinks to repo.

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=immich>
- <https://pimox-scripts.com/scripts?id=Immich>

[1]: <./immich-go.md>
