---
tags:
  - proxmox
---
# :simple-proxmox: Proxmox

[Proxmox][1] is the hypervisor that I am using on most of my hardware.

I am using it over Portainer and kubernetes for ease of use and feature set.

## :hammer_and_wrench: Post Installation

!!! example ""

    :material-console-network: Default Port: `8006`

### Post Install

=== "AMD64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/post-pve-install.sh)"
    ```

=== "ARM64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/misc/post-pve-install.sh)"
    ```

### Add LXC IP Tag

=== "AMD64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/add-lxc-iptag.sh)"
    ```

=== "ARM64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/add-lxc-iptag.sh)"
    ```

### Update

=== "AMD64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/update-lxcs.sh)"
    ```

=== "ARM64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/add-lxc-iptag.sh)"
    ```

## :material-harddisk-plus: Datacenter NFS Volumes

!!! example ""

    GUI: `Datacenter -> Storage -> Add -> NFS`

!!! example "pve-backups"

    ID: `pve-backups`

    Server: `omv.l.nicholaswilde.io`
    
    Export: `/export/pve-backups`

!!! example "pve-shared"

    ID: `pve-shared`

    Server: `omv.l.nicholaswilde.io`

    Export: `/export/pve-shared`

## :simple-kubernetes: [Reset Cluster Info][2]

How to reset cluster. Useful if the node IP isn't matching.

```shell title="node"
(
  systemctl stop pve-cluster corosync && \
  pmxcfs -l
)
```

```shell title="node"
(
  rm /etc/corosync/*  && \
  rm -r /etc/corosync/*  && \
  rm -r /etc/pve/corosync.conf  && \ 
  killall pmxcfs && \
  systemctl start pve-cluster
)
```

## :material-ip-network: Static IP

### :gear: Node

WIP

### :package: Container

WIP

### :desktop_computer: VM

WIP

## :simple-authentik: [authentik][4]

!!! example "Proxmox GUI"

    `Datacenter -> Permissions -> Realms`

    Issuer URL: `http://authentik.l.nicholaswilde.io/application/o/proxmox`
    
    Realm: `authentik`

    Client ID: `from authentik`
    
    Client Key: `from authentik`
    
    Autocreate Users: :white_check_mark:

    Username Claim: `username`

## :material-harddisk-plus: [Resize VM Disks][3]

### :frame_photo: Step 1: Increase/resize disk from GUI console

### :material-harddisk-plus: Step 2: Extend physical drive partition

```shell title="check free space"
fdisk -l
```

```shell title="Extend physical drive partition"
growpart /dev/sda3
```

```shell title="See  phisical drive"
pvdisplay
```

```shell title="Instruct LVM that disk size has changed"
pvresize /dev/sda3
```

```shell title="Check physical drive if has changed"
pvdisplay
```

### :brain: Step 3: Extend Logical volume

```shell title="View starting LV"
lvdisplay
```

```shell title="Resize LV"
lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
```

```shell title="View changed LV"
lvdisplay
```

### :open_file_folder: Step 4: Resize Filesystem

```shell title="Resize Filesystem"
resize2fs /dev/ubuntu-vg/ubuntu-lv
```

```shell title="Confirm results"
fdisk -l
```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=homepage>
- <https://pimox-scripts.com/scripts?id=Homepage>

[1]: <https://www.proxmox.com/en/>
[2]: <https://forum.proxmox.com/threads/remove-or-reset-cluster-configuration.114260/#post-493906>
[3]: <https://forum.proxmox.com/threads/resize-ubuntu-vm-disk.117810/post-510089>
[4]: <https://docs.goauthentik.io/integrations/services/proxmox-ve/>
