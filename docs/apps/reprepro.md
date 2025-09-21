--8<-- "reprepro/debian/conf/override.trixie"
          wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/debian/conf/override.bullseye -O /srv/reprepro/debian/conf/override.bullseye
          wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/debian/conf/override.bookworm -O /srv/reprepro/debian/conf/override.bookworm
          wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/ubuntu/conf/override.oracular -O /srv/reprepro/ubuntu/conf/override.oracular
          wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/ubuntu/conf/override.noble -O /srv/reprepro/ubuntu/conf/override.noble
          wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/debian/conf/override.forky -O /srv/reprepro/debian/conf/override.forky
        )
        ```

    === "Symlinks"

        ```shell
        (
          ln -s /root/git/nicholaswilde/homelab/pve/reprepro/debian/conf/override.trixie /srv/reprepro/debian/conf/override.trixie
          ln -s /root/git/nicholaswilde/homelab/pve/reprepro/debian/conf/override.bullseye /srv/reprepro/debian/conf/override.bullseye
          ln -s /root/git/nicholaswilde/homelab/pve/reprepro/debian/conf/override.bookworm /srv/reprepro/debian/conf/override.bookworm
          ln -s /root/git/nicholaswilde/homelab/pve/reprepro/ubuntu/conf/override.oracular /srv/reprepo/ubuntu/conf/override.oracular
          ln -s /root/git/nicholaswilde/homelab/pve/reprepro/ubuntu/conf/override.noble /srv/reprepro/ubuntu/conf/override.noble
          ln -s /root/git/nicholaswilde/homelab/pve/reprepro/debian/conf/override.forky /srv/reprepro/debian/conf/override.forky
        )
        ```

    === "Manual"
    
        ```shell
        (
          touch /srv/reprepro/ubuntu/conf/override.noble
          touch /srv/reprepro/ubuntu/conf/override.oracular
          touch /srv/reprepro/debian/conf/override.trixie
          touch /srv/reprepro/debian/conf/override.bookworm
          touch /srv/reprepro/debian/conf/override.bullseye
          touch /srv/reprepro/debian/conf/override.forky
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
          reprepro -b /srv/reprepro/debian/ includedeb trixie sops_3.9.4_amd64.deb
          reprepro -b /srv/reprepro/debian/ includedeb bookworm sops_3.9.4_amd64.deb
          reprepro -b /srv/reprepro/debian/ includedeb forky sops_3.9.4_amd64.deb
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

        === "Trixie"

            ```shell
            (
              echo "deb [signed-by=/etc/apt/keyrings/reprepro.gpg] http://deb.l.nicholaswilde.io/debian trixie main" >> /etc/apt/sources.list.d/reprepro.list && \
              apt update && \
              apt install sops
            )
            ```

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

        === "Forky"

            ```shell
            (
              echo "deb [signed-by=/etc/apt/keyrings/reprepro.gpg] http://deb.l.nicholaswilde.io/debian forky main" >> /etc/apt/sources.list.d/reprepro.list && \
              apt update && \
              apt install sops
            )
            ```

    === "Manual"

        === "Trixie"

            ```ini
            deb [signed-by=/etc/apt/keyrings/reprepro.gpg] http://deb.l.nicholaswilde.io/debian trixie main
            ```

            ```shell
            apt update && \
            apt install sops
            ```

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

        === "Forky"

            ```ini
            deb [signed-by=/etc/apt/keyrings/reprepro.gpg] http://deb.l.nicholaswilde.io/debian forky main
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
        (crontab -l 2>/dev/null; echo "0 2 * * * /root/git/nicholaswilde/homelab/pve/reprepro/sync-check.sh") | crontab - 
        ```
        
    === "Manual"

        ```shell
        crontab -e
        ```
        
        ```ini
        0 2 * * * /root/git/nicholaswilde/homelab/pve/reprepro/sync-check.sh
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
  
[1]: <https://santi-bassett.blogspot.com/2014/07/setting-up-apt-repository-with-reprepro.html?m=1>iki/Reprepro>
  
[1]: <https://santi-bassett.blogspot.com/2014/07/setting-up-apt-repository-with-reprepro.html?m=1>