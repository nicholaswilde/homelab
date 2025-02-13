---
tags:
  - proxmox
  - lxc
---
# :simple-traefikproxy: Traefik

[Traefik][1] is used as my reverse proxy.

## :gear: Config

!!! note

    Paths in config file should be absolute.

### :handshake: Service

!!! abstract "/etc/systemd/system/traefik.service"

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

    ```shell
    (
     systemctl enable traefik.service && \
     systemctl start traefik.service && \
     systemctl status traefik.service
    ) 
    ```

## :file_folder: Logs

!!! quote ""

    ```shell
    tail -n10 /var/log/traefik/traefik.log
    ```

## :pencil: Usage

WIP

[1]: <https://traefik.io/traefik/>
