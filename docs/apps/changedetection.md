---
tags:
  - lxc
  - proxmox
---
# ![title](https://raw.githubusercontent.com/selfhst/icons/400886b4f5cd552ef373e4550cb0be7344402cce/svg/changedetection.svg){ width="32" } Change Detection

[Change Detection][1] is used to monitor websites and send notifications for when the websites have changed. I typically use this to be notified of when a new release of an OS image is released.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `5000`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/changedetection.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/changedetection.sh)"
        ```

## :gear: Config

!!! code ""

    ```shell
    apt install apprise
    ```

!!! success "Test"

    ```shell
    apprise -vv -t 'my title' -b 'my notification body' 'mailto://email:passkey@gmail.com'
    ```

!!! abstract "Notification URL List"

    ```shell
    mailto://email:passkey@gmail.com
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/changedetection.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/changedetection.yaml"
    ```

## :rocket: Upgrade

!!! code ""

    ```shell
    (
      echo 'bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/changedetection.sh)"' | tee -a ~/.bash_aliases && \
      source ~/.bashrc && \
      update
    )
    ```


## :link: References

- <https://github.com/caronc/apprise>
- <https://pimox-scripts.com/scripts?id=Change+Detection>
- <https://community-scripts.github.io/ProxmoxVE/scripts?id=changedetection>

[1]: <https://changedetection.io/>
