---
tags:
  - vm
  - proxmox
---
# :simple-openmediavault: OpenMediaVault

[OpenMediaVault][3] is my NAS that serves both NFS and SAMBA shares to my network. It runs on VM on the system that is directly connected to my external hard drive.

## :hammer_and_wrench: Installation

- [Download][2] ISO into Proxmox

!!! code "pve"

    ```shell
    (
      cd /var/lib/vz/template/iso && \
      wget $(curl -s https://sourceforge.net/projects/openmediavault/rss?path=/iso | \
      grep -oP '<link>https://sourceforge.net/projects/openmediavault/files/iso/[^<]+</link>' | \
      head -n 1 | \
      sed 's/<link>//; s/<\/link>//'| \
      sed 's/\/download$//')
    )
    ```

- Create new VM

!!! example "General"

    Name: `omv`
    
    Start at boot: :white_check_mark:

!!! example "OS"

    ISO image: `*.iso`

!!! example "Disks"

    Bus/Device: `SATA`

    Disk size (GiB): `16`

!!! example "CPU"

    Cores: `2`

!!! example "Memory"

    Memory (MiB): `4096`

!!! code "Look for disk"

    ```shell
    lsblk
    ```

- Install omv into VM.

## :fontawesome-solid-universal-access: Default Access

!!! example ""

    :material-console-network: Port: `80`

    :fontawesome-solid-user: Username: `admin`

    :material-key: Password: `openmediavault`

### :key: Change Password

Top right person icon -> Change Password

### :fontawesome-solid-user-plus: New User

!!! example "Users -> Users"

    :fontawesome-solid-user-group: Groups: `openmediavault-admin,users`

## :material-content-save-cog: Reinstall

[Recover drive][1]

Mounted after reinstall and not before.

!!! code "Remount"

    ```shell
    omv-firstaid
    ```

## :material-check-network: Static IP

### :octicons-browser-24: GUI

!!! example "Network -> Interfaces -> ens18"

    Method: `Static`

    Address: `192.168.2.19`

    Netmask: `255.255.0.0`

    Gateway: `192.168.0.0`

## :simple-googlecloudstorage: NFS

!!! example "Server"

    Client: `192.168.2.0/24`

    Permission: `Read/Write`

    Extra options: `subtree_check,insecure,no_root_squash`

### :material-laptop: Client

!!! code "Installation"

    ```shell
    apt install autofs
    ```

!!! abstract "/etc/auto.master"

    === "Automated"

        ```shell
        echo "/mnt /etc/auto.nfs --ghost --timeout=60" | tee -a /etc/auto.master
        ```

    === "Manual"

        ```ini
        +auto.master
        /mnt /etc/auto.nfs --ghost --timeout=60
        ```

!!! abstract "/etc/auto.nfs"

    === "Automated"

        ```shell
        echo "storage -fstype=nfs4,rw,insecure 192.168.2.19:/storage" | tee /etc/auto.nfs
        ```

    === "Manual"

        ```ini
        storage -fstype=nfs4,rw,insecure 192.168.2.19:/storage
        ```

!!! example "Test"

    ```shell
    showmount -e 192.168.2.19
    ```

!!! code "Mount"

    ```shell
    (
      systemctl restart autofs.service && \
      systemctl status autofs.service
    )
    ```

## :rocket: Upgrade

!!! code

    ```shell
    omv-upgrade
    ```

## :link: References

- https://www.youtube.com/watch?v=Bce7VT3kJ4g

[1]: <https://www.reddit.com/r/OpenMediaVault/s/vgdGfywcij>
[2]: <https://www.openmediavault.org/?page_id=77>
[3]: <https://www.openmediavault.org/>
