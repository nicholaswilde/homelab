---
tags:
  - lxc
  - proxmox
---
# :simple-prometheus: Prometheus

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `9090`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/prometheus.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/prometheus.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/prometheus.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/prometheus.yaml"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=prometheus>
- <https://pimox-scripts.com/scripts?id=Prometheus>
