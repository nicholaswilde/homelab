---
tags:
  - lxc
  - proxmox
  - debian
---
# :package: reprepro

[reprepro][1] is used as a local repository for deb packages.

Some apps, like SOPS, release devs, but are not a part of the normal repository. Hosting them locally, allows me to download the package once and then easily update on all other containers.

## :hammer_and_wrench: Installation

```shell
apt install reprepro apache2 gpg
```

## :gear: Config

```shell
mkdir -p /var/www/repos/apt/debian
```

```shell title="/etc/apache2/apache2.conf"
echo "ServerName localhost" | tee -a /etc/apache2/apache2.conf
```

```xml title="/etc/apache2/conf-availabe/repos.conf"
<Directory /var/www/repos/ >  
     # We want the user to be able to browse the directory manually  
     Options Indexes FollowSymLinks Multiviews  
     Order allow,deny  
     Allow from all  
</Directory>  
 # This syntax supports several repositories, e.g. one for Debian, one for Ubuntu.  
 # Replace * with debian, if you intend to support one distribution only.  
<Directory "/var/www/repos/apt/*/db/">  
     Order allow,deny  
     Deny from all  
</Directory>  
<Directory "/var/www/repos/apt/*/conf/">  
     Order allow,deny  
     Deny from all  
</Directory>  
<Directory "/var/www/repos/apt/*/incoming/">  
     Order allow,deny  
     Deny from all  
</Directory>
```

```shell
(
    a2enconf repos && \
    apache2ctl configtest && \
    service apache2 restart
)
```

```shell
mkdir -p /var/www/repos/apt/debian/conf
```

```ini title="/var/www/repos/apt/debian/conf/distributions"
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

WIP

## :link: References

[1]: <https://santi-bassett.blogspot.com/2014/07/setting-up-apt-repository-with-reprepro.html?m=1>
