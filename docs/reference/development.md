---
tags:
  - reference
---
# :construction: Development

The development of my homelab is mainly done by watching YouTube videos and occasionally browsing Reddit.

## :hammer_and_wrench: Installation

### :simple-github: Repo

Generally, the repo is meant to be used as a centralized location for my homelab config files and setup instructions.

This repo is cloned into each container and VM and then updated and maintained on that container and VM.

!!! quote ""

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

#### :package: reprepro

If a `deb` file is available for download for the tool, I'll add it to my [`reprepro`][8] registry and install the tool using `apt`. Updating the tool is then just a matter of running apt update using Ansible.

#### :inbox_tray: installer

If the tool is only available to download as a binary file, I'll use my [`installer`][9] container.

## :twisted_rightwards_arrows: Workflow

1. Create VM or LXC.
2. Run setup playbook.
3. Add to lxcAll inventory.
4. Clone and log into homelab repo on container.
5. Setup app.
6. Add to [AdGuardHome][1].
7. Run [AdGuardHome sync][2].
8. Add to [Traefik][4].
9. Add to [homepage][5].
10. Add to homelab docs.
11. Add to [WatchYourLAN][6].
12. Add to [Beszel][7].

## :page_facing_up: New Document Pages

New pages for this site can be created using [jinja2][3] and the `.template.md.j2` file.

!!! quote "From `homepage/docs`"

    === "task"

        ```shell
        APP_NAME="New App" task new > apps/new-app.md
        ```
        
    === "jinja2-cli"
    
        ```shell
        jinja2 .template.md.j2 -D app_name="New App" -D app_port=8080 -D config_path=/opt/new-app > apps/new-app.md
        ```

## :link: References

[3]: <../tools/jinja2-cli.md>
[1]: <../apps/adguard.md>
[2]: <../apps/adguard-sync.md>
[4]: <../apps/traefik.md>
[5]: <../apps/homepage.md>
[6]: <../apps/watchyourlan.md>
[7]: <../apps/beszel.md>
[8]: <../apps/reprepro.md>
[9]: <../apps/installer.md>
