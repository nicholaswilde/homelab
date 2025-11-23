---
tags:
  - about
---
# :construction: Development

The development of my homelab is mainly done by watching YouTube videos and occasionally browsing Reddit.

## :hammer_and_wrench: Installation

### :simple-github: Repo

Generally, the repo is meant to be used as a centralized location for my homelab config files and setup instructions.

This repo is cloned into each container and VM and then updated and maintained on that container and VM.


```shell
(
    [ -d ~/git/nicholaswilde ] || mkdir -p ~/git/nicholaswilde
    cd ~/git/nicholaswilde && \
    git clone git@github.com:nicholaswilde/homelab.git && \
    cd homelab
)
```

### :package: Containers & VMs

I use different installation methods for the containers and VMs depending on what is available.

#### :scroll: Proxmox Helper Script

If a it exists as a Proxmox Helper Script, I'll use that.

#### :package: LXC

If that doesn't exist, I'll clone a Debian LXC and manually install the app. Generally, I like to stick with LXCs because of their lower overhead.

#### :computer: VM

I'll use a VM if I need to pass through a device or the installation is complicated. I'll clone an existing Debian or Ubuntu VM and do a manual installation.

#### :simple-docker: Docker

Sometimes if the installation is really complicated, I'll use Docker inside of and LXC or VM. I generally try to avoid Docker containers because of the overhead of Docker being installed in the container or VM.

### :wrench: Tools

#### :package: apt

Tools are generally installed, generally, using `apt`.

!!! note

    I try to avoid using other package systems, such as `pip` or `npm`, to avoid the overhead of having those package systems installed.

!!! note ":v: `curl` vs `wget`"

    I generally prefer using `curl` over `wget` for downloading files and making HTTP requests. `curl` is often more versatile, supporting a wider range of protocols and offering finer control over requests, which is beneficial for scripting and debugging in diverse environments.

#### :package: reprepro

If a `deb` file is available for download for the tool, I'll add it to my [`reprepro`][8] registry and install the tool using `apt`. Updating the tool is then just a matter of running apt update using Ansible.

#### :inbox_tray: installer

If the tool is only available to download as a binary file, I'll use my [`installer`][9] container.

## :gear: Config

Config files are backed up into this repo so that can be replicated or referenced when lost.

### :lock: Keys

Keys are syncronized across containers using [Syncthing][15] so that I don't have to manually copy them over.

## :floppy_disk: Backups

The original files are copied into the original config location with a `.bak` extension before making any changes to them.

??? example

    ```shell
    cp /opt/AdGuardHome/AdGuardHome.yaml /opt/AdGuardHome/AdGuardHome.yaml.bak
    ```

### :link: Symlinks

Generally, config files are moved to the repo for remote backup and then symlinked back to the original location.

!!! note

    The app service needs to be stopped and restarted when moving the config files.

??? example

    ```shell
    (
      systemctl stop AdGuardHome.service
      cp /opt/AdGuardHome/AdGuardHome.yaml /root/git/nicholaswilde/homelab/pve/adguardhome/AdGuardHome.yaml
      ln -s /root/git/nicholaswilde/homelab/pve/adguardhome/AdGuardHome.yaml /opt/AdGuardHome/AdGuardHome.yaml
      systemctl start AdGuardHome.service
    )
    ```

!!! warning

    Some apps have trouble starting their service when using symlinked config files.

### :lock: Encrypted Files

If the config file contains secrets, the file is encrypted and saved in the repo and the unencrypted file is added to `.gitignore`.

Encrypted files will end in `.enc` and are encrypted using [SOPS][13] and age.

??? example

    ```shell
    sops -d --input-type dotenv --output-type dotenv .env.enc > .env
    ```

### :pencil: .env Files

[.env][14] files are used to store variables and secrets. There are used whenever possible.

`.env` files are ignored in this repo so that secrets aren't commited.

### :material-content-copy: Template Files

Template files end in `.tmpl` and are not used by the app and are meant to be copied.

??? example

    ```shell
    cp .env.tmpl .env
    ```

## :twisted_rightwards_arrows: Workflow

My general workflow when creating a new LXC or VM.

1. Create VM or LXC container.
2. Run `homelab-pull`.
3. Add to Ansible inventory.
4. Setup app.
5. Backup config files to repo on cintainer.
6. Add to [AdGuardHome][1].
7. Run [AdGuardHome sync][2].
8. Add to [Traefik][4].
9. Add to [homepage][5].
10. Add to homelab docs.
11. Add to [WatchYourLAN][6].
12. Add to [Beszel][7].
13. Add to [authentik][12].

