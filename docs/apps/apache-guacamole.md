---
tags:
  - lxc
  - proxmox
---
# :simple-apacheguacamole: Apache Guacamole

[Apache Guacamole][1] is used to remote into GUI based systems, such as [Windows 11][2]

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8080`

    :material-link: Url: `http://ip-address:8080/guacamole`

    :material-information-outline: Configuration path: `/etc/guacamole/guacd.conf`

    :material-account: Default username: `guacadmin`

    :material-key: Default uassword: `guacadmin`
    
!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/ct/apache-guacamole.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(curl -sL https://github.com/asylumexp/Proxmox/raw/main/ct/apache-guacamole.sh)"
        ```

## :gear: Config

### ![windows](https://cdn.jsdelivr.net/gh/selfhst/icons/png/microsoft-windows.png){ width="16" } Windows 11

!!! example "Connections"

    === "Edit Connection"
    
        Name: `w11`

        Location: `Root`

        Protocol: `RDP`

    === "Network"

        Hostname: `192.168.2.154`

        Port: `3389`

    === "Authentication"

        Username: `username`

        Password: `password`

        Domain: `W11`

!!! info

    Domain should match the hostname of the W11 computer.

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/apache-guacamole.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/apache-guacamole.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "apache-guacamole/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=apache-guacamole>
- <https://pimox-scripts.com/scripts?id=apache-guacamole>

[1]: <https://guacamole.apache.org/>
[2]: <./w11.md>
