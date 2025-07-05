---
tags:
  - hardware
---
# :frame_with_picture: Digital Picture Frame

I have a [NIX Advance 8 Inch USB Digital Photo Frame][1] that does not have wireless communication.

## :frame_with_picture: Background

The issue is workflow for updating the memory card or USB thumb drive with pictures is a bit manual and clunky. I want to automate the process a little bit more.

### :clipboard: Current Process

1. Create a `Digital Picture Frame` album in [Google Photos][2] (manual).
2. Add desired photos to album (manual).
3. [Download album][3] as zip file via web interface on Chromebook (manual).
4. Transfer zip file to LXC (manual).
5. Extract zip file (manual).
6. Convert `HEIC` files to `jpg` using [ImageMagick][4] (manual).
7. Delete `MP4` files (manual).
8. Format SD card as `FAT32` (optional) (manual).
9. Transfer `png` and `jpg` files to SD card (manual).
10. Plug in SD card to digital picture frame (manual).

### :rocket: Future Process

WIP

1. Create a `Digital Picture Frame` album in [Google Photos][2] (manual).
2. Add desired photos to album (manual).
3. Download files from album (auto).
4. Convert `HEIC` files to `jpg` (auto).
5. Wirelessly upload files to frame USB drive via [LILYGO T-Dongle S3][5] (auto).

## :gear: Config

### :material-sd: SD Card Preparation

!!! code "Format the SD card"

    ```shell
    sudo mkfs.vfat -F 32 /dev/sdc 
    ```

WIP

## :pencil: Usage

### :arrows_counterclockwise: HEIC Conversion

WIP

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
