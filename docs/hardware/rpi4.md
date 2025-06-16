---
tags:
  - home-assistant
  - rpi
  - arm64
---
# :simple-raspberrypi: Raspberry Pi 4 8GB

I recently converted my [Raspberry Pi 4 8GB][1] to run [Home Assistant][12] so that I can use my [NUC][13] as another Proxmox node.

!!! warning

    Everything listed below is out of date and needs to be moved to relevant pages or deleted.

### :clipboard: TL;DR

!!! code ""

    ```shell
    (
      sudo su root  && \
      passwd  && \
      echo "<ip address> <hostname>" | tee -a /etc/hosts  && \
      hostname --ip-address  && \
      echo 'deb [arch=arm64] https://mirrors.apqa.cn/proxmox/debian/pve bookworm port'>/etc/apt/sources.list.d/pveport.list && \
      curl -L https://mirrors.apqa.cn/proxmox/debian/pveport.gpg -o /etc/apt/trusted.gpg.d/pveport.gpg && \
      apt update && \
      apt full-upgrade && \
      apt install ifupdown2 && \
      apt install proxmox-ve postfix open-iscsi && \
      sed -i 's/^#?\s*PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    }
    ```

## :gear: Config

!!! example ""

    OS: [`Raspberry Pi OS Lite (64-bit)`][3]

    RAM: `8GB`

    HAT1: [`Argon Fan HAT for Raspberry Pi 4`][15]

    HAT2: [`GeeekPi M.2 NVME SSD Storage Expansion Board for Raspberry Pi 4 (52Pi EP-0171)`][14]

    DRIVE: `500GB NVMe`

### :material-usb-flash-drive: [Raspberry Pi 4 boot from usb][6]

!!! code ""

    ```shell
    sudo raspi-config
    ```

    ```shell title="GUI"
    Advanced Options -> Boot Order -> B2 NVMe/USB
    ```

    ```shell
    sudo reboot
    ```

Sometimes, the USB adapter is slow and disconnections. The [device quirks][11] may need to be set.

!!! code "Get `vendorId` and `deviceId`"

    ```shell
    sudo dmesg | grep usb
    ```

    ```shell title="Output"
    [1.301989] usb 2-1: new SuperSpeed Gen 1 USB device number 2 using xhci_hcd
    [1.332965] usb 2-1: New USB device found, idVendor=152d, idProduct=1561, bcdDevice= 1.00
    [1.332999] usb 2-1: New USB device strings: Mfr=2, Product=3, SerialNumber=1
    [1.333026] usb 2-1: Product: ASM105x
    [1.333048] usb 2-1: Manufacturer: ASMT
    [1.333071] usb 2-1: SerialNumber: 123456789B79F
    ```

!!! success "Verify the `vendorId` and `deviceId`"

    ```shell
    sudo lsusb
    ```

    ```shell title="Output"
    Bus 002 Device 002: ID 152d:1561 ASMedia Technology Inc. Name: ASM1051E SATA 6Gb/s bridge
    ```

Combine the `vendorId` and `deviceId` to get make up the `quirks`.

!!! example

    ```ini
    usb-storage.quirks=152d:1561:u
    ```

!!! abstract "Add the quirks to `/boot/firmware/cmdline.txt`"

    === "Automatic"

        ```shell
        sed -i '1s/$/ usb-storage.quirks=152d:1561:u console=serial0,115200 console=tty1 root=PARTUUID=fcf4cb94-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait/' cmdline.txt
        ```
        
    === "Manual"

        ```
        usb-storage.quirks=152d:1561:u console=serial0,115200 console=tty1 root=PARTUUID=fcf4cb94-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait
        ```

!!! abstract "`/boot/firmware/config.txt`"

    === "Automatic"
    
        ```shell
        echo program_usb_boot_mode=1 | sudo tee -a config.txt
        ```

    === "Manual"
    
        ```shell
        program_usb_boot_mode=1
        ```

!!! success "Check"

    ```shell
    mount | egrep "/([[:space:]]|boot)"
    ```

    ```shell
    vcgencmd otp_dump | grep 17
    ```

    ```shell
    17:1020000a=USB boot disabled
    17:3020000a=USB boot enabled
    ```

!!! code ""

    === "sudo"
    
        ```shell
        sudo raspi-config
        sudo rpi-update
        sudo raspi-config --expand-rootfs
        ```

    === "root"
    
        ```shell
        raspi-config
        rpi-update
        raspi-config --expand-rootfs
        ```

## :simple-proxmox: Proxmox

Setup [LVM][10] first

### Setup [Raspberry Pi OS][3].

!!! code "Create a tmp dir"

    ```shell
    cd "$(mktemp -d)"
    ```

!!! code "Download image"

    ```shell
    wget https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2024-11-19/2024-11-19-raspios-bookworm-arm64-lite.img.xz -O 2024-11-19-raspios-bookworm-arm64-lite.img.xz
    ```

!!! code "Extract image"

    ```shell
    xz -d 2024-11-19-raspios-bookworm-arm64-lite.img.xz
    ```

!!! code "Write image to SD card"

    ```shell
    dd if=2024-11-19-raspios-bookworm-arm64-lite.img /dev/mmcblk0 status=progress
    ```

!!! code "Mount boot partition"

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

### Proxmox Installation

!!! tip

    Alternatively, the [ISO][7] may be downloaded and installed as a removable media.

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

### :floppy_disk: Install Proxmox VE

