---
tags:
  - lxc
  - proxmox
  - docker
---
# ![cyberkeygen](https://raw.githubusercontent.com/karthik558/CyberKeyGen/refs/heads/main/public/favicon.png){ width="32" } CyberKeyGen

[CyberKeyGen][1] is used as a simple password generator.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8080`

    :material-information-outline: Configuration path: `/opt/cyberkeygen`

For this installation of CyberKeyGen, the LXC is used to both build and serve the static site. The reason for this to
make it easier to build and deploy the site after an update.

[`npm`][2] and [`vite`][3] are used to build the site and an [nginx][4] Docker container is used to serve the site.

!!! code ""

    ```shell
    (
      apt install npm
      git clone https://github.com/karthik558/CyberKeyGen.git /opt/cyberkeygen
      npm install --prefix /opt/cyberkeygen -D vite
      npm run --prefix /opt/cyberkeygen build
      docker run -it --rm -d -p 8080:80 --name web -v /opt/cyberkeygen/dist:/usr/share/nginx/html nginx
    )
    ```

## :gear: Config

!!! abstract "`homelab/docker/cyberkeygen/.env`"

    ```ini
    --8<-- "cyberkeygen/.env.tmpl"
    ```

??? abstract "`homelab/docker/cyberkeygen/compose.yaml`"

    ```yaml
    --8<-- "cyberkeygen/compose.yaml"
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/cyberkeygen.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/cyberkeygen.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "cyberkeygen/task-list.txt"
    ```

## :link: References

- <https://github.com/karthik558/CyberKeyGen>

[1]: <https://github.com/karthik558/CyberKeyGen>
[2]: <https://www.npmjs.com/>
[3]: <https://vite.dev/>
[4]: <https://hub.docker.com/_/nginx>
