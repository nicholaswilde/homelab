---
tags:
  - lxc
  - vm
  - proxmox
  - docker
---
# :film_frames: Pinchflat

[Pinchflat][1] is a self-hosted app for downloading YouTube content built using [`yt-dlp`][2].

This app is being used to automatically download videos from YouTube and store them on my [NFS share][4] so that I can stream the videos to my Apple TV via [Infuse][3] without having to watch commercials and take up bandwidth every time a video is rewatched.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: 8945

!!! code "`homelab/docker/pinchflat`"

    === "Task"

        ```shell
        task up
        ```

    === "Docker Compose"

        ```shell
        docker compose up
        ```

## :gear: Config

I am currently investigating how to format the metadata for Infuse to properly pickup the video automatically. I also need to figure out how to setup Infuse.

!!! abstract "`homelab/docker/pinchflat/.env`"

    ```ini
    --8<-- "pinchflat/.env.tmpl"
    ```

??? abstract "`homelab/docker/pinchflat/compose.yaml`"

    ```yaml
    --8<-- "pinchflat/compose.yaml"
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/pinchflat.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/pinchflat.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "pinchflat/task-list.txt"
    ```

## :link: References

[1]: <https://github.com/kieraneglin/pinchflat>
[2]: <https://github.com/yt-dlp/yt-dlp>
[3]: <https://firecore.com/infuse>
[4]: <./openmediavault.md>