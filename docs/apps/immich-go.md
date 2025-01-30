---
tags:
  - vm
  - proxmox
---
# :simple-immich: Immich-Go

[Immich-Go][1] is an open-source tool designed to streamline uploading large photo collections to your self-hosted Immich
server.

## :hammer_and_wrench: Installation

!!! quote ""

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

## Usage

!!! quote ""

    ```shell
    immich-go -key=${API_KEY} -server=${IMMICH_SERVER} upload -create-albums -google-photos Takeout/
    ```

## :link: References

[1]: <https://github.com/simulot/immich-go>
