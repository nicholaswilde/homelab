---
tags:
  - lxc
  - proxmox
  - debian
---
# :package: reprepro

[reprepro][1] is used as a local repository for deb packages.

Some apps, like SOPS, release deb files, but are not a part of the normal repository. Hosting them locally, allows me to download the package once and then easily update on all other containers.

## :hammer_and_wrench: Installation

!!! code ""

    ```shell
    apt install reprepro apache2 gpg
    ```

## :gear: Config

### :feather: Apache

!!! abstract "/etc/apache2/apache2.conf"

    === "Automated"

        ```shell
        echo "ServerName localhost" | tee -a /etc/apache2/apache2.conf
        ```

    === "Manual"

        ```ini
        ServerName localhost
        ```

!!! abstract "/etc/apache2/conf-availabe/repos.conf"

    === "Automated"
    
        ```shell
        cat <<EOF > /etc/apache2/conf-availabe/repos.conf 
        --8<-- "reprepro/apache2/conf-available/repos.conf"
        EOF
        ```

    === "Download"

        ```shell
        wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/apache2/conf-available/repos.conf -O /etc/apache2/conf-availabe/repos.conf
        ```

    === "Manual"
    
        ```xml
        --8<-- "reprepro/apache2/conf-available/repos.conf"
        ```

!!! example "Enable and test"

    ```shell
    (
        a2enconf repos && \
        apache2ctl configtest && \
        service apache2 restart
    )
    ```

## :gear: Config

### :package: Repository

!!! code "Make directories"
    
    ```shell
    (
      [ -d /srv/reprepro/debian/conf ] || mkdir -p /srv/reprepro/debian/conf
      [ -d /srv/reprepro/ubuntu/conf ] || mkdir -p /srv/reprepro/ubuntu/conf
     )
     ```

!!! code "Generate new gpg keys"

    ```shell
    gpg --full-generate-key
    ```

    ```shell
    gpg --list-keys  
     pub  2048R/489CD644 2014-07-15  
     uid         Your Name <your_email_address@domain.com>  
     sub  2048R/870B8E2D 2014-07-15
    ```

!!! code "Get short fingerprint"

    ```shell
    gpg --list-keys noreply@email.com | sed -n '2p'| sed 's/ //g' | tail -c 9
    ```

!!! abstract "Export public gpg key"

    ```shell
    gpg --armor --output /srv/reprepro/public.gpg.key --export-options export-minimal --export 089C9FAF
    ```
    
!!! abstract "/srv/reprepo/&lt;dist&gt;/conf/distributions"

    === "Automated"

        ```shell
        (
          cat <<EOF > /srv/reprepo/debian/conf/distributions
          --8<-- "reprepro/debian/conf/distributions"
          EOF
          cat <<EOF > /srv/reprepo/ubuntu/conf/distributions
          --8<-- "reprepro/ubuntu/conf/distributions"
          EOF
        )
        ```
    === "Symlinks"

        ```shell
        (
          ln -s /root/git/nicholaswilde/homelab/pve/reprepro/debian/conf/distributions /srv/reprepro/debian/conf/distributions
          ln -s /root/git/nicholaswilde/homelab/pve/reprepro/ubuntu/conf/distributions /srv/reprepro/ubuntu/conf/distributions
        )
        ```
        
    === "Download"

        ```shell
        (
          wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/debian/conf/distributions -O /srv/reprepro/debian/conf/distributions
          wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/ubuntu/conf/distributions -O /srv/reprepro/ubuntu/conf/distributions
        )
        ```

    === "Debian Manual"

        ```yaml
        --8<-- "reprepro/debian/conf/distributions"
        ```

    === "Ubuntu Manual"

        ```yaml
        --8<-- "reprepro/ubuntu/conf/distributions"
        ```

