---
tags:
  - lxc
  - proxmox
---
# :simple-vaultwarden: Vaultwarden

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8000`

!!! code "Vaultwarden"

    === "AMD64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/ct/vaultwarden.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(curl -sL https://github.com/asylumexp/Proxmox/raw/main/ct/vaultwarden.sh)"
        ```

!!! code "bw cli"

    === "Installer"
    
        ```shell
        (
          curl -s https://installer.l.nicholaswilde.io/bitwarden/clients! | bash
          mv /usr/local/bin/clients /usr/local/bin/bw
        )
        ```

## :gear: Config

!!! code "Connect to self-hosted server"

    ```shell
    bw config server https://vault.l.nicholaswilde.io
    ```

!!! code "Authorize via API"

    ```shell
    bw login --apikey
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "vaultwarden/task-list.txt"
    ```

## :pencil: Usage

!!! code "Create Attachment"

    ```shell
    bw create attachment --file ./path/to/file --itemid 16b15b89-65b3-4639-ad2a-95052a6d8f66
    ```

!!! tip

    If you don’t know the exact `itemid` you want to use, use `bw get item <search-term>` to return the item, including its `id`.

!!! code "Get Attachment"

    ```shell
    bw get attachment photo.png --itemid 99ee88d2-6046-4ea7-92c2-acac464b1412 --output /Users/myaccount/Pictures/
    ```

!!! note

    When using `--output`, the path must end a forward slash (/) to specify a directory or a filename (`/Users/myaccount/Pictures/photo.png`).

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=vaultwarden>
- <https://pimox-scripts.com/scripts?id=Vaultwarden>
- <https://bitwarden.com/help/cli/>
