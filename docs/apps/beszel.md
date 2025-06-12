---
tags:
  - lxc
  - proxmox
---
# ![beszel](https://github.com/henrygd/beszel/raw/refs/heads/main/beszel/site/public/static/favicon.svg){ width="24" } Beszel

[Beszel][1] is used as a monitoring tool for my homelab.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Hub Port: `8090`

    :material-console-network: Agent Port: `45876`

!!! code ""

    === "hub"

        ```shell
        curl -sL https://raw.githubusercontent.com/henrygd/beszel/main/supplemental/scripts/install-hub.sh -o install-hub.sh && chmod +x install-hub.sh && ./install-hub.sh
        ```

    === "agent"

        ```shell
        curl -sL https://raw.githubusercontent.com/henrygd/beszel/main/supplemental/scripts/install-agent.sh -o  install-agent.sh && chmod +x install-agent.sh && ./install-agent.sh
        ```

## :gear: Config

Make symlinks to repo.

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/beszel.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/beszel.yaml"
    ```

## :bell: Notifications

1. [mailrise][2] via `smtp`.
2. [ntfy][3] via webhook.
3. [Gotify][4] via webhook.

## :pencil: Usage

WIP

## :rocket: Upgrade

!!! code ""

    === "Task"

        ```shell
        task update
        ```
    
    === "Manual"
    
        ```shell
        ./beszel update
        ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "beszel/task-list.txt"
    ```

## :link: References

[1]: <https://beszel.dev/>
[2]: <./mailrise.md>
[3]: <./ntfy.md>
[4]: <./gotify.md>

