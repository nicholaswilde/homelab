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

    === "Automatic"
        ```shell
        cat <<EOF > /etc/apache2/conf-availabe/repos.conf 
        <Directory /srv/reprepro/ >
             # We want the user to be able to browse the directory manually  
             Options Indexes FollowSymLinks Multiviews  
             Order allow,deny  
             Allow from all  
        </Directory>  
         # This syntax supports several repositories, e.g. one for Debian, one for Ubuntu.  
         # Replace * with debian, if you intend to support one distribution only.  
        <Directory "/srv/reprepro/*/db/">  
             Order allow,deny  
             Deny from all  
        </Directory>  
        <Directory "/srv/reprepro/*/conf/">  
             Order allow,deny  
             Deny from all  
        </Directory>  
        <Directory "/srv/reprepro/*/incoming/">  
             Order allow,deny  
             Deny from all  
        </Directory>
        EOF
        ```

    === "Download"

        ```shell
        wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/apache2/conf-available/repos.conf -O /etc/apache2/conf-availabe/repos.conf
        ```

    === "Manual"
    
        ```xml
        <Directory /srv/reprepro/ >  
             # We want the user to be able to browse the directory manually  
             Options Indexes FollowSymLinks Multiviews  
             Order allow,deny  
             Allow from all  
        </Directory>  
         # This syntax supports several repositories, e.g. one for Debian, one for Ubuntu.  
         # Replace * with debian, if you intend to support one distribution only.  
        <Directory "/srv/reprepro/*/db/">  
             Order allow,deny  
             Deny from all  
        </Directory>  
        <Directory "/srv/reprepro/*/conf/">  
             Order allow,deny  
             Deny from all  
        </Directory>  
        <Directory "/srv/reprepro/*/incoming/">  
             Order allow,deny  
             Deny from all  
        </Directory>
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

!!! abstact "/srv/reprepo/debian/conf/distributions"

    === "Manual"

        ```ini title="/srv/reprepo/debian/conf/distributions"
        Origin: Debian  
        Label: Sid apt repository  
        Codename: sid  
        Architectures: i386 amd64  
        Components: main  
        Description: Apt repository for Debian unstable - Sid  
        DebOverride: override.sid  
        DscOverride: override.sid  
        SignWith: 870B8E2D  

        Origin: Debian  
        Label: Jessie apt repository  
        Codename: jessie  
        Architectures: i386 amd64  
        Components: main  
        Description: Apt repository for Debian testing - Jessie  
        DebOverride: override.jessie  
        DscOverride: override.jessie  
        SignWith: 870B8E2D
        
        Origin: Debian  
        Label: Wheezy apt repository  
        Codename: wheezy  
        Architectures: i386 amd64  
        Components: main  
        Description: Apt repository for Debian stable - Wheezy  
        DebOverride: override.wheezy  
        DscOverride: override.wheezy  
        SignWith: 870B8E2D
        ```

!!! abstract "/srv/reprepo/&lt;dist&gt;/conf/options"

    === "Automated"

        ```shell
        cat <<EOF > /srv/reprepo/debian/conf/options
        verbose
        basedir /srv/reprepo/debian
        ask-passphrase
        EOF
        cat <<EOF > /srv/reprepo/ubuntu/conf/options
        verbose
        basedir /srv/reprepo/ubuntu
        ask-passphrase
        EOF
        ```

    === "Debian Manual"

        ```ini title="/srv/reprepo/debian/conf/options"
        verbose  
        basedir /srv/reprepo/debian  
        ask-passphrase
        ```

    === "Ubuntu Manual"

        ```ini title="/srv/reprepo/ubuntu/conf/options"
        verbose  
        basedir /srv/reprepo/ubuntu
        ask-passphrase
        ```

## :link: References

  - <https://santi-bassett.blogspot.com/2014/07/setting-up-apt-repository-with-reprepro.html?m=1>
  - <https://wiki.debian.org/DebianRepository/SetupWithReprepro>
  
[1]: <https://santi-bassett.blogspot.com/2014/07/setting-up-apt-repository-with-reprepro.html?m=1>
