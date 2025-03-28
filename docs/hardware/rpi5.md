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

## :simple-proxmox: Proxmox

See [Raspberry Pi 4 8GB][4].

## :broom: [Swap][8]

!!! success ""

    ```shell
    free -h
    ```

!!! code ""

    ```shell
    dphys-swapfile swapoff
    ```

!!! abstract "`/etc/dphys-swapfile`"

    ```ini
    CONF_SWAPSIZE=2048
    ```

!!! code ""

    ```shell
    dphys-swapfile setup
    dphys-swapfile swapon
    ```

!!! success ""

    ```shell
    free -h
    ```

## :floppy_disk: [LVM][9]

By default, Raspberry Pi OS does not come with LVM. However, LVM is useful for taking snapshots in Proxmox.

The main concept is as follows:

1. Create an SD card with a stock Raspberry Pi OS on a host system.
2. Install necessary packages on SD card.
3. Generate new `initramfs` on the Pi.
4. Backup the OS to a `tar` file from the host system.
5. Create file system on new NVMe drive.
6. Mount new file system drive.
7. Extract `tar` to new drive.
8. Modify boot on new drive.
9. Boot new drive.

### Equipment

The following equipment was used:

1. Raspberry Pi 5 with SD card and an NVMe hat.
2. Host computer with Ubuntu server installed that can read an SD card.
3. SD card.
4. 500GB NVMe.

!!! note

    My setup can only read NVMe drives from my Pi and so all of my interfacing with the NVMe is done while booted into
    the SD card on the Pi.

!!! note

    I have an nvme drive on my Pi, therefore my commnds below are with respect to `/dev/nvme0n1`

!!! note

    Most of the mounting of file systems is being done in the `/mnt` directory of both the Pi and host system.

### :computer: Host System

Install Raspberry Pi OS on an SD card.

### :credit_card: SD Card

Insert SD card into Pi and boot from SD card.

!!! code "Switch to `root`"

    ```shell
    sudo su
    ```
    
!!! code "Update the Pi"

    ```shell
    apt update
    apt full-upgrade
    ```

!!! code "Install `lvm2` and `initramfs-tools`"

    ```shell
    apt install initramfs-tools
    apt install lvm2 -y
    ```

!!! code "Update `initramfs`"

    ```shell
    update-initramfs -u -k all
    ```

!!! note

    Updating initramfs may not be needed because it may update itself during the `lvm2` installation.

!!! code "Shutown the Pi"

    ```shell
    poweroff
    ```

### :computer: Host System

Remove the SD card from the Pi and insert it back into the host system.

!!! code "Mount the SD card partitions and archive the contents to a `tar` file"

    ```shell
    sudo su
    cd /mnt
    mkdir -p rpi/boot/firmware
    mount /dev/nvme0n1p2 rpi
    mount /dev/nvme0n1p1 rpi/boot/firmware
    tar -cvzf rpi.tar.gz -C rpi ./
    umount /rpi/boot/firmware
    umount /rpi
    ```

The SD card is not archived into the `/mnt/rpi.tar.gz` file on the host system.

### :credit_card: SD Card

Insert SD card into Pi and boot from SD card.

Using `parted`, remove all partitions from the NVMe.  

!!! warning

    THIS DESTROYS ALL EXISTING DATA ON THE NVMe

!!! code

    ```shell
    sudo su
    parted /dev/nvme0n1
    ```

