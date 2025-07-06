---
tags:
  - rpi
  - proxmox
  - arm64
---
# :simple-raspberrypi: Raspberry Pi 5 16GB

My [Raspberry Pi 5 16GB][3] is being used as another `arm64` Proxmox server.

## :gear: Config

!!! example ""

    OS: [`Rasbperry Pi OS Lite (64-bit)`][2]
    
    RAM: `16GB`

    HAT1: [`Raspberry Pi Active Cooler`][14]

    HAT2: [`GeeekPi N04 M.2 NVMe to PCIe Adapter`][5]

    DRIVE: [`Crucial P3 500GB PCIe Gen3 3D NAND NVMe M.2 SSD`][6]

### :pager: Enable PCIe

!!! tip

    When connecting the PCIe adapter to the pi, ensure that the correct end of the ribbon cable is being plugged into the correct connector.
    Typically, the ribbon cable ends are labeled.

!!! abstract "/boot/firmware/config.txt"

    === "Automatic Gen 3.0"
    
        ```shell
        echo "dtparam=pciex1_gen=3" | sudo tee -a config.txt
        ```

    === "Automatic Gen 2.0"
    
        ```shell
        echo "dtparam=pciex1" | sudo tee -a config.txt
        ```
  
    === "Manual Gen 3.0"

        ```shell
        dtparam=pciex1_gen=3
        ```
        
    === "Manual Gen 2.0"

        ```shell
        dtparam=pciex1
        ```

### :detective: Enable auto detection PCIe and booting from NVMe

!!! code ""

    === "root"

        ```shell
        rpi-eeprom-config --edit
        ```

    === "sudo"
    
        ```shell
        sudo rpi-eeprom-config --edit
        ```

!!! abstract ""

    ```env
    PCIE_PROBE=1

    BOOT_ORDER=0xf416
    ```

The 6 means to enable booting from nvme. Reboot Raspberry Pi 5 and try to use `lsblk` or `lspci -vvv` to get more details of the PCIe device.

### :electric_plug: [Enable 5A PSU][7]

If `apt` is slow, it might be due to the pi reducing the power input.

!!! code ""

    === "root"
    
        ```shell
        rpi-eeprom-config --edit
        ```
        
    === "sudo"
    
        ```shell
        sudo rpi-eeprom-config --edit
        ```

!!! abstract ""

    ```env
    PSU_MAX_CURRENT=5000
    ```

### :tv: [Set Resolution][12]

When using a TV as a temporary monitor, usually when troubleshooting the booting from a USB or NVMe drive, the text size can be way too small.
This is how to change the resolution on boot of the command line so that it can be read more easily on the TV.

!!! warning

    This does not seem to work for the Raspberry Pi 4 for some reason. Perhaps it's the display port mapping?

!!! abstract "`/boot/firmware/cmdline.txt`"

    === "Automatic"

        ```env
        sed -i `1s/$/ video=HDMI-A-1:1920x1080M@60D/' /boot/firmware/cmdline.txt
        ```

    === "Manual"

        ```env
        video=HDMI-A-1:1920x1080M@60D
        ```

## :simple-proxmox: Proxmox

Setup [LVM][9] first

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

    Alternatively, the [ISO][13] may be downloaded and installed as a removable media.

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

!!! warning

    Proxmox-Port has now been replaced by [PXVIRT][15]! The information below may be out of date!

##### :octicons-repo-24: Add the Proxmox VE repository

!!! abstract "/etc/apt/sources.list.d/pveport.list"

    === "Automatic"
    
        ```shell
        echo 'deb https://download.lierfang.com/pxcloud/pxvirt bookworm main'>/etc/apt/sources.list.d/pxvirt.list
        ```

    === "Manual"

        ```shell title="/etc/apt/sources.list.d/pxvirt.list"
        deb https://download.lierfang.com/pxcloud/pxvirt bookworm main
        ```

!!! code "Add the Proxmox VE repository key"

    ```shell
    curl -L https://mirrors.lierfang.com/proxmox/debian/pveport.gpg -o /etc/apt/trusted.gpg.d/pveport.gpg 
    ```

!!! code "Update repository and system"

    ```shell
    apt update && apt full-upgrade
    ```

!!! code "Install `ifupdown2` and Proxmox VE packages"

    ```shell
    apt install --allow-downgrades -y ifupdown2 pxvirt pve-manager=8.3.5-1+port2 qemu-server=8.3.8+port5 postfix open-iscsi
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

