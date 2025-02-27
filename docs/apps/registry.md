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

    :material-console-network: Default Port: ``


!!! quote ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/.sh)"
        ```

## :gear: Config

### Server

!!! abstract "/etc/docker/registry/config.yml"

    === "Manual"
    
        ```yaml
        ---
        proxy:
          remoteurl: https://registry-1.docker.io
          username: [username]
          password: [password]
        ```

### :computer: Client

!!! abstract "`/etc/docker/daemon.json`"

    === "Manual"
    
        ```json
        {
          "registry-mirrors": ["https://<my-docker-mirror-host>"]
        }
        ```

Make symlinks to repo.

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=>
- <https://pimox-scripts.com/scripts?id=>
- <https://docs.docker.com/docker-hub/image-library/mirror/>
