---
tags:
  - lxc
  - proxmox
---
# :simple-gitea: Gitea

[Gitea][1] is used to have local git repos. I typically use it as a backup (mirror) of my GitHub repos.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `3000`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/gitea.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/gitea.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/gitea.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/gitea.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "gitea/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=homepage>
- <https://pimox-scripts.com/scripts?id=Homepage>

[1]: <https://about.gitea.com/>