## :x: [Repository 'http://deb.debian.org/debian buster InRelease' changed its 'Version' value from '' to '10.0' Error][11]

!!! code ""

    ``` shell
    apt --allow-releaseinfo-change update
    ```

## :material-script-text: [Proxmox VE Helper-Scripts][10]

!!! code ""

    ```shell
    (
      bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/update-repo.sh)" &&
      bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/post-pve-install.sh)"
    )
    ```

## :broom: [Swap][8]

The Raspberry Pi uses [`dphys-swapfile`][1] to manage it's swap.

For Proxmox, I'm using a [logical volume][9] instead of a swap file.

### :straight_ruler: Change Swap Size

!!! success "Check the free space"

    ```shell
    free -h
    ```

!!! code "Turn of swap"

    ```shell
    dphys-swapfile swapoff
    ```

!!! abstract "Update size in `/etc/dphys-swapfile`"

    ```ini
    CONF_SWAPSIZE=2048
    ```

!!! code "Resetup swap and turn it back on"

    ```shell
    (
      dphys-swapfile setup
      dphys-swapfile swapon
    )
    ```

!!! success "Check for the new size"

    ```shell
    free -h
    ```

### :no_entry_sign: Disable Permanently

!!! code "Disable dphys-swapfile temporarily"

    ```shell
    dphys-swapfile swapoff
    ```

!!! code "Stop the service"

    ```shell
    systemctl stop dphys-swapfile
    ```

!!! code "Disable the service"

    ```shell
    systemctl disable dphys-swapfile
    ```

!!! code "Remove the swap file to save disk space"

    ```shell
    rm /var/swap
    ```

## :floppy_disk: LVM

See [LVM](../tools/lvm.md).

## :link: References

  - <https://a.co/d/etvDazc>

[1]: <https://packages.debian.org/buster/dphys-swapfile>
[2]: <https://www.raspberrypi.com/software/>
[3]: <https://www.raspberrypi.com/products/raspberry-pi-5/>
[4]: <./rpi4.md>
[5]: <https://www.amazon.com/dp/B0CRK4YB4C>
[6]: <https://www.amazon.com/dp/B0B25LQQPC>
[7]: <https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#PSU_MAX_CURRENT>
[8]: <https://forums.raspberrypi.com/viewtopic.php?t=46472>
[9]: <../tools/lvm.md#swap>
[12]: <https://forums.raspberrypi.com/viewtopic.php?t=359643>

[10]: <https://community-scripts.github.io/ProxmoxVE/> 
[11]: <https://www.reddit.com/r/debian/comments/ca3se6/for_people_who_gets_this_error_inrelease_changed/> 
[13]: <https://mirrors.apqa.cn/proxmox/isos/> 
[14]: <https://www.raspberrypi.com/products/active-cooler/>
[15]: <https://github.com/jiangcuo/pxvirt>

<!-- [1]: <https://www.raspberrypi.com/products/raspberry-pi-4-model-b/> -->
<!-- [2]: <../apps/proxmox.md> -->
<!-- [3]: <https://www.raspberrypi.com/software/operating-systems/> -->
<!-- [6]: <https://www.makeuseof.com/how-to-boot-raspberry-pi-ssd-permanent-storage/>> -->
<!-- [8]: <./rpi5.md> -->
<!-- [9]: <https://cdn.shopify.com/s/files/1/0556/1660/2177/files/Argon_Fan_Hat.pdf> -->
<!-- [10]: <../tools/lvm.md> -->
<!-- [11]: <https://jamesachambers.com/fixing-storage-adapters-for-raspberry-pi-via-firmware-updates/comment-page-1/> -->
<!-- [12]: <https://www.home-assistant.io/> -->
<!-- [13]: <./nuc.md> -->
<!-- [14]: <https://wiki.52pi.com/index.php?title=EP-0171> -->
<!-- [15]: <https://argon40.com/products/argon-fan-hat> -->
