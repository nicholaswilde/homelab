---
tags:
  - home-assistant
  - rpi
  - arm64
---
# :simple-raspberrypi: Raspberry Pi 4 8GB

I recently converted my [Raspberry Pi 4 8GB][1] to run [Home Assistant][12] so that I can use my [NUC][13] as another
Proxmox node.

## :gear: Config

!!! example ""

    OS: [`Raspberry Pi OS Lite (64-bit)`][3]

    RAM: `8GB`

    HAT1: [`Argon Fan HAT for Raspberry Pi 4`][15]

    HAT2: [`GeeekPi M.2 NVME SSD Storage Expansion Board for Raspberry Pi 4 (52Pi EP-0171)`][14]

    DRIVE: `500GB NVMe`

    Hostname: `pi04`

    IP: `192.168.2.88`

    MAC: `dc:a6:32:ba:fa:eb`

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

## :zap: Speed Test

| Rank | Send Speed | Receive Speed | Verdict |
| :--- | :--- | :--- | :--- |
| #2 | 942 Mbps | 934 Mbps | The Underdog. A shocking perfect score. |

### :pencil: Usage

To test the network speed, use `iperf3`.

!!! code "Send"

    ```shell
    iperf3 -c 192.168.2.143
    ```

!!! code "Receive"

    ```shell
    iperf3 -c 192.168.2.143 -R
    ```

## :link: References

- <https://github.com/jiangcuo/Proxmox-Port/wiki/Install-Proxmox-VE-on-Debian-bookworm>
- <https://mirrors.apqa.cn/proxmox/isos/>

[1]: <https://www.raspberrypi.com/products/raspberry-pi-4-model-b/> 
[3]: <https://www.raspberrypi.com/software/operating-systems/> 
[6]: <https://www.makeuseof.com/how-to-boot-raspberry-pi-ssd-permanent-storage/>> 
[8]: <./rpi5.md> 
[9]: <https://cdn.shopify.com/s/files/1/0556/1660/2177/files/Argon_Fan_Hat.pdf> 
[11]: <https://jamesachambers.com/fixing-storage-adapters-for-raspberry-pi-via-firmware-updates/comment-page-1/> 
[12]: <https://github.com/nicholaswilde/home-assistant> 
[13]: <./nuc.md> 
[14]: <https://wiki.52pi.com/index.php?title=EP-0171> 
[15]: <https://argon40.com/products/argon-fan-hat>