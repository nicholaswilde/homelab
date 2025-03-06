---
tags:
  - proxmox
---
# :simple-proxmox: Proxmox

[Proxmox][1] is the hypervisor that I am using on most of my hardware.

I am using it over Portainer and kubernetes for ease of use and feature set.

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/proxmox.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/proxmox.yaml"
    ```

## :hammer_and_wrench: Post Installation

!!! example ""

    :material-console-network: Default Port: `8006`

!!! quote "Post Install"

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/post-pve-install.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/misc/post-pve-install.sh)"
        ```

!!! quote "Add LXC IP Tag"

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/add-lxc-iptag.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/add-lxc-iptag.sh)"
        ```

!!! quote "Update"

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

How to reset cluster. Useful if the node IP isn't matching during join.

!!! quote "node"

    ```shell
    (
      systemctl stop pve-cluster corosync && \
      pmxcfs -l
    )
    ```

!!! quote "node"

    ```shell
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

## :material-group: [Create a Volume Group][6]

!!! quote "Create a partition"

    ```shell
    sgdisk -N 1 /dev/sdb
    ```
!!! quote "Create a [P]hysical [V]olume (PV) without confirmation and 250K metadatasize."

    ```shell
    pvcreate --metadatasize 250k -y -ff /dev/sdb1
    ```

!!! quote "Create a volume group named `vmdata` on /dev/sdb1"

    ```shell
    vgcreate vmdata /dev/sdb1
    ```

## :material-pool: Create a LVM-thin pool

!!! quote ""

    ```shell
    lvcreate -L 80G -T -n vmstore vmdata
    ```

## :material-harddisk-plus: [Resize VM Disks][3]

### :frame_photo: Step 1: Increase/resize disk from GUI console

### :material-harddisk-plus: Step 2: Extend physical drive partition

!!! quote "check free space"

    ```shell
    fdisk -l
    ```

!!! quote "Extend physical drive partition"

    ```shell
    growpart /dev/sda3
    ```

!!! quote "See physical drive"

    ```shell
    pvdisplay
    ```

!!! quote "Instruct LVM that disk size has changed"

    ```shell
    pvresize /dev/sda3
    ```

!!! success "Check physical drive if has changed"

    ```shell
    pvdisplay
    ```

### :brain: Step 3: Extend Logical volume

!!! quote "View starting LV"

    ```shell
    lvdisplay
    ```

!!! quote "Resize LV"

    ```shell
    lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
    ```

!!! success "View changed LV"

    ```shell
    lvdisplay
    ```

### :open_file_folder: Step 4: Resize Filesystem

!!! quote "Resize Filesystem"

    ```shell
    resize2fs /dev/ubuntu-vg/ubuntu-lv
    ```

!!! success "Confirm results"

    ```shell
    fdisk -l
    ```

## :key: [private key /root/.ssh/id_rsa contents do not match][5]

!!! quote "Run on all nodes"

    ```shell
    (
      cd /root/.ssh && \
      mv id_rsa id_rsa.bak && \
      mv id_rsa.pub id_rsa.pub.bak && \
      mv config config.bak
    )
    ```

!!! quote "Run on all nodes"

    ```shell
    pvecm updatecerts
    ```

## :material-monitor: [Pass Disk to VM][6]

!!! quote "List the disks by ID"

    ```shell
    ls -n /dev/disk/by-id/
    ```
    
!!! quote "Attach the disk to the VM"

    ```
    /sbin/qm set [VM-ID] -virtio2 /dev/disk/by-id/[DISK-ID]
    ```

## :material-backup-restore: [Kill Backup Job][7]

!!! quote ""

    ```shell
    vzdump -stop
    ```

!!! quote ""

    ```shell
    ps awxf | grep vzdump
    ```

!!! note ""

    ```shell
    2444287 ?        Ds     0:00 task UPID:server_name:00254BFF:06D36C31:63BB7524:vzdump::root@pam:
    ```

!!! quote ""

    ```shell
    kill -9 <process id>
    ```



## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=homepage>
- <https://pimox-scripts.com/scripts?id=Homepage>
- <https://pve.proxmox.com/wiki/>

[1]: <https://www.proxmox.com/en/>
[2]: <https://forum.proxmox.com/threads/remove-or-reset-cluster-configuration.114260/#post-493906>
[3]: <https://forum.proxmox.com/threads/resize-ubuntu-vm-disk.117810/post-510089>
[4]: <https://docs.goauthentik.io/integrations/services/proxmox-ve/>
[5]: <https://forum.proxmox.com/threads/cant-connect-to-destination-address-using-public-key-task-error-migration-aborted.42390/post-663678>
[6]: <https://pve.proxmox.com/wiki/Logical_Volume_Manager_(LVM)>
[7]: <https://forum.proxmox.com/threads/backup-job-is-stuck-and-i-cannot-stop-it-or-even-kill-it.120835/#post-524962>
