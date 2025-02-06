---
tags:
  - lxc
  - proxmox
---
# ![ventoy](https://a.fsdn.com/allura/p/ventoy/icon?83b3cf3559dee8e8a1302821225c2e6076b1e2fded2a1ddc8c229a99eb9efd5a?&w=90){ width="32" } Ventoy

Ventoy is used as an app to serve multipe ISOs on a bootable USB drive.
The drive is consistently plugged into the node and updated automatically using `rsync`
It is meant to be synchronized with ISOs saved in Proxmox or downloaded via qTorrent.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `24680`

    :material-information-outline: Configuration path: `/etc/ventoy`    

!!! quote ""

    === "AMD64"

        ```shell
        wget https://sourceforge.net/projects/ventoy/files/v1.1.00/ventoy-1.1.00-linux.tar.gz/download -O ventoy-1.1.00-linux.tar.gz
        ```

## :gear: Config

WIP

### :handshake: Service

## :link: References

- <https://www.ventoy.net/en/index.html>