## :page_facing_up: New Document Pages

New pages for this site can be created using [jinja2][3] and the `.template.md.j2` file.

!!! code "`homelab/docs`"

    === "Task"

        ```shell
        APP_NAME="New App" task new > apps/new-app.md
        ```
        
    === "jinja2-cli"
    
        ```shell
        jinja2 .template.md.j2 -D app_name="New App" -D app_port=8080 -D config_path=/opt/new-app > apps/new-app.md
        ```

## :rocket: Upgrades

Maintenance is usually done by monitoring GitHub repos for releases. Once an email is received, I SSH into the host and perform a manual update.

I prefer to "manually" update my homelab because I can react to anything that goes wrong. Yes, I can have automated monitoring that sends me a notification when something goes wrong, but that itself takes maintenance.

### :scroll: Upgrades via Custom Scripts

Sometimes I will create my own bash script to update the app. Typically, the script is named `update.sh` and is located in the `homelab/pve/<app name>` directory.

!!! code "homelab/pve/appname/update.sh"

    === "Task"

        ```shell
        task update
        ```

    === "Manual"

        ```shell
        sudo ./update.sh
        ```

### ![proxmox](https://cdn.jsdelivr.net/gh/selfhst/icons/png/proxmox.png){: style="vertical-align": width="24" } Upgrades via Proxmox Helper Scripts

The helper scripts can update the app in the LXC/VM.

!!! code ""

    ```bash
    update
    ```

One thing I don't like about the scripts is their interactivity. I prefer not to be prompted.

What is nice is that that the scripts are updated automatically by the community and they are available globally throughout the container. Although, I can make my custom script global as well.

Sometimes, I will convert the community script to a custom one.

### :whale2: Docker Upgrades

Docker tags are scanned by [Mend Renovate][10] :simple-renovate:, which opens a PR if a newer version is available.

The PR is then merged and then the repo is pulled and updated on the LXC/VM and then Docker Compose performs a pull and restarts the Docker container.

The old and unused images are then purged to save space in the LXC/VM.

!!! warning

    The below commands purge any unused Docker images! Use at your own risk!

!!! code "`homelab/docker/appname`"

    === "Task"

        ```shell
        task upgrade
        ```
        
    === "Manual"
    
        ```shell
        (
          git pull origin
          docker compose up --force-recreate --build -d
          docker image prune -a -f
        )
        ```

### ![ansible](https://cdn.jsdelivr.net/gh/selfhst/icons/svg/ansible.svg){: style="vertical-align": width="24" } Ansible Upgrades

I also use Ansible for batch updates and changes. See my [Homelab Playbooks][16].

## :alarm_clock: Cronjobs

Cronjobs :alarm_clock: are run on some containers to periodically perform functions, usually to sync files.

!!! code "Edit job"

    === "Manual"

        ```shell
        crontab -e
        ```

        ```ini
        0 2 * * * * /foo.sh
        ```
      
## :handshake: Services

Systemd services are used to keep processes running in the background.

The services are usually created automatically if installed via a package manager, such as `apt` :package:.

Apps that are manually installed, such as Ventoy, need a service to keep them running after restarts.

Docker :simple-docker: containers don't require services because they are managed by the [restart policy][11].

## :floppy_disk: Logs

Logs are used to debug applications. They may be looked at once or followed get to real time updates.

### :package: LXC Logs

??? example

    === "journalctl"

        ```shell
        journalctl -xeu AdGuardHome.service
        ```

### :simple-docker: Docker Logs

??? example

    === "Once"
    
        ```shell
        docker logs immich-server
        ```

    === "Followed"

        ```shell
        docker logs immich-server -f
        ```

## :bell: Notifications 

My preferred form of notifications in my Homelab are email via [mailrise][17] because they are lasting and not easily dismissed.



## :link: References

[3]: <../tools/jinja2-cli.md>
[1]: <../apps/adguardhome.md>
[2]: <../apps/adguardhome-sync.md>
[4]: <../apps/traefik.md>
[5]: <../apps/homepage.md>
[6]: <../apps/watchyourlan.md>
[7]: <../apps/beszel.md>
[8]: <../apps/reprepro.md>
[9]: <../apps/installer.md>
[10]: <https://github.com/apps/renovate>
[11]: <https://docs.docker.com/reference/compose-file/services/#restart>
[12]: <../apps/authentik.md>
[13]: <../tools/sops.md>
[14]: <../tools/env-files.md>
[15]: <../tools/syncthing.md>
[16]: <https://nicholaswilde.io/homelab-playbooks>
[17]: <../apps/mailrise.md>

