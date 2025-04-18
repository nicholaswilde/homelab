---
tags:
  - proxmox
  - rpi
  - rpi4
  - rpi5
---
# :floppy_disk: [LVM][9]

By default, Raspberry Pi OS does not come with [LVM][13]. However, LVM is useful for taking snapshots in Proxmox.

## :gear: Setup

The main setup concept is as follows:

1. Create an SD card with a stock Raspberry Pi OS on a host system.
2. Install necessary packages on SD card.
3. Generate new `initramfs` on the Pi.
4. Backup the OS to a `tar` file from the host system.
5. Create file system on new NVMe drive.
6. Mount new file system drive.
7. Extract `tar` to new drive.
8. Modify boot on new drive.
9. Boot new drive.

### :toolbox: Equipment

The following equipment was used:

1. Raspberry Pi 5 with SD card and an NVMe hat.
2. Host computer with Ubuntu server installed that can read an SD card.
3. SD card.
4. 500GB NVMe.

!!! note

    My setup can only read NVMe drives from my Pi and so all of my interfacing with the NVMe is done while booted into
    the SD card on the Pi.

!!! note

    I have an NVMe drive on my Pi, therefore my commnds below are with respect to `/dev/nvme0n1` when working with it.

!!! note

    When working with my SD card mounted on my host system, the drive location is `/dev/mmcblk0`

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
    (
      apt update
      apt full-upgrade
    )
    ```

!!! code "Install `lvm2` and `initramfs-tools`"

    ```shell
    (
      apt install initramfs-tools
      apt install lvm2 -y
    )
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

!!! code "Switch to `root`"

    ```shell
    sudo su
    ```

!!! code "Get the `/dev` drive location"

    ```shell
    lsblk
    ```

    ```shell title="Output"
    NAME         MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
    mmcblk0      179:0    0 119.1G  0 disk 
    ├─mmcblk0p1  179:1    0   512M  0 part /boot/firmware
    └─mmcblk0p2  179:2    0 118.6G  0 part /
    nvme0n1      259:0    0 465.8G  0 disk
    ```

!!! code "Set the drive location"

    ```shell
    DRIVE=mmcblk0p
    ```

!!! note

    The `p` needs to be added to the end of the drive if using an SD card or NVMe drive.

!!! code "Mount the SD card partitions and archive the contents to a `tar` file"

    ```shell
    (
      cd /mnt
      mount /dev/${DRIVE}2 ./rpi
      mkdir -p rpi/boot/firmware
      mount /dev/${DRIVE}1 ./rpi/boot/firmware
      tar -cvzf rpi.tar.gz -C rpi ./
      umount ./rpi/boot/firmware
      umount ./rpi
    )
    ```

The SD card is not archived into the `/mnt/rpi.tar.gz` file on the host system.

!!! success "Check the `tar` file before using it"

    ```shell
    tar -tvf /mnt/rpi.tar.gz
    ```

### :credit_card: SD Card

Insert SD card into Pi and boot from SD card.

Using `parted`, remove all partitions from the NVMe.  

!!! warning

    THIS DESTROYS ALL EXISTING DATA ON THE NVMe

!!! code "Switch to `root`"

    ```shell
    sudo su
    ```

!!! code "Set the drive location"

    ```shell
    DRIVE=nvme0n1p
    ```

!!! note

    The `p` needs to be added to the end of the drive if using an SD card or NVMe drive.

