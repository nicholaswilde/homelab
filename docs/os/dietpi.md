---
tags:
  - os
  - raspberry-pi
  - linux
---
# :simple-raspberrypi: DietPi

[DietPi][1] is used on my [Raspberry Pi 1](../../hardware/rpi1.md) and [Raspberry Pi Zero W](../../hardware/rpi0.md)

## :hammer_and_wrench: Installation

1. Download the image from [DietPi website][2].
2. Identify the SD card device using `lsblk`.

    ```shell
    lsblk
    ```

3. Write the image to the SD card. Replace `image.img.xz` with the path to your downloaded image and `/dev/sdX` with the device identifier of your SD card.

=== "root"

    ```shell
    xzcat image.img.xz | dd of=/dev/sdX status=progress
    ```

=== "sudo"

    ```shell
    xzcat image.img.xz | sudo dd of=/dev/sdX status=progress
    ```

4. Mount the boot partition (e.g., `/dev/sdX1`) and edit the configuration files.

!!! abstract "/boot/dietpi.txt"

    ```ini
    AUTO_SETUP_NET_WIFI_ENABLED=1
    ```

!!! abstract "/boot/dietpi-wifi.txt"

    ```ini
    aWIFI_SSID[0]='MyWifiName'
    aWIFI_KEY[0]='MySecretPassword'
    ```

## :gear: Config

```shell title="Add user"
adduser nicholas
usermod -aG sudo nicholas
su nicholas
```

!!! note "Enable Secure Copy Protocol (SCP)"
    These packages are installed to enable Secure Copy Protocol (SCP), allowing secure file transfers to and from the device. This is useful for managing files remotely.

```shell title="Enable SCP"
sudo apt install openssh-client openssh-sftp-server
```

!!! note "Disable DietPi Banner"
    The DietPi banner displays system information upon login. To disable it and show only a standard login prompt, create a `.hushlogin` file in the user's home directory.

```shell title="Disable Banner"
touch ~/.hushlogin
```

```shell title="Configure Banner"
dietpi-banner
```

```shell title="Config DietPi"
dietpi-config
```

!!! tip "Change Hostname"
    To change the hostname of your DietPi device, run `dietpi-config`, navigate to '2 Network Options' -> 'Hostname', and enter your desired hostname.

```shell title="Change Hostname"
dietpi-config
```

```shell title="Resize"
dietpi-drive_manager
```

### :zap: Overclocking

!!! warning "Risk of Hardware Damage"
    Overclocking may void your warranty and can shorten the life of your device. Ensure you have adequate cooling.

=== "Raspberry Pi Zero W"

    Add the following to `/boot/config.txt`:

    ```ini
    # already runs at 1000 by default when busy, this locks it high
    force_turbo=1
    over_voltage=2
    ```

=== "Raspberry Pi 1"

    Add the following to `/boot/config.txt`:

    ```ini
    arm_freq=900
    core_freq=400
    sdram_freq=450
    over_voltage=6
    ```

### :rocket: Kernel Tuning

Optimize the kernel for low-memory devices (Raspberry Pi 1, Zero, 2).

!!! abstract "/etc/sysctl.d/99-rpi-tuning.conf"

    ```ini
    vm.swappiness=100
    vm.vfs_cache_pressure=500
    vm.dirty_background_ratio=1
    vm.dirty_ratio=50
    ```

Apply the changes:

```shell
sudo sysctl --system
```

### :package: ZRAM Swap

Install `zram-swap` to improve performance on low-memory devices.

```shell
git clone https://github.com/foundObjects/zram-swap.git
cd zram-swap
sudo ./install.sh
```

## :pencil: Usage

## :rocket: Upgrade

!!! code ""

    === "Manual"

        ```shell
        dietpi-update
        ```

## [rpi-update](https://github.com/raspberrypi/rpi-update)

=== "apt"

    ```shell
    sudo apt install rpi-update
    ```

=== "Manual"

    ```shell
    sudo curl -L --output /usr/bin/rpi-update https://raw.githubusercontent.com/raspberrypi/rpi-update/master/rpi-update && sudo chmod +x /usr/bin/rpi-update
    ```

## :link: References

[1]: <https://dietpi.com/>
[2]: <https://dietpi.com/downloads/images/>
[3]: <https://github.com/foundObjects/zram-swap>