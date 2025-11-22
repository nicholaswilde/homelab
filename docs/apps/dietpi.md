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

    ```shell
    xzcat image.img.xz | sudo dd of=/dev/sdX bs=4M status=progress
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

## :pencil: Usage

## :rocket: Upgrade

!!! code ""

    === "Manual"

        ```shell
        dietpi-update
        ```

## :link: References

[1]: <https://dietpi.com/>
[2]: <https://dietpi.com/downloads/images/>
