---
tags:
  - vm
  - proxmox
  - docker
---
# :simple-immich: Immich

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `2283`

! warning

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