!!! code

    ```shell
    parted /dev/${DRIVE%p}
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

    ```shell title="Output"
    NAME         MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
    mmcblk0      179:0    0 119.1G  0 disk 
    ├─mmcblk0p1  179:1    0   512M  0 part /boot/firmware
    └─mmcblk0p2  179:2    0 118.6G  0 part /
    nvme0n1      259:0    0 465.8G  0 disk 
    ```

!!! code "Create a 500MB FAT32 partition and the remainder of the disk as an LVM partition"

    ```shell
    (
      parted /dev/${DRIVE%p} mkpart primary fat32 2048s 512MiB && \
      parted /dev/${DRIVE%p} mkpart primary ext4 512MiB 100% && \
      parted /dev/${DRIVE%p} set 2 lvm on
    )
    ```

!!! success "Check that the partitions were created successfully"

    ```shell
    lsblk
    ```

    ```shell title="Output"
    NAME         MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
    mmcblk0      179:0    0 119.1G  0 disk 
    ├─mmcblk0p1  179:1    0   512M  0 part /boot/firmware
    └─mmcblk0p2  179:2    0 118.6G  0 part /
    nvme0n1      259:0    0 465.8G  0 disk 
    ├─nvme0n1p1  259:1    0   511M  0 part 
    └─nvme0n1p2  259:2    0 465.3G  0 part
    ```

!!! code "Format and label the FAT partition"

    ```shell
    mkfs.fat -F 32 -n bootfs-rpi /dev/${DRIVE}1
    ```

!!! code "Setup LVM on the NVMe drive, create and format the root volume"

    ```shell
    (
      pvcreate /dev/${DRIVE}2 && \
      vgcreate pve /dev/${DRIVE}2 && \
      lvcreate -L 70G -n root pve && \
      mke2fs -t ext4 -L pve /dev/pve/root
    )
    ```

!!! success "Check that the volumes were created successfully"

    ```shell
    lsblk
    ```

    ```shell title="Output"
    NAME         MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
    mmcblk0      179:0    0 119.1G  0 disk 
    ├─mmcblk0p1  179:1    0   512M  0 part /boot/firmware
    └─mmcblk0p2  179:2    0 118.6G  0 part /
    nvme0n1      259:0    0 465.8G  0 disk 
    ├─nvme0n1p1  259:1    0   511M  0 part 
    └─nvme0n1p2  259:2    0 465.3G  0 part 
      └─pve-root 254:0    0    30G  0 lvm
    ```

!!! code "Transfer the archived tar file from the host system using SCP"

    ```shell
    scp user@hostip:/mnt/rpi.tar.gz /mnt
    ```

!!! code "Mount the USB partitions and restore the contents"

    ```shell
    (
      cd /mnt && \
      mkdir -p ./rpi/boot/firmware && \
      mount /dev/pve/root rpi && \
      mount /dev/${DRIVE}1 ./rpi/boot/firmware && \
      tar -xvzf rpi.tar.gz -C ./rpi
    )
    ```

!!! success "Check that the contents transferred successfully"

    ```shell
    ls rpi
    ```

    ```shell title="Output"
    bin  boot  dev  etc  home  lib  lost+found  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
    ```

!!! note

    Don't seem to need to change `config.txt` with `initramfs`.

!!! abstract "`./rpi/etc/fstab`"

    === "Automatic"

        ```shell
        (
          sed -i 's/^PARTUUID=[a-z0-9]*-01/\/dev\/'"${DRIVE}"'1/' /mnt/rpi/etc/fstab && \
          sed -i 's/^PARTUUID=[a-z0-9]*-02/\/dev\/pve\/root/' /mnt/rpi/etc/fstab && \
          cat /mnt/rpi/etc/fstab
        )
        ```

    === "Manual"

        ```ini
        proc            /proc           proc    defaults          0       0
        /dev/nvme0n1p1  /boot/firmware  vfat    defaults          0       2
        /dev/pve/root  /               ext4    defaults,noatime  0       1
        ```

!!! abstract "`./rpi/boot/firmware/cmdline.txt`"

    === "Automatic"

        ```shell
        (
          sed -i 's/root=PARTUUID=[a-z0-9]*-02/root=\/dev\/pve\/root/' /mnt/rpi/boot/firmware/cmdline.txt && \
          cat /mnt/rpi/boot/firmware/cmdline.txt
        )
        ```

    === "Manual"

        ```ini
        console=serial0,115200 console=tty1 root=/dev/pve/root rootfstype=ext4 fsck.repair=yes rootwait cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1
        ```

!!! code "Unmount the partitions"

    ```shell
    (
      cd /mnt && \
      umount ./rpi/boot/firmware/ && \
      umount ./rpi/ && \
      rm -r rpi/
    )
    ```

Reboot and hold the `spacebar` to get to the boot menu. Choose `6` for NVMe.

!!! success "Verify that it's booting from the NVMe"

    ```shell
    lsblk
    ```

    ```shell title="Output"
    NAME         MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
    mmcblk0      179:0    0 119.1G  0 disk 
    ├─mmcblk0p1  179:1    0   512M  0 part 
    └─mmcblk0p2  179:2    0 118.6G  0 part 
    nvme0n1      259:0    0 465.8G  0 disk 
    ├─nvme0n1p1  259:1    0   511M  0 part /boot/firmware
    └─nvme0n1p2  259:2    0 465.3G  0 part 
      ├─pve-swap 254:0    0     8G  0 lvm  
      └─pve-root 254:1    0    70G  0 lvm  /
    ```

If successful, use `raspi-config` to set the boot order to be NVMe drive first.

## :broom: [Swap][10]

This sets up a logical volume for swap instead of using the default Raspberry Pi OS file swap.

Disable `dphys-swapfile` [file swap][14].

!!! code "Create the LVM2 logical volume of 8GB"

    ```shell
    lvm lvcreate pve -n swap -L 8G
    ```

!!! code "Format the new swap space"

    ```shell
    mkswap /dev/pve/swap
    ```

!!! success "Check that the volume was created"

    ```shell
    lvdisplay
    ```

    ```shell title="Output"
      --- Logical volume ---
      LV Path                /dev/pve/swap
      LV Name                swap
      VG Name                pve
      LV UUID                Gb7n93-OBv9-YtPu-vz7K-GeXK-G5fY-W2QQ3T
      LV Write Access        read/write
      LV Creation host, time raspberrypi, 2025-03-30 05:11:22 +0100
      LV Status              available
      # open                 0
      LV Size                8.00 GiB
      Current LE             2048
      Segments               1
      Allocation             inherit
      Read ahead sectors     auto
      - currently set to     256
      Block device           254:0    
    ```

!!! abstract "`/etc/fstab`"

    === "Manual"

        ```ini
         /dev/pve/swap swap swap defaults 0 0 
        ```

!!! code "Enable the extended logical volume"

    ```shell
    swapon -va
    ```

!!! success "Test that the swap has been extended properly"

    ```shell
    cat /proc/swaps # free
    ```

    ```shell title="Output"
    Filename                                Type            Size            Used            Priority
    /dev/dm-0                               partition       8388592         0               -2
    ```

## :pinching_hand: [LVM Thin][11]

Create an LVM thin pool which allocates blocks when they are written, thereby saving disk space.

!!! code

    ```shell
    (
      lvcreate -L 100G -n data pve && \
      lvconvert --type thin-pool pve/data
    )
    ```

??? abstract "`/etc/pve/storage.cfg`"

    ```ini
    lvmthin: local-lvm
             thinpool data
             vgname pve
             content rootdir,images
    ```

## :stethoscope: Troubleshooting

!!! code "Activate LVM volume group"

    ```shell
    vgchange -ay
    ```

??? code

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

- <https://github.com/MikeJansen/rpi-boot-lvm>
- <https://raspberrypi.stackexchange.com/questions/85958/easy-backups-and-snapshots-of-a-running-system-with-lvm>

[1]: <../apps/adguard.md>
[2]: <https://www.raspberrypi.com/software/>
[3]: <https://www.raspberrypi.com/products/raspberry-pi-5/>
[4]: <./rpi4.md>
[5]: <https://www.amazon.com/dp/B0CRK4YB4C>
[6]: <https://www.amazon.com/dp/B0B25LQQPC>
[7]: <https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#PSU_MAX_CURRENT>
[8]: <https://forums.raspberrypi.com/viewtopic.php?t=46472>
[9]: <https://forums.raspberrypi.com/viewtopic.php?t=366552>
[10]: <https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/4/html/system_administration_guide/adding_swap_space-creating_an_lvm2_logical_volume_for_swap#Adding_Swap_Space-Creating_an_LVM2_Logical_Volume_for_Swap>
[11]: <https://pve.proxmox.com/wiki/Storage:_LVM_Thin>
[12]: <https://forums.raspberrypi.com/viewtopic.php?t=359643>
[13]: <https://en.wikipedia.org/wiki/Logical_volume_management>
[14]: <../hardware/rpi5.md#disable-permanently>