!!! abstract "/srv/reprepo/&lt;dist&gt;/conf/options"

    === "Automated"

        ```shell
        cat <<EOF > /srv/reprepo/debian/conf/options
        --8<-- "reprepro/debian/conf/options::3"
        EOF
        cat <<EOF > /srv/reprepo/ubuntu/conf/options
        --8<-- "reprepro/ubuntu/conf/options::3"
        EOF
        ```

    === "Download"

        ```shell
        (
          wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/debian/conf/options -O /srv/reprepro/debian/conf/options
          wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/ubuntu/conf/options -O /srv/reprepro/ubuntu/conf/options
        )
        ```

    === "Symlinks"

        ```shell
        (
          ln -s /root/git/nicholaswilde/homelab/pve/reprepro/debian/conf/options /srv/reprepro/debian/conf/options
          ln -s /root/git/nicholaswilde/homelab/pve/reprepro/ubuntu/conf/options /srv/reprepro/ubuntu/conf/options
        )
        ```

    === "Debian Manual"

        ```ini
        --8<-- "reprepro/debian/conf/options"
        ```

    === "Ubuntu Manual"

        ```ini
        --8<-- "reprepro/ubuntu/conf/options"
        ```

!!! abstract "/srv/reprepo/&lt;dist&gt;/conf/override.&lt;codename&gt;"

    === "Automatic"

        ```shell
        task symlinks
        ```
        
    === "Download"

        ```shell
        (
          sudo wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/debian/conf/override.bullseye -O /srv/reprepro/debian/conf/override.bullseye
          sudo wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/debian/conf/override.bookworm -O /srv/reprepro/debian/conf/override.bookworm
          sudo wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/debian/conf/override.trixie -O /srv/reprepro/debian/conf/override.trixie
          sudo wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/ubuntu/conf/override.plucky -O /srv/reprepro/ubuntu/conf/override.plucky
          sudo wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/ubuntu/conf/override.oracular -O /srv/reprepro/ubuntu/conf/override.oracular
          sudo wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/ubuntu/conf/override.noble -O /srv/reprepro/ubuntu/conf/override.noble
          sudo wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/ubuntu/conf/override.jammy -O /srv/reprepro/ubuntu/conf/override.jammy
        )
        ```

    === "Symlinks"

        ```shell
        (
          sudo ln -fs /root/git/nicholaswilde/homelab/pve/reprepro/debian/conf/override.bullseye /srv/reprepro/debian/conf/override.bullseye
          sudo ln -fs /root/git/nicholaswilde/homelab/pve/reprepro/debian/conf/override.bookworm /srv/reprepro/debian/conf/override.bookworm
          sudo ln -fs /root/git/nicholaswilde/homelab/pve/reprepro/debian/conf/override.trixie /srv/reprepro/debian/conf/override.trixie
          sudo ln -fs /root/git/nicholaswilde/homelab/pve/reprepro/ubuntu/conf/override.plucky /srv/reprepro/ubuntu/conf/override.plucky
          sudo ln -fs /root/git/nicholaswilde/homelab/pve/reprepro/ubuntu/conf/override.oracular /srv/reprepro/ubuntu/conf/override.oracular
          sudo ln -fs /root/git/nicholaswilde/homelab/pve/reprepro/ubuntu/conf/override.noble /srv/reprepro/ubuntu/conf/override.noble
          sudo ln -fs /root/git/nicholaswilde/homelab/pve/reprepro/ubuntu/conf/override.jammy /srv/reprepro/ubuntu/conf/override.jammy
        )
        ```

    === "Manual"
    
        ```shell
        (
          sudo touch /srv/reprepro/debian/conf/override.bookworm
          sudo touch /srv/reprepro/debian/conf/override.bullseye
          sudo touch /srv/reprepro/debian/conf/override.trixie
          sudo touch /srv/reprepro/ubuntu/conf/override.plucky
          sudo touch /srv/reprepro/ubuntu/conf/override.oracular
          sudo touch /srv/reprepro/ubuntu/conf/override.noble
          sudo touch /srv/reprepro/ubuntu/conf/override.jammy
        )
        ```

### :key: Environmental File

A `.env` file is used to set variables that are used with task and scripts.

!!! code "`homelab/pve/reprepro`"

    === "Automatic"

        ```shell
        task init
        ```

    === "Manual"

        ```shell
        cp .env.tmpl .env
        ```

Edit the `.env` file with your preferred text editor.

??? abstract ".env"

    ```ini
    --8<-- "reprepro/.env.tmpl"
    ```

### :label: Adding a New Release Codename

To add a new release codename to reprepro:

1. Add a new `override.<codename>` file in `/srv/reprepro/<dist>/conf`.
2. Add a new entry to `/srv/reprepro/<dist>/conf/distributions` file.

!!! abstract "`/srv/reprepro/<dist>/conf/distributions`"

    ```ini
    Origin: Ubuntu
    Label: Oracular apt repository
    Codename: plucky
    Architectures: amd64 arm64 armhf
    Components: main
    Description: Apt repository for Ubuntu stable - Plucky
    DebOverride: override.plucky
    DscOverride: override.plucky
    SignWith: 089C9FAF
    ```

## :pencil: Usage

### :desktop_computer: Server

!!! code "Add deb file to reprepro."

    === "Manual"

        ```shell
        (
          sudo reprepro -b /srv/reprepro/debian includedeb bookworm sops_3.9.4_amd64.deb
          sudo reprepro -b /srv/reprepro/debian includedeb bullseye sops_3.9.4_amd64.deb
          sudo reprepro -b /srv/reprepro/debian includedeb trixie sops_3.9.4_amd64.deb
          sudo reprepro -b /srv/reprepro/ubuntu includedeb plucky sops_3.9.4_amd64.deb
          sudo reprepro -b /srv/reprepro/ubuntu includedeb oracular sops_3.9.4_amd64.deb
          sudo reprepro -b /srv/reprepro/ubuntu includedeb noble sops_3.9.4_amd64.deb
          sudo reprepro -b /srv/reprepro/ubuntu includedeb jammy sops_3.9.4_amd64.deb
        )
        ```

### :computer: Client

!!! code "Download gpg key"

    ```shell
    curl -fsSL http://deb.l.nicholaswilde.io/public.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/reprepro.gpg
    ```

Add repo and install.

!!! abstract "`/etc/apt/sources.list.d/reprepro.list`"

    === "Automatic"

        === "Bookworm"
    
            ```shell
            (
              echo "deb [signed-by=/etc/apt/keyrings/reprepro.gpg] http://deb.l.nicholaswilde.io/debian bookworm main" >> /etc/apt/sources.list.d/reprepro.list && \
              apt update && \
              apt install sops
            )
            ```

        === "Bullseye"
    
            ```shell
            (
              echo "deb [signed-by=/etc/apt/keyrings/reprepro.gpg] http://deb.l.nicholaswilde.io/debian bullseye main" >> /etc/apt/sources.list.d/reprepro.list && \
              apt update && \
              apt install sops
            )
            ```

        === "Trixie"

            ```shell
            (
              echo "deb [signed-by=/etc/apt/keyrings/reprepro.gpg] http://deb.l.nicholaswilde.io/debian trixie main" >> /etc/apt/sources.list.d/reprepro.list && \
              apt update && \
              apt install sops
            )
            ```

    === "Manual"

        === "Bookworm"

            ```ini
            deb [signed-by=/etc/apt/keyrings/reprepro.gpg] http://deb.l.nicholaswilde.io/debian bookworm main
            ```

            ```shell
            apt update && \
            apt install sops
            ```

        === "Bullseye"

            ```ini
            deb [signed-by=/etc/apt/keyrings/reprepro.gpg] http://deb.l.nicholaswilde.io/debian bullseye main
            ```

            ```shell
            apt update && \
            apt install sops
            ```

        === "Trixie"

            ```ini
            deb [signed-by=/etc/apt/keyrings/reprepro.gpg] http://deb.l.nicholaswilde.io/debian trixie main
            ```

            ```shell
            apt update && \
            apt install sops
            ```

## :scroll: Scripts

Some scripts are provided to help with common tasks.

### :package: Update Reprepro

The script `update-reprepro.sh` is used to compare the latest released versions of the apps specified with the 
`SYNC_APPS_GITHUB_REPOS` and `PACKAGE_APPS` variables in the `.env` file to the local versions.

If out of date, the compressed archives specified in the `PACKAGE_APPS` variable are downloaded, packaged into deb files,
and added to reprepro and deb files located in the `SYNC_APPS_GITHUB_REPOS` variable are downloaded and add to reprepro.

!!! code "`homelab/pve/reprepro`"

    === "Task"

        ```shell
        task update-reprepro
        ```
        
    === "Manual"
    
        ```shell
        sudo ./update-reprepro.sh
        ```

