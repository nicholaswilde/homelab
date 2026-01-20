---
tags:
  - lxc
  - vm
  - proxmox
---
# :simple-bentopdf: BentoPDF

[BentoPDF][3] is a self-hosted, minimalist web-based PDF editor that focuses on simplicity and ease of use for basic PDF manipulations.

I use BentoPDF in conjunction with [Stirling PDF][4] to provide a comprehensive PDF management suite. While Stirling PDF is a powerful, feature-rich tool for complex operations (like OCR, merging, and advanced conversions), BentoPDF offers a cleaner, more streamlined interface for quick edits and viewing. Having both allows for choosing the right tool for the task: BentoPDF for speed and simplicity, and Stirling PDF for heavy-duty processing.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8080`
    
    :material-information-outline: Configuration path: `/opt/bentopdf`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/ct/bentopdf.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(curl -sL https://github.com/asylumexp/Proxmox/raw/main/ct/bentopdf.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## :rocket: Upgrade

!!! code ""

    === "Task"

        ```shell
        task update
        ```
    === "Manual"

        ```shell
        sudo /root/git/nicholaswilde/homelab/lxc/bentopdf/update.sh
        ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "bentopdf/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=bentopdf>
- <https://pimox-scripts.com/scripts?id=BentoPDF>

[3]: <https://github.com/alam00000/bentopdf>
[4]: <./stirling-pdf.md>
