---
tags:
  - lxc
  - proxmox
---
# :simple-homepage: homepage

[homepage][1] is my landing 🛬 page for my most frequented sites as well as my internal web pages.

I don't show service statistics to keep things a bit cleaner and simple.

I make this my 🏠 button as well as my new tab in Chrome so that it launches every time I launch Chrome, open a new tab, or click the home 🏠 button. I use the [New Tab Redirect][2] extension to redirect my new tab to homepage.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `3000`
    
    :material-information-outline: Configuration (bookmarks.yaml, services.yaml, widgets.yaml) path: `/opt/homepage/config/`

!!! quote ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/homepage.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/homepage.sh)"
        ```

## :gear: Config

### :link: Symlinks

!!! abstract "`/opt/homepage/config/`"

    === "Task"

        ```shell
        task mklinks
        ```
        
    === "Manual"

        ```shell
        (
          ln -s /root/git/nicholaswilde/homelab/pve/homepage/config/bookmarks.yaml /opt/homepage/config/
          ln -s /root/git/nicholaswilde/homelab/pve/homepage/config/custom.css /opt/homepage/config/
          ln -s /root/git/nicholaswilde/homelab/pve/homepage/config/custom.js /opt/homepage/config/
          ln -s /root/git/nicholaswilde/homelab/pve/homepage/config/docker.yaml /opt/homepage/config/
          ln -s /root/git/nicholaswilde/homelab/pve/homepage/config/kubernetes.yaml /opt/homepage/config/
          ln -s /root/git/nicholaswilde/homelab/pve/homepage/config/services.yaml /opt/homepage/config/
          ln -s /root/git/nicholaswilde/homelab/pve/homepage/config/settings.yaml /opt/homepage/config/
          ln -s /root/git/nicholaswilde/homelab/pve/homepage/config/widgets.yaml /opt/homepage/config/
          ls /opt/homepage/config/
        )
        ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/homepage.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/homepage.yaml"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=homepage>
- <https://pimox-scripts.com/scripts?id=Homepage>

[1]: <https://gethomepage.dev/>
[2]: <https://chromewebstore.google.com/detail/new-tab-redirect/icpgjfneehieebagbmdbhnlpiopdcmna>
