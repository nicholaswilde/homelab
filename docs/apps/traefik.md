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

!!! code ""

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

All internal URLs use an `l` sub domain so that only one certificate is needed from letsencrypt. E.g. `https://app.l.nicholaswilde.io/`

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
    
!!! code "Enable service"

    === "Manual"
    
        ```shell
        (
         systemctl enable traefik.service && \
         systemctl start traefik.service && \
         systemctl status traefik.service
        ) 
        ```

??? abstract "`homelab/pve/traefik/traefik.yaml`"

    ```yaml
    --8<-- "traefik/traefik.yaml"
    ```

??? abstract "`homelab/pve/traefik/conf.d/config.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/config.yaml"
    ```

## :pencil: Usage

**Create new config for app**

!!! code "`homelab/pve/traefik/conf.d/`"

    === "Task"

        ```shell
        APP_NAME=AppName task new > appname.yaml
        ```

    === "Manual"

        ```shell
        jinja2 -D APP_NAME=AppName .template.yaml.j2 > appname.yaml
        ```

**Edit config file**

**Restart traefik**

!!! code "`homelab/pve/traefik/conf.d/`"

    === "Task"

        ```shell
        task restart
        ```

    === "Manual"

        ```shell
        systemctl restart traefik.service
        ```
**Test URL**

**Comment out middleware in config file**

**Restart traefik**

**Test URL**

**Remove middleware or uncomment middleware**

**Restart traefik**

## :file_folder: Logs

!!! code "`/var/log/traefik/traefik.log`"

    === "Task"

        ```shell
        task logs
        ```
        
    === "Manual"
    
        ```shell
        tail -n10 /var/log/traefik/traefik.log
        ```

[1]: <https://traefik.io/traefik/>
