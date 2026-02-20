---
tags:
  - reference
  - linux
---
# :scroll: Cheatsheet

A collection of useful commands and tips.

## :computer: Hardware

### :zap: PCIe Speed

To check the PCIe generation and speed of devices:

1.  **Identify the Device:**
    Find the device's Bus, Device, and Function numbers (e.g., `01:00.0`).

    ```shell
    lspci
    ```

2.  **Get Detailed Information:**
    Use the identifier to query the device.

    ```shell
    sudo lspci -s 01:00.0 -vvv | grep -i "LnkCap\|LnkSta"
    ```

    *   `LnkCap`: Maximum supported speed and width.
    *   `LnkSta`: Current operating speed and width.

3.  **Interpret Output:**
    *   2.5 GT/s = PCIe Gen 1
    *   5 GT/s = PCIe Gen 2
    *   8 GT/s = PCIe Gen 3
    *   16 GT/s = PCIe Gen 4
    *   Width (e.g., x16, x4) indicates lane count.

### :floppy_disk: Boot Device

Identify the device the system booted from.

```shell
lsblk -no pkname $(findmnt -n / | awk '{ print $2 }')
```

### :electric_plug: Reset USB Subsystem

Sometimes a USB device gets stuck and needs a reset without rebooting.

1.  **Identify the Controller:**
    List USB controllers and find the one you need to reset.

    ```shell
    lspci | grep USB
    ```

    Note the ID (e.g., `00:14.0`).

2.  **Reset:**
    Unbind and rebind the driver. Replace `0000:00:14.0` with your controller's full ID.

    ```shell
    echo -n "0000:00:14.0" | sudo tee /sys/bus/pci/drivers/xhci_hcd/unbind
    echo -n "0000:00:14.0" | sudo tee /sys/bus/pci/drivers/xhci_hcd/bind
    ```

### :computer: BIOS Version

Check the BIOS version.

```shell
sudo dmidecode -s bios-version
```

## :link: References

- [AskUbuntu: BIOS Update](https://askubuntu.com/a/1094838)
- [SuperUser: Boot device](https://superuser.com/a/1602237/352242)
- [Zedt: Reset USB](https://zedt.eu/tech/linux/restarting-usb-subsystem-centos/)