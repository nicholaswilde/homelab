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

!!! quote ""

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

```shell title="Make directories"
(
  [ -d /srv/reprepo/debian/conf ] || mkdir -p /srv/reprepo/debian/conf
  [ -d /srv/reprepo/ubuntu/conf ] || mkdir -p /srv/reprepo/ubuntu/conf
)
```

```shell title="Generate new gpg keys"
gpg --full-generate-key
```

```shell
gpg --list-keys  
 pub  2048R/489CD644 2014-07-15  
 uid         Your Name <your_email_address@domain.com>  
 sub  2048R/870B8E2D 2014-07-15
```

```shell title="Get short fingerprint"
gpg --list-keys noreply@email.com | sed -n '2p'| sed 's/ //g' | tail -c 9
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

    === "Debian Manual"

        ```ini
        --8<-- "reprepro/debian/conf/options"
        ```

    === "Ubuntu Manual"

        ```ini
        --8<-- "reprepro/ubuntu/conf/options"
        ```

## :pencil: Usage

Add deb file to reprepro

!!! quote ""

    === "Manual"

        ```shell
        (
          reprepro --confdir /srv/reprepro/ubuntu/conf/ includedeb oracular sops_3.9.4_amd64.deb
          reprepro --confdir /srv/reprepro/ubuntu/conf/ includedeb noble sops_3.9.4_amd64.deb
          reprepro --confdir /srv/reprepro/debian/conf/ includedeb bookworm sops_3.9.4_amd64.deb
          reprepro --confdir /srv/reprepro/debian/conf/ includedeb bullseye sops_3.9.4_amd64.deb
        )
        ```

## :link: References

  - <https://santi-bassett.blogspot.com/2014/07/setting-up-apt-repository-with-reprepro.html?m=1>
  - <https://wiki.debian.org/DebianRepository/SetupWithReprepro>
  
[1]: <https://santi-bassett.blogspot.com/2014/07/setting-up-apt-repository-with-reprepro.html?m=1>
