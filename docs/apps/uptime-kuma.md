---
tags:
  - bare-metal
  - docker
---
# :simple-uptimekuma: Uptime Kuma

[Uptime Kuma][1] is used to monitor the uptime of my devices.

## :gear: Config

!!! example ""

    :material-console-network: Default Port: `3001`

## :key: Auth

Disable authentication.

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/uptimekuma.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/uptimekuma.yaml"
    ```

## :link: References

[1]: <https://uptime.kuma.pet/>
