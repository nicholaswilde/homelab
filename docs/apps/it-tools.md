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

!!! quote ""

    === "Docker"

        ```shell
        docker run -d --name it-tools --restart unless-stopped -p 8080:80 ghcr.io/corentinth/it-tools:latest
        ```

## :gear: Config

Make symlinks to repo.

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=alpine-it-tools>
