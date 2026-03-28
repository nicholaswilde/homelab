---
tags:
  - lxc
  - proxmox
---
# :simple-gatus: Gatus

[Gatus][1] is a service health dashboard.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8080`

    :material-information-outline: Configuration path: `/opt/gatus`

!!! code "`homelab/lxc/gatus`"

    === "Task"
    
        ```shell
        task update
        ```

    === "Manual"
    
        ```shell
        ./update.sh
        ```

## :gear: Config

!!! abstract "`homelab/lxc/gatus/.env`"

    ```ini
    --8<-- "gatus/.env.tmpl"
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/gatus.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/gatus.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "gatus/task-list.txt"
    ```

## :link: References

- <https://gatus.io/>

[1]: <https://github.com/TwiN/gatus>
