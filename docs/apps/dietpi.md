# DietPi

[DietPi][1] is used on my Raspberry Pi 1 and Raspberry Pi Zero W

## Installation

!!! abstract "/boot/dietpi.txt"

    ```ini
    AUTO_SETUP_NET_WIFI_ENABLED=1
    ```

!!! abstract "/boot/dietpi-wifi.txt"

    ```ini
    aWIFI_SSID[0]='MyWifiName'
    aWIFI_KEY[0]='MySecretPassword'
    ```

## Config

```shell title="Add user"
adduser nicholas
usermod -aG sudo nicholas
su nicholas
```

```shell title="Enable SCP"
sudo apt install openssh-client openssh-sftp-server
```

```shell title="Banner"
dietpi-banner
```

```shell title="Config DietPi"
dietpi-config
```

```shell title="Resize"
dietpi-drive_manager
```

## Usage

## :link: References

[1]: <https://dietpi.com/>