##### :octicons-repo-24: Add the Proxmox VE repository

!!! abstract "/etc/apt/sources.list.d/pveport.list"

    === "Automatic"
    
        ```shell
        echo 'deb [arch=arm64] https://mirrors.apqa.cn/proxmox/debian/pve bookworm port'>/etc/apt/sources.list.d/pveport.list
        ```

    === "Manual"

        ```shell
        https://mirrors.apqa.cn/proxmox/debian/pve bookworm port
        ```

!!! code "Add the Proxmox VE repository key"

    ```shell
    curl -L https://mirrors.apqa.cn/proxmox/debian/pveport.gpg -o /etc/apt/trusted.gpg.d/pveport.gpg 
    ```

!!! code "Update repository and system"

    ```shell
    apt update && apt full-upgrade
    ```

!!! code "Install `ifupdown2` and Proxmox VE packages"

    ```shell
    apt install ifupdown2 proxmox-ve postfix open-iscsi
    ```

Configure packages which require user input on installation according to your needs (e.g. Samba asking about WINS/DHCP
support). If you have a mail server in your network, you should configure postfix as a satellite system, your existing
mail server will then be the relay host which will route the emails sent by the Proxmox server to their final
recipient.

If you don't know what to enter here, choose local only and leave the system name as is.

#### :computer: Reenable SSH

!!! abstract "/etc/ssh/sshd_config"

    === "Automatic"

        ```shell
        sudo sed -i 's/^#?\s*PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
        ```
        
    === "Manual "
    
        ```ini
        PermitRootLogin yes
        ```

Finally, you can connect to the admin web interface (`https://youripaddress:8006`).

### :material-network: Network

#### Missing `vmbr0`

!!! warning

    This should be done before reboot, else you won't be able to connect to the network!

!!! abstract "Create `vmbr0` network interface in GUI"

    ```yaml
    <node> -> Network -> Create
    Name: vmbr0
    IPv4: 192.168.1.192/24
    Gateweay: 192.168.1.1 
    Bridge Ports: eth0
    ```

!!! abstract "`/etc/network/interfaces`"

    ```ini
    auto lo
    iface lo inet loopback
    
    iface eth0 inet manual
    
    auto vmbr0
    iface vmbr0 inet static
            address 192.168.2.192/24
            gateway 192.168.2.1
            bridge-ports eth0
            bridge-stp off
            bridge-fd 0
    ```

Where `eth0` is the current existing network interface

## :x: [Repository 'http://deb.debian.org/debian buster InRelease' changed its 'Version' value from '' to '10.0' Error][5]

!!! code ""

    ``` shell
    apt --allow-releaseinfo-change update
    ```

## :material-script-text: [Proxmox VE Helper-Scripts][4]

!!! code ""

    ```shell
    (
      bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/update-repo.sh)" &&
      bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/post-pve-install.sh)"
    )
    ```

## :broom: Swap

See [Raspberry Pi 5 16GB][8].

## :material-fan: [Argon Fan Hat][9]

!!! code "Install"

    ```shell
    curl https://download.argon40.com/argonfanhat.sh | bash
    ```
!!! code "Uninstall"

    ```shell
    argonone-uninstall
    ```

!!! code "Config"

    ```shell
    argonone-config
    ```

### :gear: Config

1. Without the `ARGON FAN HAT` script the FAN will run constantly at 50% `FAN SPEED`
2. Upon installation of the script, `DEFAULT SETTINGS` of the `ARGON FAN HAT` are as follows:

| CPU TEMP | FAN SPEED / POWER |
|:-----:|:------------------------:|
| 55°C | 10 % |
| 60°C | 55 % |
| 65°C | 100 % |

### :electric_plug: Power Buttons

| ARGON FAN HAT | ACTION | FUNCTION |
|:-------------:|:------:|:--------:|
| OFF (FROM SOFT SHUTDOWN) | Short Press | Turn ON |
| ON | Short Press | Nothing |
| ON | Long Press (> 3 Secs) | Initiate Soft Shutdown (NO POWER CUT) |
| ON | Double Tap | Reboot |

## :link: References

- <https://github.com/jiangcuo/Proxmox-Port/wiki/Install-Proxmox-VE-on-Debian-bookworm>
- <https://mirrors.apqa.cn/proxmox/isos/>

[1]: <https://www.raspberrypi.com/products/raspberry-pi-4-model-b/>
[2]: <../apps/proxmox.md>
[3]: <https://www.raspberrypi.com/software/operating-systems/>
[4]: <https://community-scripts.github.io/ProxmoxVE/>
[5]: <https://www.reddit.com/r/debian/comments/ca3se6/for_people_who_gets_this_error_inrelease_changed/>
[6]: <https://www.makeuseof.com/how-to-boot-raspberry-pi-ssd-permanent-storage/>>
[7]: <https://mirrors.apqa.cn/proxmox/isos/>
[8]: <./rpi5.md>
[9]: <https://cdn.shopify.com/s/files/1/0556/1660/2177/files/Argon_Fan_Hat.pdf>
[10]: <../tools/lvm.md>
[11]: <https://jamesachambers.com/fixing-storage-adapters-for-raspberry-pi-via-firmware-updates/comment-page-1/>
[12]: <https://www.home-assistant.io/>
[13]: <./nuc.md>
[14]: <https://wiki.52pi.com/index.php?title=EP-0171>
[15]: <https://argon40.com/products/argon-fan-hat>
