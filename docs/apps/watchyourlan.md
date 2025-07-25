---
tags:
  - lxc
  - vm
  - proxmox
---
# ![watchyourland](https://cdn.jsdelivr.net/gh/selfhst/icons/png/watchyourlan.png){ width="32"} WatchYourLAN

[WatchYourLAN][1] is used to monitor IP addresses on my network rather than logging into Unifi.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8840`

    :material-information-outline: Configuration path: `/etc/watchyourlan`
    
!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/watchyourlan.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/watchyourlan.sh)"
        ```

## :gear: Config

!!! abstract "/etc/watchyourlan/config_v2.yaml"

    === "Symbolic Link"

        ```shell
        ln -s /root/git/nicholaswilde/homelab/pve/watchyourlan/config_v2.yaml /etc/watchyourlan/config_v2.yaml
        ```
        
    === "Automatic"

        ```yaml
        cat > /etc/watchyourlan/config_v2.yaml <<EOF
        --8<-- "watchyourlan/config_v2.yaml"
        EOF
        ```

    === "Download"

        ```shell
        wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/watchyourlan/config_v2.yaml -O /etc/watchyourlan/config_v2.yaml
        ```
        
    === "Manual"
    
        ```yaml
        --8<-- "watchyourlan/config_v2.yaml"
        ```

!!! abstract "/etc/watchyourlan/scan.db"

    !!! code "Decrypt"

        === "Task"

            ```shell
            task decrypt
            ```
            
        === "SOPS"

            ```shell
            sops -d scan.db.enc > scan.db
            ```

    !!! code "Encrypt"

        === "Task"
    
            ```shell
            task encrypt
            ```
                
        === "SOPS"
            
            ```shell
            sops -e scan.db > scan.db.enc
            ```

    !!! code "Symbolic Link"

        ```shell
        ln -s /root/git/nicholaswilde/homelab/pve/watchyourlan/scan.db /etc/watchyourlan/scan.db
        ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/watchyourlan.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/watchyourlan.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "watchyourlan/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=watchyourlan>
- <https://pimox-scripts.com/scripts?id=watchyourlan>

[1]: <https://github.com/aceberg/WatchYourLAN>
