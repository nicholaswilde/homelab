---
tags:
  - lxc
  - proxmox
---
# :simple-gitea: Gitea

[Gitea][1] is used to have local git repos. I typically use it as a backup (mirror) of my GitHub repos.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `3000`

    :material-information-outline: Configuration path: `/etc/gitea/`

    :material-information-outline: Custom path: `/var/lib/gitea/custom/`
    
!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/gitea.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/gitea.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## ![catppuuccin](https://raw.githubusercontent.com/catppuccin/website/refs/heads/main/public/favicon.png){ width="32" } [Catppuccin][2]

!!! info

    Gitea 1.20 or newer is required for this theme.

1. Download the [latest GitHub release](https://github.com/catppuccin/gitea/releases/latest).
2. Place the CSS files inside Gitea's configuration directory:
   - Gitea 1.21.0 or newer: `$GITEA_CUSTOM/public/assets/css`
   - Otherwise: `$GITEA_CUSTOM/public/css`
3. Add the themes to your `app.ini`. For further information on customizing Gitea, see the [Gitea documentation][3].
4. Restart your Gitea instance.
5. Select the theme in `Gitea > Account > Settings > Appearance`.

### Flavor-Accent

!!! abstract "`/etc/gitea/app.ini`"

    === "Manual"
    
        ```ini
        [ui]
        THEMES = catppuccin-latte-rosewater,catppuccin-latte-flamingo,catppuccin-latte-pink,catppuccin-latte-mauve,catppuccin-latte-red,catppuccin-latte-maroon,catppuccin-latte-peach,catppuccin-latte-yellow,catppuccin-latte-green,catppuccin-latte-teal,catppuccin-latte-sky,catppuccin-latte-sapphire,catppuccin-latte-blue,catppuccin-latte-lavender,catppuccin-frappe-rosewater,catppuccin-frappe-flamingo,catppuccin-frappe-pink,catppuccin-frappe-mauve,catppuccin-frappe-red,catppuccin-frappe-maroon,catppuccin-frappe-peach,catppuccin-frappe-yellow,catppuccin-frappe-green,catppuccin-frappe-teal,catppuccin-frappe-sky,catppuccin-frappe-sapphire,catppuccin-frappe-blue,catppuccin-frappe-lavender,catppuccin-macchiato-rosewater,catppuccin-macchiato-flamingo,catppuccin-macchiato-pink,catppuccin-macchiato-mauve,catppuccin-macchiato-red,catppuccin-macchiato-maroon,catppuccin-macchiato-peach,catppuccin-macchiato-yellow,catppuccin-macchiato-green,catppuccin-macchiato-teal,catppuccin-macchiato-sky,catppuccin-macchiato-sapphire,catppuccin-macchiato-blue,catppuccin-macchiato-lavender,catppuccin-mocha-rosewater,catppuccin-mocha-flamingo,catppuccin-mocha-pink,catppuccin-mocha-mauve,catppuccin-mocha-red,catppuccin-mocha-maroon,catppuccin-mocha-peach,catppuccin-mocha-yellow,catppuccin-mocha-green,catppuccin-mocha-teal,catppuccin-mocha-sky,catppuccin-mocha-sapphire,catppuccin-mocha-blue,catppuccin-mocha-lavender
        ```

### Auto

This ensures that the theme automatically switches between light (latte) and dark (mocha) mode.

!!! abstract "`/etc/gitea/app.ini`"

    === "Manual"
    
        ```ini
        [ui]
        THEMES = catppuccin-rosewater-auto,catppuccin-flamingo-auto,catppuccin-pink-auto,catppuccin-mauve-auto,catppuccin-red-auto,catppuccin-maroon-auto,catppuccin-peach-auto,catppuccin-yellow-auto,catppuccin-green-auto,catppuccin-teal-auto,catppuccin-sky-auto,catppuccin-sapphire-auto,catppuccin-blue-auto,catppuccin-lavender-auto
        ```

!!! code

    ```shell
    (
      [ -d /var/lib/gitea/custom/public/assets/css ] || mkdir -p /var/lib/gitea/custom/public/assets/css
      wget https://github.com/catppuccin/gitea/releases/latest/download/catppuccin-gitea.tar.gz -O /tmp/catppuccin-gitea.tar.gz && \
      tar -xvf /tmp/catppuccin-gitea.tar.gz -C /var/lib/gitea/custom/public/assets/css && \
      systemctl restart gitea.service
    )
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/gitea.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/gitea.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "gitea/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=homepage>
- <https://pimox-scripts.com/scripts?id=Homepage>

[1]: <https://about.gitea.com/>
[2]: <https://github.com/catppuccin/gitea>
[3]: <https://docs.gitea.com/next/administration/customizing-gitea#customizing-the-look-of-gitea>
