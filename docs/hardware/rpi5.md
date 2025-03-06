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

!!! quote ""

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

!!! quote ""

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

## :simple-proxmox: Proxmox

See [Raspberry Pi 4 8GB][4].

## :broom: [Swap][8]

!!! success ""

    ```shell
    free -h
    ```

!!! quote ""

    ```shell
    dphys-swapfile swapoff
    ```

!!! abstract "`/etc/dphys-swapfile`"

    ```ini
    CONF_SWAPSIZE=2048
    ```

!!! quote ""

    ```shell
    dphys-swapfile setup
    dphys-swapfile swapon
    ```

!!! success ""

    ```shell
    free -h
    ```

## :link: References

  - <https://a.co/d/etvDazc>

[1]: <../apps/adguard.md>
[2]: <https://www.raspberrypi.com/software/>
[3]: <https://www.raspberrypi.com/products/raspberry-pi-5/>
[4]: <./rpi4.md>
[5]: <https://www.amazon.com/dp/B0CRK4YB4C>
[6]: <https://www.amazon.com/dp/B0B25LQQPC>
[7]: <https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#PSU_MAX_CURRENT>
[8]: <https://forums.raspberrypi.com/viewtopic.php?t=46472>
