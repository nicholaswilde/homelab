---
tags:
  - hardware
---
# :frame_with_picture: Digital Picture Frame

I have a [NIX Advance 8 Inch USB Digital Photo Frame][1] that does not have wireless communication.

## :frame_with_picture: Background

The issue is workflow for updating the memory card or USB thumb drive with pictures is a bit manual and clunky. I want
to automate the process a little bit more.

### :clipboard: Current Process

1. Create a `Digital Picture Frame` album in [Google Photos][2] (manual).
2. Add desired photos to album (manual).
3. [Download album][3] as zip file via web interface on Chromebook (manual).
4. Transfer zip file to LXC (manual).
5. Use the [`heic-extract.sh` script](#heic-converter-script) to extract zip file, convert `HEIC` files to `jpg`, and delete `MP4` files (auto).
6. Format SD card as `FAT32` (optional) (manual).
7. Transfer `png` and `jpg` files to SD card (manual).
8. Plug in SD card to digital picture frame (manual).

### :rocket: Future Process

I'd like to be able to make a custom programmed LILYGO T-Dongle S3 that allows the frame to read from a micro SD card and
also allow to write to the SD card wirelessly.

1. Create a `Digital Picture Frame` album in [Google Photos][2] (manual).
2. Add desired photos to album (manual).
3. Download files from album (auto).
4. Convert `HEIC` files to `jpg` (auto).
5. Wirelessly upload files to frame USB drive via [LILYGO T-Dongle S3][5] (auto).

## :gear: Config

### :material-sd: SD Card Preparation

!!! code "Determine USB device"

    ```shell
    sudo lsusb
    ```

    ```shell title="Output"
    Bus 003 Device 003: ID 0bda:0306 Realtek Semiconductor Corp. USB3.0 Card Reader
    ```

!!! code "Look at messages after plugging in USB adapter"

    ```shell
    sudo dmesg
    ```
    
    ```shell title="Output"
    [ 1409.448074] usb 3-1: new SuperSpeed USB device number 3 using xhci_hcd
    [ 1409.468208] usb 3-1: New USB device found, idVendor=0bda, idProduct=0306, bcdDevice= 1.17
    [ 1409.468215] usb 3-1: New USB device strings: Mfr=1, Product=2, SerialNumber=3
    [ 1409.468216] usb 3-1: Product: USB3.0 Card Reader
    [ 1409.468218] usb 3-1: Manufacturer: Realtek
    [ 1409.468219] usb 3-1: SerialNumber: 201506301013
    [ 1409.470012] usb-storage 3-1:1.0: USB Mass Storage device detected
    [ 1411.925210] sd 3:0:0:1: [sdc] 31116288 512-byte logical blocks: (15.9 GB/14.8 GiB)
    [ 1411.926227] sd 3:0:0:1: [sdc] Write Protect is off
    [ 1411.926231] sd 3:0:0:1: [sdc] Mode Sense: 2f 00 00 00
    [ 1411.927024] sd 3:0:0:1: [sdc] Write cache: disabled, read cache: enabled, doesn't support DPO or FUA
    [ 1411.946558]  sdc: sdc1
    [ 1411.946720] sd 3:0:0:1: [sdc] Attached SCSI removable disk
    ```

!!! code "Format the SD card as FAT32"

    ```shell
    sudo mkfs.vfat -F 32 /dev/sdc 
    ```

## :pencil: Usage

### :arrows_counterclockwise: HEIC Converter Script

This script converts `HEIC` images to `JPG` or `PNG` format. It can also delete original `HEIC` files upon successful
conversion, delete `MP4` files, and extract zip/tar archives.

It requires ImageMagick (`magick` or `convert` command) for `HEIC` conversion, `unzip` for `.zip` files, and `tar` for `.tar`
and compressed tarballs.

!!! code "Prerequisites"

    === "apt"

        ```shell
        sudo apt install imagemagick
        ```

!!! note

    Certain ImageMagick packages uses the `convert` command and others use the `magick` command.

!!! example "Convert individual HEIC files"

    ```shell
    ./heic-converter.sh image.heic photo.heic
    ```
!!! example "Convert individual HEIC file to png and extract zip file"

    ```shell
    ./heic-converter.sh -f png photo.heic --extract-archives archive.zip
    ```
    
!!! example "Process all files in directory and delete all HEIC files"

    ```shell
    ./heic-converter.sh -d ~/Pictures/MyHEICImages -f jpg --delete-heic-on-success --extract-archives
    ```

!!! example "Process all files in directory and deleta all mp4 files"

    ```shell
    ./heic-converter.sh -d ./my_media --delete-mp4 --extract-archives
    ```

!!! example "Extract archive files, such as zip or tar"

    ```shell
    ./heic-converter.sh --extract-archives my_photos.zip video_archive.tar.gz
    ```

??? abstract "heic-converter.sh"

    ```bash
    --8<-- "digital-picture-frame/heic-converter.sh"
    ```

## :link: References

- <https://www.amazon.com/dp/B015XVAKG4>

[1]: <https://www.amazon.com/dp/B015XVAKG4>
[2]: <https://www.google.com/photos/about/>
[3]: <https://support.google.com/photos/answer/7652919>
[4]: <https://imagemagick.org/script/convert.php>
[5]: <https://lilygo.cc/products/t-dongle-s3>