Identify the partition number: Once inside the parted interactive shell (you'll see a (parted) prompt), use the print command to list the partitions on the selected disk and find the number of the one you want to delete.

!!! code

    ```shell
    (parted) print
    ```

!!! code "Look at the output to identify the correct partition number (the first column)."

    ```shell
    (parted) rm 2
    ```

    ```shell
    (parted) rm 1
    ```

    ```shell
    (parted) quit
    ```

!!! success "Check that the partitions were deleted"

    ```shell
    lsblk
    ```

    ```shell
    ```
    
!!! code "Create a 500MB FAT32 partition and the remainder of the disk as an LVM partition"

    ```shell
    parted /dev/nvme0n1 mkpart primary fat32 2048s 512MiB
    parted /dev/nvme0n1 mkpart primary ext4 512MiB 100%
    parted /dev/nvme0n1 set 2 lvm on
    ```

!!! success "Check that the partitions were created successfully"

    ```shell
    lsblk
    ```

    ```shell
    ```

!!! code "Format and label the FAT partition"

    ```shell
    mkfs.fat -F 32 -n bootfs-rpi /dev/nvme0n1p1
    ```

!!! code "Setup LVM on the USB drive, create and format the root volume"

    ```shell
    pvcreate /dev/nvme0n1p2
    vgcreate usb-rpi /dev/nvme0n1p2
    lvcreate -L 30G -n rootfs usb-rpi
    mke2fs -t ext4 -L rootfs-rpi /dev/usb-rpi/rootfs
    ```

!!! code "Transfer the archived tar file from the host system using SCP"

    ```shell
    scp user@hostip:/mnt/rpi.tar.gz /mnt
    ```

!!! code "Mount the USB partitions and restore the contents"

    ```shell
    cd /mnt
    mkdir -p rpi/boot/firmware
    mount /dev/usb-rpi/rootfs rpi
    mount /dev/nvme0n1p1 rpi/boot/firmware
    tar -xvzf rpi.tar.gz -C rpi
    ```

!!! success "Check that the contents transferred successfully"

    ```shell
    ls rpi
    ```

    ```shell
    ```

!!! code "List modules"

    ```shell
    ls rpi/etc/modules
    ```

    ```shell
    4.19.97+  4.19.97-v7+  4.19.97-v7l+  4.19.97-v8+
    ```

!!! abstract "Update `rpi/boot/firmware/config.txt`"

    ```ini
    [pi4]
    initramfs initrd.img-4.19.97-v7l+ followkernel
    ```

!!! abstract "`rpi/etc/fstab`"

    === "Manual"
    
        ```ini
        LABEL=rootfs-rpi  /
        LABEL=bootfs-rpi  /boot/firmware
        ```

!!! abstract "`rpi/boot/firmware/cmdline.txt`"

    === "Manual"
    
        ```ini
        root=LABEL=rootfs-rpi
        ```

!!! code "Unmount the partitions"

    ```shell
    umount rpi/boot/firmware
    umount rpi
    rmdir rpi
    ```

Optionally use `raspi-config` to set the boot order to be USB drive first.

----



2. Safely eject (NOTE:  You shouldn't need to deactivate the LVM volumes to safely eject).


!!! code "Activate LVM volume group"

    ```shell
    vgchange -ay
    ```

!!! code

    ```shell
    foo@pi23:/wrk $ cat sdlvm
    #!/bin/false

    #umount /mnt/dev/p2
    #umount /mnt/dev/p1
    #vgremove $(hostname)
    #pvremove "$1""2"

    which pvs || exit 1
    [ -z "$1" ] && exit 1

    E=echo
    #chk and umount /dev/media/*
    $E vgchange -an -y $(hostname)
    $E vgremove -y $(hostname)
    $E pvremove "$1""2"

    $E parted -s "$1" mklabel gpt || exit 1
    $E parted -s "$1" mkpart primary 4M 516M || exit 1
    $E parted -s "$1" mkpart primary 516M 64G || exit 1
    $E parted -s "$1" name 1 bootfs || exit 1
    $E parted -s "$1" name 2 rootfs || exit 1
    $E parted -s "$1" set 1 boot on || exit 1
    $E parted -s "$1" set 2 lvm on || exit 1
    $E pvcreate "$1""2"  || exit 1
    $E vgcreate $(hostname) "$1""2" || exit 1
    $E lvcreate -y -n rootfs -l 100%FREE $(hostname) || exit 1
    $E mkfs.vfat "$1""1" || exit 1
    $E mkfs.ext4 "/dev/"$(hostname)"/rootfs" || exit 1
    $E mkdir -p /mnt/dev/p{1,2} || exit 1
    $E mount "$1""1" /mnt/dev/p1 || exit 1
    $E mount "/dev/"$(hostname)"/rootfs" /mnt/dev/p2 || exit 1
    $E update-initramfs -u -k all
    $E DRY=" " sys-rbackup /boot/firmware/ /mnt/dev/p1/ || exit 1
    $E DRY=" " sys-rbackup / /mnt/dev/p2/ || exit 1
    $E sed -i -e "s,root=[^[:space:]]*,root=/dev/mapper/$(hostname)-rootfs," /mnt/dev/p1/cmdline.txt || exit 1
    $E sed -i -e "s,PART.*=.*-01[^[:space:]]*,PARTLABEL=bootfs," /mnt/dev/p2/etc/fstab || exit 1
    $E sed -i -e "s,PART.*=.*-02[^[:space:]]*,/dev/mapper/$(hostname)-rootfs," /mnt/dev/p2/etc/fstab || exit 1

    $E cat /mnt/dev/p2/etc/fstab
    $E umount /mnt/dev/p2 || exit 1
    $E cat /mnt/dev/p1/cmdline.txt
    $E umount /mnt/dev/p1 || exit 1
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
[9]: <https://forums.raspberrypi.com/viewtopic.php?t=366552>
