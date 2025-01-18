---
tags:
  - lxc
  - proxmox
---
# reprepro

[reprepro][1] is used as a local repository for deb packages.

Some apps, like SOPS, release devs, but are not a part of the normal repository. Hosting them locally, allows me to download the package once and then easily update on all other containers.

## :link: References

[1]: <https://santi-bassett.blogspot.com/2014/07/setting-up-apt-repository-with-reprepro.html?m=1>