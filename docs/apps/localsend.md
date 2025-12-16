---
tags:
  - lxc
  - proxmox
---
# :simple-localsend: LocalSend Web App

[LocalSend][1] is a free and open-source cross-platform app that allows you to securely share files and messages with nearby devices over your local network without the need for an internet connection.

I use this as a self-hosted web app to transer files between my Chromebook, or other system that uses a browser.

!!! note

    The current version of the web app is not compatible with the mobile app nor [LocalSend Go][2]

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `80`

WIP

### Caddy

Caddy needs to be installed to run the LXC as a webserver.

WIP

## :gear: Config

WIP

### Caddy

WIP

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/localsend.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/localsend.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "localsend/task-list.txt"
    ```

## :link: References

- <https://github.com/localsend/web>

[1]: <https://github.com/localsend/web>
[2]: <../tools/localsend-go.md>