??? abstract "package-apps.sh"

    ```bash
    --8<-- "reprepro/update-reprepro.sh"
    ```

### :package: Package Neovim

The script `package-neovim.sh` is used to compare the latest released version of Neovim to the local version in reprepro.

If out of date, the compressed archive is downloaded, built, packaged into a deb file.

The reason this is separate from `update-reprepro.sh` is because dependencies need to get packaged along with the binary
and an `armhf` version is not part of the release package.

There are three ways to build the Neovim package for different architectures:

  1. **Docker**: Use `@pve/reprepro/docker/**` on the localhost to build for multiple platforms.
  2. **Ansible**: Use `@pve/reprepro/ansible/**` if you have physical machines with different architectures.
  3. **Manual Script**: Log into each machine with a different architecture and run the `@pve/reprepro/package-neovim.sh` script.

!!! tip

    To get multiple architectures of the deb file, the script may be run on different architecture platforms. For
    instance, I use my [RPi2](../hardware/rpi2.md) to build the `armv7l`, [RPi5](../hardware/rpi5.md) to build
    the `arm64`, and [HP](../hardware/hp-prodesk-600-g3.md) to build the `amd64` version.

!!! code "`homelab/pve/reprepro`"

    === "Task"

        ```shell
        task package-neovim
        ```
        
    === "Manual"
    
        ```shell
        sudo ./package-neovim.sh
        ```

??? abstract "package-neovim.sh"

    ```bash
    --8<-- "reprepro/package-neovim.sh"
    ```

### :package: Package SOPS

The script `package-sops.sh` is used to compare the latest released version of SOPS to the local version in reprepro.

If out of date, the compressed archive is downloaded, built, packaged into a deb file.

The reason this is separate from `update-reprepro.sh` is because the sops repo doesn't offer an `armhf` version and so I
manually build and package the `armhf` version and add it to reprepro.

!!! tip

    To get multiple architectures of the deb file, the script may be run on different architecture platforms. For
    instance, I use my [RPi2](../hardware/rpi2.md) to build the `armhf` version.

!!! code "`homelab/pve/reprepro`"

    === "Task"

        ```shell
        task package-sops
        ```
        
    === "Manual"
    
        ```shell
        sudo ./package-sops.sh
        ```

??? abstract "package-sops.sh"

    ```bash
    --8<-- "reprepro/package-sops.sh"
    ```

### :outbox_tray: Upload Deb Files

Once the neovim or sops deb files are built, they are copied to the current `pve/reprepro` folder. The `upload-debs` task can then be used to push the deb files to the reprepro LXC using `scp`.

The `REMOTE_IP`, `REMOTE_USER`, and `REMOTE_PATH` variables in the `.env` file are used to specify the reprepro LXC.

!!! code ""

    ```bash
    task upload-debs
    ```

### :bell: Script Notifications

Some scripts can send notifications via [Mailrise](./mailrise.md).

Set the `MAILRISE_*` variables and the `ENABLE_NOTIFICATIONS` variable in the `.env` file.

## :alarm_clock: Cronjob

A cronjob can be setup to run every night to check the released versions.

!!! code "2 A.M. nightly"

    === "Automatic"
    
        ```shell
        (crontab -l 2>/dev/null; echo "0 2 * * * /root/git/nicholaswilde/homelab/pve/reprepro/update-reprepro.sh") | crontab -
        ```
        
    === "Manual"

        ```shell
        crontab -e
        ```
        
        ```ini
        0 2 * * * /root/git/nicholaswilde/homelab/pve/reprepro/update-reprepro.sh
        ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/reprepro.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/reprepro.yaml"
    ```
        
## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "reprepro/task-list.txt"
    ```

## :link: References

  - <https://santi-bassett.blogspot.com/2014/07/setting-up-apt-repository-with-reprepro.html?m=1>
  - <https://wiki.debian.org/DebianRepository/SetupWithReprepro>
  - <https://wikitech.wikimedia.org/wiki/Reprepro>
  
[1]: <https://santi-bassett.blogspot.com/2014/07/setting-up-apt-repository-with-reprepro.html?m=1>
