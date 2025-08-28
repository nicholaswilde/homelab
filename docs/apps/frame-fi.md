---
tags:
  - lxc
  - proxmox
  - rclone
---
# :signal_strength: FrameFi :frame_photo:

[FrameFi][1] is an application used to display pictures on my digital picture frame using a [LILYGO T-Dongle S3][2]. This documentation focuses on how to download images from a Google Photos album using `rclone` so that the photos can then be synced with the frame.

## :chains: Workflow

1. Add pictures to Google Photos album.
2. Download pictures from album to homelab.
3. Sync photos from homelab to digital picture frame via FrameFi (FTP).

## :hammer_and_wrench: Installation

See [rclone](../tools/rclone.md) for `rclone` installation and [FrameFi][1] for how to setup FrameFi on your LILYGO T-Dongle S3.

!!! example ""

    :material-information-outline: Configuration path: `/opt/frame-fi`

## :gear: Config

Before running the download script, you need to configure the `.env` file and `rclone`.

Copy the `.env.tmpl` to `.env` and then edit the following variables:

!!! abstract "`homelab/pve/frame-fi/.env`"

    ```ini
    --8<-- "frame-fi/.env.tmpl"
    ```

- `RCLONE_GPHOTOS_CLIENT_ID`: Your Google API client ID for rclone.
- `RCLONE_GPHOTOS_CLIENT_SECRET`: Your Google API client secret for rclone.
- `RCLONE_GPHOTOS_ALBUM_NAME`: The exact name of the Google Photos album you wish to download.
- `RCLONE_DOWNLOAD_DESTINATION`: The local directory where the downloaded images will be stored. Defaults to `${INSTALL_DIR}/images`.

### :simple-rclone: Rclone Configuration

The `download.sh` script assumes an `rclone` remote named `gphotos` is configured to access Google Photos. If it's not already set up, you will need to configure it interactively using `rclone config`.

!!! warning

    While the script sets the client ID and secret as environment variables, `rclone` typically requires an authenticated token for Google Photos. It is highly recommended to run `rclone config` interactively to set up the `gphotos` remote and obtain the necessary token.

!!! warning

    Rclone can only download photos from albums that were *created by rclone itself*. It cannot download from albums created directly in Google Photos or by other applications.

### :frame_photo: Creating Google Photos Albums with Rclone

To create a new Google Photos album that rclone can later download from, use the following command:

!!! code "Create Album"

    ```shell
    rclone mkdir gphotos:album/"Your New Album Name"
    ```

Replace `"Your New Album Name"` with the desired name for your album. Once created, you can upload photos to this album using rclone or manually via the Google Photos interface.

## :pencil: Usage

To download images from your configured Google Photos album, simply run the `download` task:

!!! code "Download Images"

    === "Task"
        
        ```shell
        task download
        ```

    === "Manual"

        ```shell
        ./download.sh
        ```


This will execute the `download.sh` script, which will:

1. Check for `rclone` dependency.

2. Load environment variables from `.env`.

3. Verify or attempt to configure the `gphotos` rclone remote.

4. Create the Google Photos album if it does not already exist.

5. Create the local destination directory if it doesn't exist.

6. Use `rclone sync` to download images from the specified Google Photos album to the local destination.

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "frame-fi/task-list.txt"
    ```

## :link: References

- <https://rclone.org/googlephotos/>
- <https://rclone.org/>

[1]: <https://nicholaswilde.io/frame-fi>
[2]: <https://lilygo.cc/products/t-dongle-s3>
