---
tags:
  - lxc
  - proxmox
---
# :simple-authentik: authentik

[authentik][1] is used as a single sign on provider. This is so I don't have different logins for
different applications.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `9000`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/ct/authentik.sh)"
        ```

## :gear: Config

WIP

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "authentik/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=authentik>

[1]: <https://goauthentik.io/>