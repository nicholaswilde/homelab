---
tags:
  - lxc
  - proxmox
---
# :simple-speedtest: DNS Speed Test

[DNS Speed Test][1] (DoHSpeedTest) is used to test the speed of DNS resolvers,
including DoH (DNS over HTTPS).

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `80`

!!! code ""

    === "Docker"

        ```shell
        docker run -d --name dohspeedtest -p 80:80 brainichq/dohspeedtest:latest
        ```

## :gear: Config

Make symlinks to repo.

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/dnsspeedtest.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/dnsspeedtest.yaml"
    ```

## :link: References

[1]: <https://github.com/BrainicHQ/DoHSpeedTest>
