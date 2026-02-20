---
tags:
  - lxc
  - proxmox
---
# ![Stirling PDF](https://cdn.jsdelivr.net/gh/selfhst/icons/webp/stirling-pdf.webp){ width="32" } Stirling PDF

[Stirling PDF][1] is a powerful, self-hosted web-based PDF manipulation tool that offers a wide range of features, including merging, splitting, OCR, and advanced conversions.

I use Stirling PDF in conjunction with [BentoPDF][2] to provide a complete PDF management solution. While Stirling PDF handles heavy-duty processing and complex operations, BentoPDF serves as a minimalist alternative for quick edits and viewing. Together, they ensure I have the right tool for any PDF task, from simple viewing to complex document transformations.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8080`

    :material-information-outline: Configuration path: `/opt/Stirling-PDF/.env`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/ct/stirling-pdf.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(curl -sL https://github.com/asylumexp/Proxmox/raw/main/ct/stirling-pdf.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "stirling-pdf/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=stirling-pdf>
- <https://pimox-scripts.com/scripts?id=stirling-pdf>

[1]: <https://github.com/Stirling-Tools/Stirling-PDF>
[2]: <./bentopdf.md>