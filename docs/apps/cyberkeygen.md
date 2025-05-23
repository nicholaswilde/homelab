---
tags:
  - lxc
  - proxmox
---
# ![cyberkeygen](https://raw.githubusercontent.com/karthik558/CyberKeyGen/refs/heads/main/public/favicon.png){ width="32" } CyberKeyGen

[CyberKeyGen][1] is used as a simple password generator.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8080`

    :material-information-outline: Configuration path: `/opt/cyberkeygen`

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

WIP

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "cyberkeygen/task-list.txt"
    ```

## :link: References

- <https://github.com/karthik558/CyberKeyGen>

[1]: <https://github.com/karthik558/CyberKeyGen>
