---
tags:
  - vm
  - proxmox
---
# :simple-openmediavault: OpenMediaVault

## :hammer_and_wrench: Installation

- [Download][2] ISO into Proxmox

```shell title="pve"
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

- Look for disk

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

remount

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

```shell
apt install autofs
```

```ini title="/etc/auto.master"
+auto.master
/mnt /etc/auto.nfs --ghost --timeout=60
```

```shell
echo "/mnt /etc/auto.nfs --ghost --timeout=60" | tee -a /etc/auto.master
```

```ini title="/etc/auto.nfs"
storage -fstype=nfs4,rw,insecure 192.168.2.19:/storage
```

```shell
echo "storage -fstype=nfs4,rw,insecure 192.168.2.19:/storage" | tee /etc/auto.nfs
```


```shell title="Test"
showmount -e 192.168.2.19
```

```shell title="Mount"
(
  systemctl restart autofs.service && \
  systemctl status autofs.service
)
```


## :link: References

- https://www.youtube.com/watch?v=Bce7VT3kJ4g

[1]: <https://www.reddit.com/r/OpenMediaVault/s/vgdGfywcij>
[2]: <https://www.openmediavault.org/?page_id=77>
