---
tags:
  - proxmox
  - rpi
---
# :simple-raspberrypi: Raspberry Pi 4 8GB

I use my [Raspberry Pi 4 8GB][1] as another [Proxmox][2] server.

### :clipboard: TL;DR

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

    HAT: `none`

    DRIVE: `USB 500GB SSD`

### :material-usb-flash-drive: [Raspberry Pi 4 boot from usb][6]

!!! quote ""

    ```shell
    sudo raspi-config
    ```

    ```
    Advanced Options -> Boot Order -> B2 NVMe/USB
    ```

    ```shell
    sudo reboot
    ```

    ```shell title="Get vendorId and deviceId"
    dmesg
    ```

!!! abstract "/boot/firmware/cmdline.txt"

    === "Manual"

        ```
        usb-storage.quirks=152d:1561:u console=serial0,115200 console=tty1 root=PARTUUID=fcf4cb94-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait
        ```

!!! abstract "/boot/firmware/config.txt"

    === "Automatic"
    
        ```shell
        echo program_usb_boot_mode=1 | sudo tee -a /boot/firmware/config.txt
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

!!! quote ""

    ```shell
    sudo raspi-config
    sudo rpi-update
    sudo raspi-config --expand-rootfs
    ```

## :simple-proxmox: Proxmox

### Setup [Raspberry Pi OS][3].

```shell title="Create a tmp dir"
cd "$(mktemp -d)"
```

```shell title="Download image"
wget https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2024-11-19/2024-11-19-raspios-bookworm-arm64-lite.img.xz -O 2024-11-19-raspios-bookworm-arm64-lite.img.xz
```

```shell title="Extract image"
xz -d 2024-11-19-raspios-bookworm-arm64-lite.img.xz
```

```shell title="Write image to SD card"
dd if=2024-11-19-raspios-bookworm-arm64-lite.img /dev/mmcblk0 status=progress
```

```shell title="Mount boot partition"
(
  [ -d /media/sd ] || mkdir /media/sd
  sudo mount -a /dev/mmcblk0p1 /media/sd
)
```

```shell title="Change to boot partition"
cd /media/sd
```

### Create Username & Password

!!! abstract "/boot/firmware/userconf.txt"

    === "Automatic"
    
        ```shell
        echo 'nicholas:' "$(openssl passwd -6)" | sed 's/ //g' | sudo tee -a userconf.txt
        ```

    === "Manual"

        ```shell
        nicholas:<hash>
        ```

### Enable SSH

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

Log into the Raspberry Pi using SSH.

Switch to `root` user. Default password is blank for Raspberry Pi OS.

```shell
sudo su root
```

Set root password so that you can log into Proxmox web GUI.

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

```shell title="Get IP address"
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

You can test if your setup is ok using the hostname command:

```shell
hostname --ip-address
```

```shell
192.168.1.192 # should return your IP address here
```

### :floppy_disk: Install Proxmox VE

##### :octicons-repo-24: Add the Proxmox VE repository:

!!! abstract "/etc/apt/sources.list.d/pveport.list"

    === "Automatic"
    
        ```shell
        echo 'deb [arch=arm64] https://mirrors.apqa.cn/proxmox/debian/pve bookworm port'>/etc/apt/sources.list.d/pveport.list
        ```

    === "Manual"

        ```shell
        https://mirrors.apqa.cn/proxmox/debian/pve bookworm port
        ```

Add the Proxmox VE repository key:

```shell
curl -L https://mirrors.apqa.cn/proxmox/debian/pveport.gpg -o /etc/apt/trusted.gpg.d/pveport.gpg 
```

Update your repository and system by running:

```shell
apt update && apt full-upgrade
```

Install Proxmox VE packages
Install the ifupdown2 packages

```shell
apt install ifupdown2
```

Install the Proxmox VE packages

```shell
apt install proxmox-ve postfix open-iscsi
```

Configure packages which require user input on installation according to your needs (e.g. Samba asking about WINS/DHCP
support). If you have a mail server in your network, you should configure postfix as a satellite system, your existing
mail server will then be the relay host which will route the emails sent by the Proxmox server to their final
recipient.

If you don't know what to enter here, choose local only and leave the system name as is.

Reenable ssh.


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

Create `vmbr0` network interface in GUI

```yaml
<node> -> Network -> Create
Name: vmbr0
IPv4: 192.168.1.192/24
Gateweay: 192.168.1.1 
Bridge Ports: eth0
```

Where `eth0` is the current existing network interface

## [Repository 'http://deb.debian.org/debian buster InRelease' changed its 'Version' value from '' to '10.0' Error][5]

``` shell
apt-get --allow-releaseinfo-change update
```

### :material-script-text: [Proxmox VE Helper-Scripts][4]

```shell
(
  bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/update-repo.sh)" &&
  bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/post-pve-install.sh)"
)
```

## :link: References

- <https://github.com/jiangcuo/Proxmox-Port/wiki/Install-Proxmox-VE-on-Debian-bookworm>

[1]: <https://www.raspberrypi.com/products/raspberry-pi-4-model-b/>
[3]: <https://www.raspberrypi.com/software/operating-systems/>
[2]: <../apps/proxmox.md>
[4]: <https://community-scripts.github.io/ProxmoxVE/>
[5]: <https://www.reddit.com/r/debian/comments/ca3se6/for_people_who_gets_this_error_inrelease_changed/>
[6]: <https://www.makeuseof.com/how-to-boot-raspberry-pi-ssd-permanent-storage/>>
