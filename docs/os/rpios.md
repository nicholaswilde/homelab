---
tags:
  - rpi
  - os
  - proxmox
  - arm64
---
# :simple-raspberrypi: Raspberry Pi OS

This page outlines the setup of Raspberry Pi OS for use with Proxmox on a Raspberry Pi 5.

## :gear: Installation

### :simple-raspberrypi: Setup Raspberry Pi OS

!!! code "Create a tmp dir"

    ```shell
    cd "$(mktemp -d)"
    ```

!!! code "Get the latest image version"

    === "arm64"
    
        ```shell
        curl -fsSL https://downloads.raspberrypi.com/raspios_lite_arm64/images/ | grep -Eo '[a-zA-Z0-9_.-]+-[0-9]{4}-[0-9]{2}-[0-9]{2}' | sort -u | tail -n 1
        ```

        !!! success "Output"

            ```shell
            raspios_lite_arm64-2025-11-24
            ```

    === "armhf"
    
        ```shell
        curl -fsSL https://downloads.raspberrypi.com/raspios_lite_armhf/images/ | grep -Eo '[a-zA-Z0-9_.-]+-[0-9]{4}-[0-9]{2}-[0-9]{2}' | sort -u | tail -n 1
        ```

        !!! success "Output"

            ```shell
            raspios_lite_armhf-2025-11-24
            ```

!!! code "Download image"

    === "arm64"
    
        ```shell
        curl -fSLO https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2025-11-24/2025-11-24-raspios-trixie-arm64-lite.img.xz
        ```

    === "armhf"
    
        ```shell
        curl -fSLO https://downloads.raspberrypi.com/raspios_lite_armhf/images/raspios_lite_armhf-2025-11-24/2025-11-24-raspios-trixie-armhf-lite.img.xz
        ```

!!! note

    Pay attention to which debian version the download URL is (e.g. `trixie`, `bookworm`, etc.)

See [raspios_lite_arm64](https://downloads.raspberrypi.com/raspios_lite_arm64/images/) and [raspios_lite_armhf](https://downloads.raspberrypi.com/raspios_lite_armhf/images/).

!!! code "Write image to SD card"

    === "arm64"
    
        ```shell
        xzcat 2025-11-24-raspios-trixie-arm64-lite.img.xz | dd /dev/mmcblk0 status=progress
        ```

!!! code "Mount boot partition"

    === "sudo"
    
        ```shell
        (
          [ -d /media/sd ] || mkdir /media/sd
          sudo mount -a /dev/mmcblk0p1 /media/sd
        )
        ```

!!! code "Change to boot partition"

    ```shell
    cd /media/sd
    ```

### :fontawesome-solid-user-plus: Create Username & Password

!!! abstract "/boot/firmware/userconf.txt"

    === "Automatic"
    
        ```shell
        echo 'nicholas:' "$(openssl passwd -6)" | sed 's/ //g' | sudo tee -a userconf.txt
        ```

    === "Manual"

        ```shell
        nicholas:<hash>
        ```

### :computer: Enable SSH

!!! abstract "/boot/ssh"
    
    ```shell
    touch ssh
    ```

#### :page_facing_up: Kernel Page Size

You should use the Kernel with 4K pagesize

!!! abstract "/boot/firmware/config.txt"

    === "Manual"
    
        ```shell
        kernel=kernel8.img # to end of line
        ```

#### :material-memory: CT Notes

Is the container summary memory usage and swap usage always shows `0`?

!!! abstract "/boot/firmware/cmdline.txt"

    === "Automatic"

        ```shell
        sed -i '1s/$/ cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/' cmdline.txt
        ```

    === "Manual"

        ```ini
        cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1
        ```

Unmount SD card, plug into the Raspberry Pi and boot

## :simple-proxmox: PXVIRT Installation

!!! tip

    Alternatively, the [ISO][1] may be downloaded and installed as a removable media.

Log into the Raspberry Pi using SSH.

!!! code "Switch to `root` user. Default password is blank for Raspberry Pi OS.""

    ```shell
    sudo su root
    ```

!!! code "Set root password so that you can log into Proxmox web GUI"

    ```shell
    passwd
    ```

Add an `/etc/hosts` entry for your IP address.

Please make sure that your machine's hostname is resolvable via `/etc/hosts`, i.e. you need an entry in `/etc/hosts` which assigns an address to its hostname.

Make sure that you have configured one of the following addresses in `/etc/hosts` for your hostname:

1 `IPv4` or
1 `IPv6` or
1 `IPv4` and 1 `IPv6`

!!! note

    This also means removing the address `127.0.1.1` that might be present as default.

!!! code "Get IP address"

    ```shell
    hostname -I | awk '{print $1}'
    ```

For instance, if your IP address is `192.168.15.77`, and your hostname `prox4m1`, then your `/etc/hosts` file could look like:

!!! abstract "/etc/hosts"

    ```ini
    127.0.0.1       localhost.localdomain localhost

    ::1             localhost ip6-localhost ip6-loopback
    ff02::1         ip6-allnodes
    ff02::2         ip6-allrouters

    192.168.1.192   pve02.nicholaswilde.io pve02
    ```

!!! code "Test if your setup is ok using the hostname command"

    ```shell
    hostname --ip-address
    ```

!!! success "should return your IP address here"

    ```shell
    192.168.1.192
    ```

Then see [install PXVIRT](http://localhost:8000/homelab/hardware/rpi5/#install-pxvirt).

## :link: References

[1]: <https://mirrors.lierfang.com/pxcloud/pxvirt/isos/>
[2]: <https://www.raspberrypi.com/software/>
[3]: <https://www.raspberrypi.com/documentation/computers/configuration.html#configuring-a-user>