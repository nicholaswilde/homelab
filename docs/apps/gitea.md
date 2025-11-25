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
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/ct/gitea.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(curl -sL https://github.com/asylumexp/Proxmox/raw/main/ct/gitea.sh)"
        ```

## :gear: Config

### ![catppuuccin](https://raw.githubusercontent.com/catppuccin/website/refs/heads/main/public/favicon.png){ width="32" } [Catppuccin][2]

!!! info

    Gitea 1.20 or newer is required for this theme.

1. Download the [latest GitHub release](https://github.com/catppuccin/gitea/releases/latest).
2. Place the CSS files inside Gitea's configuration directory:
   - Gitea 1.21.0 or newer: `$GITEA_CUSTOM/public/assets/css`
   - Otherwise: `$GITEA_CUSTOM/public/css`
3. Add the themes to your `app.ini`. For further information on customizing Gitea, see the [Gitea documentation][3].
4. Restart your Gitea instance.
5. Select the theme in `Gitea > Account > Settings > Appearance`.

#### :art: Flavor-Accent

!!! abstract "`/etc/gitea/app.ini`"

    === "Manual"
    
        ```ini
        [ui]
        THEMES = catppuccin-latte-rosewater,catppuccin-latte-flamingo,catppuccin-latte-pink,catppuccin-latte-mauve,catppuccin-latte-red,catppuccin-latte-maroon,catppuccin-latte-peach,catppuccin-latte-yellow,catppuccin-latte-green,catppuccin-latte-teal,catppuccin-latte-sky,catppuccin-latte-sapphire,catppuccin-latte-blue,catppuccin-latte-lavender,catppuccin-frappe-rosewater,catppuccin-frappe-flamingo,catppuccin-frappe-pink,catppuccin-frappe-mauve,catppuccin-frappe-red,catppuccin-frappe-maroon,catppuccin-frappe-peach,catppuccin-frappe-yellow,catppuccin-frappe-green,catppuccin-frappe-teal,catppuccin-frappe-sky,catppuccin-frappe-sapphire,catppuccin-frappe-blue,catppuccin-frappe-lavender,catppuccin-macchiato-rosewater,catppuccin-macchiato-flamingo,catppuccin-macchiato-pink,catppuccin-macchiato-mauve,catppuccin-macchiato-red,catppuccin-macchiato-maroon,catppuccin-macchiato-peach,catppuccin-macchiato-yellow,catppuccin-macchiato-green,catppuccin-macchiato-teal,catppuccin-macchiato-sky,catppuccin-macchiato-sapphire,catppuccin-macchiato-blue,catppuccin-macchiato-lavender,catppuccin-mocha-rosewater,catppuccin-mocha-flamingo,catppuccin-mocha-pink,catppuccin-mocha-mauve,catppuccin-mocha-red,catppuccin-mocha-maroon,catppuccin-mocha-peach,catppuccin-mocha-yellow,catppuccin-mocha-green,catppuccin-mocha-teal,catppuccin-mocha-sky,catppuccin-mocha-sapphire,catppuccin-mocha-blue,catppuccin-mocha-lavender
        ```

#### :robot: Auto

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
      curl -Lo /tmp/catppuccin-gitea.tar.gz https://github.com/catppuccin/gitea/releases/latest/download/catppuccin-gitea.tar.gz && \
      tar -xvf /tmp/catppuccin-gitea.tar.gz -C /var/lib/gitea/custom/public/assets/css && \
      systemctl restart gitea.service
    )
    ```

### :bell: Email Notifications

Enable email notifications using [mailrise](./mailrise.md).

!!! abstract "/etc/gitea/app.ini"

    ```ini
    [mailer]
    ENABLED        = true
    FROM           = gitea@nicholaswilde.io
    PROTOCOL       = smtp
    SMTP_ADDR      = smtp.l.nicholaswilde.io
    SMTP_PORT      = 8025
    ```

#### :e-mail: Send a test email

1. Open your Git server (Gitea, GitHub, GitLab, etc.) in a web browser.

2. Go to your "Site Administration".

3. Find the "Configuration -> Summary" (or similar) section.

4. Under "Mailer Configuration", enter `email@mailrize.xyz` and click the "Send" button.

### :octicons-terminal-24: SSH Domain

To be able to pull the gitea repo using a domain name rather than an IP address, change the following:

!!! abstract "/etc/gitea/app.ini"

    ```ini
    [server]
    SSH_DOMAIN = gitea-ssh.l.nicholaswilde.io
    DOMAIN = gitea.l.nicholaswilde.io
    HTTP_PORT = 3000
    ROOT_URL = https://gitea.l.nicholaswilde.io/
    APP_DATA_PATH = /var/lib/gitea/data
    DISABLE_SSH = false
    SSH_PORT = 22
    ```

The gitea repo should now show the `SSH_DOMAIN` in the `Code` button under `SSH` in the web GUI.

!!! code ""

    === "SSH"
    
        ```shell
        gitea@gitea-ssh.l.nicholaswilde.io:nicholas/homelab.git
        ```

#### :simple-adguard: AdGuardHome DNS Rewrite

In [AdGuardHome](./adguardhome.md) DNS Rewrites, add an entry that forwards the `SSH_DOMAIN` directly to your gitea LXC.

- Domain: `gitea-ssh.l.nicholaswilde.io`
- Answer: `192.168.2.20`

#### :key: Add Your Remote Machine's Public Key to Your Git Server

Your remote machine needs to be "authorized" to access your Git server. You do this by giving the server your machine's public key.

1. Display the public key on your remote machine and copy it to your clipboard.

!!! code "Remote LXC"

    ```shell
    cat ~/.ssh/id_rsa.pub
    # Or, if you made an ed25519 key:
    cat ~/.ssh/id_ed25519.pub
    ```

   The output will look something like `ssh-ed25519 AAAAC3... your_email@example.com`.

2. Open your Git server (Gitea, GitHub, GitLab, etc.) in a web browser.

3. Go to your user Settings.

4. Find the "SSH / GPG Keys" (or similar) section.

5. Click "Add Key" and paste the public key you just copied.

#### Usage

You can then clone a repo using the hostname rather than the gitea IP address.

!!! code "remote machine"

    ```shell
    git clone gitea@gitea-ssh.l.nicholaswilde.io:nicholas/homelab.git
    ```

## :mag: Configuration Monitoring

The `check-config.sh` script can be used to monitor the Gitea configuration for discrepancies between the live `app.ini` and the encrypted `app.ini.enc`. If a mismatch is found, a Mailrise notification is sent.

### :handshake: Systemd Service

Create `/etc/systemd/system/gitea-check-config.service`:

!!! abstract "/etc/systemd/system/gitea-check-config.service"

    === "Automatic"

        ```shell
        cat <<EOF > /etc/systemd/system/gitea-check-config.service
        [Unit]
        Description=Check Gitea configuration sync status

        [Service]
        Type=oneshot
        User=root
        WorkingDirectory=/root/git/nicholaswilde/homelab/lxc/gitea
        ExecStart=/root/git/nicholaswilde/homelab/lxc/gitea/check-config.sh
        EOF
        ```

    === "Manual"

        ```ini
        [Unit]
        Description=Check Gitea configuration sync status

        [Service]
        Type=oneshot
        User=root
        WorkingDirectory=/root/git/nicholaswilde/homelab/lxc/gitea
        ExecStart=/root/git/nicholaswilde/homelab/lxc/gitea/check-config.sh
        ```

### :clock: Systemd Timer

Create `/etc/systemd/system/gitea-check-config.timer`:

!!! abstract "/etc/systemd/system/gitea-check-config.timer"

    === "Automatic"
    
        ```shell
        cat <<EOF > /etc/systemd/system/gitea-check-config.timer
        [Unit]
        Description=Run Gitea configuration check daily

        [Timer]
        OnCalendar=daily
        Persistent=true

        [Install]
        WantedBy=timers.target
        EOF
        ```

    === "Manual"

        ```ini
        [Unit]
        Description=Run Gitea configuration check daily

        [Timer]
        OnCalendar=daily
        Persistent=true

        [Install]
        WantedBy=timers.target
        ```

Enable and start the timer:

=== "Manual"

    ```shell
    systemctl enable --now gitea-check-config.timer
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
