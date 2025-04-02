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

    HAT: [`GeeekPi N04 M.2 NVMe to PCIe Adapter`][5]

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

See [Raspberry Pi 4 8GB][4].

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
