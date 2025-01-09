---
tags:
  - lxc
  - proxmox
---
# :simple-homepage: Homepage

Homepage is my landing 🛬 page for my most frequented sites as well as my internal web pages.

I don't show service statistics to keep things a bit cleaner and simple.

I make this my 🏠 button as well as my new tab in Chrome so that it launches every time I launch Chrome, open a new tab, or click the home 🏠 button. I use the [New Tab Redirect][2] extension to redirect my new tab to Homepage.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `3000`
    
    :material-information-outline: Configuration (bookmarks.yaml, services.yaml, widgets.yaml) path: `/opt/homepage/config/`

=== "AMD64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/homepage.sh)"
    ```

=== "ARM64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/homepage.sh)"
    ```

## :gear: Config

Make symlinks to repo.

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=homepage>
- <https://pimox-scripts.com/scripts?id=Homepage>

[2]: <https://chromewebstore.google.com/detail/new-tab-redirect/icpgjfneehieebagbmdbhnlpiopdcmna>
