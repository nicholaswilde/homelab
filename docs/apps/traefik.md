---
tags:
  - proxmox
  - lxc
---
# :simple-traefikproxy: Traefik

[Traefik][1] is used as my reverse proxy.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `80`

!!! quote ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/traefik.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/{{ app_name | lower }}.sh)"
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/traefik.sh)"
        ```

## :gear: Config

!!! note

    Paths in config file should be absolute.

### :handshake: Service

!!! abstract "`/etc/systemd/system/traefik.service`"

    === "Automatic"

        ```shell
        cat > /etc/systemd/system/ventoy.service <<EOF
        --8<-- "traefik/traefik.service"
        EOF
        ```

    === "Download"

        ```shell
        wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/traefik/traefik.service -O /etc/systemd/system/traefik.service
        ```
        
    === "Manual"

        ```ini
        --8<-- "traefik/traefik.service"
        ```
    
!!! quote "Enable service"

    === "Manual"
    
        ```shell
        (
         systemctl enable traefik.service && \
         systemctl start traefik.service && \
         systemctl status traefik.service
        ) 
        ```

## :pencil: Usage

WIP

## :file_folder: Logs

!!! quote "`/var/log/traefik/traefik.log`"

    === "Task"

        ```shell
        task logs
        ```
        
    === "Manual"
    
        ```shell
        tail -n10 /var/log/traefik/traefik.log
        ```

[1]: <https://traefik.io/traefik/>
