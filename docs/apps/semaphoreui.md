---
tags:
  - lxc
  - proxmox
---
# ![semaphoreui](https://cdn.jsdelivr.net/gh/selfhst/icons/svg/semaphore-ui.svg){ width="32" } Semaphore UI

[Semaphore UI][1] is being used as a GUI to Ansible to help manage my playbooks.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `3000`

    :material-file-key: Admin password: `cat ~/semaphore.creds`

    :material-database: Database: `BoltDB`

!!! quote ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/semaphore.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/semaphore.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=semaphore>
- <https://pimox-scripts.com/scripts?id=semaphore>

[1]: <https://semaphoreui.com/>
