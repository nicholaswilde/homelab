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

### App

!!! tip

    Use the `staging` value of `caServer` during testing.

??? abstract "`homelab/pve/traefik/traefik.yaml`"

    ```yaml linenums="1" hl_lines="31-32"
    --8<-- "traefik/traefik.yaml"
    ```

??? abstract "`homelab/pve/traefik/conf.d/config.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/config.yaml"
    ```

### :handshake: Service

Update `EnvironmentFile` and `ExecStart` to point to your homelab directories.

!!! abstract "`/etc/systemd/system/traefik.service`"

    === "Automatic"

        ```shell hl_lines="7-8"
        cat > /etc/systemd/system/traefik.service <<EOF
        --8<-- "traefik/traefik.service"
        EOF
        ```

    === "Download"

        ```shell
        wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/traefik/traefik.service -O /etc/systemd/system/traefik.service
        ```
        
    === "Manual"

        ```ini hl_lines="6-7"
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

## :pencil: Usage

1. Create new config for app

    !!! code "`homelab/pve/traefik/conf.d/`"

        === "Task"

            ```shell
            APP_NAME=AppName task new > appname.yaml
            ```

        === "Manual"

            ```shell
            jinja2 -D APP_NAME=AppName .template.yaml.j2 > appname.yaml
            ```

2. Edit config file.

    Update `http.routers.<app_name>.rule` and `services.<app_name>.loadBalancer.servers.url[0]`
    
    ??? abstract "homelab/pve/traefik/conf.d/mcp-server.yaml"

        ```yaml hl_lines="8 20"
        --8<-- "traefik/conf.d/mcp-server.yaml"
        ```

3. Restart traefik

    !!! code "`homelab/pve/traefik/conf.d/`"

        === "Task"

            ```shell
            task restart
            ```

        === "Manual"

            ```shell
            systemctl restart traefik.service
            ```
4. Test URL in browser.

5. Comment out middleware in config file.

    ??? abstract "homelab/pve/traefik/conf.d/mcp-server.yaml"
    
        ```yaml hl_lines="23-52"
        ---
        http:
         #region routers 
          routers:
            mcp-server:
              entryPoints:
                - "websecure"
              rule: "Host(`mcp-server.l.nicholaswilde.io`)"
              middlewares:
                - default-headers@file
                - https-redirectscheme@file
              tls: {}
              service: mcp-server
        #endregion
        #region services
          services:
            mcp-server:
              loadBalancer:
                servers:
                  - url: "http://192.168.2.177:8080"
                passHostHeader: true
        #endregion
          # middlewares:
            # https-redirectscheme:
              # redirectScheme:
                # scheme: https
                # permanent: true
            # default-headers:
              # headers:
                # frameDeny: true
                # browserXssFilter: true
                # contentTypeNosniff: true
                # forceSTSHeader: true
                # stsIncludeSubdomains: true
                # stsPreload: true
                # stsSeconds: 15552000
                # customFrameOptionsValue: SAMEORIGIN
                # customRequestHeaders:
                  # X-Forwarded-Proto: https
        #
            # default-whitelist:
              # ipAllowList:
                # sourceRange:
                # - "10.0.0.0/8"
                # - "192.168.0.0/16"
                # - "172.16.0.0/12"
        #
            # secured:
              # chain:
                # middlewares:
                # - default-whitelist
                # - default-headers
        ```

6. Restart traefik

7. Test URL

8. Remove middleware or uncomment middleware

    ??? abstract "homelab/pve/traefik/conf.d/mcp-server.yaml"

        ```yaml
        ---
        http:
         #region routers 
          routers:
            mcp-server:
              entryPoints:
                - "websecure"
              rule: "Host(`mcp-server.l.nicholaswilde.io`)"
              middlewares:
                - default-headers@file
                - https-redirectscheme@file
              tls: {}
              service: mcp-server
        #endregion
        #region services
          services:
            mcp-server:
              loadBalancer:
                servers:
                  - url: "http://192.168.2.177:8080"
                passHostHeader: true
        #endregion
        ```

9. Restart traefik

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

### Follow

!!! code "`/var/log/traefik/traefik.log`"

    === "Task"

        ```shell
        task watch
        ```
        
    === "Manual"
    
        ```shell
        tail -f /var/log/traefik/traefik.log
        ```


## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "traefik/task-list.txt"
    ```

## :link: References

[1]: <https://traefik.io/traefik/>
