---
tags:
  - vm
  - proxmox
---
# :simple-immich: Immich-Go

[Immich-Go][1] is an open-source tool designed to streamline uploading large photo collections to your self-hosted Immich
server.

## :hammer_and_wrench: Installation

!!! code ""

    === "installer"
    
        ```shell
        curl -s https://installer.l.nicholaswilde.io/simulot/immich-go! | bash
        ```

## :gear: Config

!!! abstract "~/.bash_exports"

    === "Manual"
    
        ```ini
        export API_KEY='key'
        export IMMICH_SERVER='https://server.xyz'
        ```

## :pencil: Usage

!!! code ""

    ```shell
    immich-go upload from-google-photos takeout-20250216T024307Z-005.zip -k ${API_KEY} -s ${IMMICH_SERVER}
    ```

## :link: References

[1]: <https://github.com/simulot/immich-go>