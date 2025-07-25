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

### :package: Repository

!!! code "Make directories"
    
    ```shell
    (
      [ -d /srv/reprepo/debian/conf ] || mkdir -p /srv/reprepo/debian/conf
      [ -d /srv/reprepo/ubuntu/conf ] || mkdir -p /srv/reprepo/ubuntu/conf
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
          ln -s /root/git/nicholaswilde/homelab/pve/reprepro/debian/conf/distributions /srv/reprepo/debian/conf/distributions
          ln -s /root/git/nicholaswilde/homelab/pve/reprepro/ubuntu/conf/distributions /srv/reprepo/ubuntu/conf/distributions
        )
        ```
        
    === "Download"

        ```shell
        (
          wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/debian/conf/distributions -O /srv/reprepo/debian/conf/distributions
          wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/ubuntu/conf/distributions -O /srv/reprepo/ubuntu/conf/distributions
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
          wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/debian/conf/options -O /srv/reprepo/debian/conf/options
          wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/ubuntu/conf/options -O /srv/reprepo/ubuntu/conf/options
        )
        ```

    === "Symlinks"

        ```shell
        (
          ln -s /root/git/nicholaswilde/homelab/pve/reprepro/debian/conf/options /srv/reprepo/debian/conf/options
          ln -s /root/git/nicholaswilde/homelab/pve/reprepro/ubuntu/conf/options /srv/reprepo/ubuntu/conf/options
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

    === "Download"

        ```shell
        (
          wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/debian/conf/override.bullseye -O /srv/reprepo/debian/conf/override.bullseye
          wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/debian/conf/override.bookworm -O /srv/reprepo/debian/conf/override.bookworm
          wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/ubuntu/conf/override.oracular -O /srv/reprepo/ubuntu/conf/override.oracular
          wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/ubuntu/conf/override.noble -O /srv/reprepo/ubuntu/conf/override.noble
        )
        ```

    === "Symlinks"

        ```shell
        (
          ln -s /root/git/nicholaswilde/homelab/pve/reprepro/debian/conf/override.bullseye /srv/reprepo/debian/conf/override.bullseye
          ln -s /root/git/nicholaswilde/homelab/pve/reprepro/debian/conf/override.bookworm /srv/reprepo/debian/conf/override.bookworm
          ln -s /root/git/nicholaswilde/homelab/pve/reprepro/ubuntu/conf/override.oracular /srv/reprepo/ubuntu/conf/override.oracular
          ln -s /root/git/nicholaswilde/homelab/pve/reprepro/ubuntu/conf/override.noble /srv/reprepo/ubuntu/conf/override.noble
        )
        ```

    === "Manual"
    
        ```shell
        (
          touch /srv/reprepro/ubuntu/conf/override.noble
          touch /srv/reprepro/ubuntu/conf/override.oracular
          touch /srv/reprepro/debian/conf/override.bookworm
          touch /srv/reprepro/debian/conf/override.bullseye
        )
        ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/reprepro.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/reprepro.yaml"
    ```

## :pencil: Usage

### :desktop_computer: Server

!!! code "Add deb file to reprepro."

    === "Manual"

        ```shell
        (
          reprepro -b /srv/reprepro/ubuntu/ includedeb oracular sops_3.9.4_amd64.deb
          reprepro -b /srv/reprepro/ubuntu/ includedeb noble sops_3.9.4_amd64.deb
          reprepro -b /srv/reprepro/debian/ includedeb bookworm sops_3.9.4_amd64.deb
          reprepro -b /srv/reprepro/debian/ includedeb bullseye sops_3.9.4_amd64.deb
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
    
        ```shell
        (
          echo "deb [signed-by=/etc/apt/keyrings/reprepro.gpg] http://deb.l.nicholaswilde.io/debian bookworm main" >> /etc/apt/sources.list.d/reprepro.list && \  
          apt update && \
          apt install sops
        )
        ```

    === "Manual"

        ```ini
        deb [signed-by=/etc/apt/keyrings/reprepro.gpg] http://deb.l.nicholaswilde.io/debian bookworm main
        ```

        ```shell
        apt update && \
        apt install sops
        ```

## :material-sync: Sync Check

The script `sync-check.sh` is used to compare the latest released versions of the apps SOPS and Task to the local versions.

If out of date, the debs are downloaded and added to reprepro.

!!! code "`homelab/pve/reprepro`"

    === "Task"

        ```shell
        task sync-check
        ```
        
    === "Manual"
    
        ```shell
        ./sync-check.sh
        ```

## :alarm_clock: Cronjob

A cronjob can be setup to run every night to check the released versions.

!!! code "2 A.M. nightly"

    === "Automatic"
    
        ```shell
        (crontab -l 2>/dev/null; echo "0 2 * * * /root/git/nicholaswilde/homelab/pve/reprepro/sync-check.sh) | crontab -
        ```
        
    === "Manual"

        ```shell
        crontab -e
        ```
        
        ```ini
        0 2 * * * /root/git/nicholaswilde/homelab/pve/reprepro/sync-check.sh
        ```
        
## :link: References

  - <https://santi-bassett.blogspot.com/2014/07/setting-up-apt-repository-with-reprepro.html?m=1>
  - <https://wiki.debian.org/DebianRepository/SetupWithReprepro>
  - <https://wikitech.wikimedia.org/wiki/Reprepro>
  
[1]: <https://santi-bassett.blogspot.com/2014/07/setting-up-apt-repository-with-reprepro.html?m=1>

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "reprepro/task-list.txt"
    ```
