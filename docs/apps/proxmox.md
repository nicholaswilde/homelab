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

!!! code "Post Install"

    === "AMD64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/misc/post-pve-install.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(curl -sL https://github.com/asylumexp/Proxmox/raw/main/misc/post-pve-install.sh)"
        ```

!!! code "Add LXC IP Tag"

    === "AMD64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/misc/add-lxc-iptag.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/misc/add-lxc-iptag.sh)"
        ```

!!! code "Update"

    === "AMD64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/misc/update-lxcs.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/misc/add-lxc-iptag.sh)"
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

!!! code "node"

    ```shell
    (
      systemctl stop pve-cluster corosync && \
      pmxcfs -l
    )
    ```

!!! code "node"

    ```shell
    (
      rm -rf /etc/corosync/*
      rm -rf /etc/pve/corosync.conf 
      killall pmxcfs
      systemctl start pve-cluster
    )
    ```

!!! code "The node is now separated from the cluster. You can deleted it from any remaining node of the cluster"

    ```shell
    pvecm delnode oldnode
    ```

!!! tip "If the command fails due to a loss of quorum in the remaining node, set the `expected` votes to `1` as a workaround"

    ```shell
    pvecm expected 1
    ```

And then repeat the `pvecm delnode` command.

Now switch back to the separated node and delete all the remaining cluster files on it. This ensures that the node can be added to another cluster again without problems.

!!! code "Separated node"

    ```shell
    rm -rf /var/lib/corosync/*
    ```

As the configuration files from the other nodes are still in the cluster file system, you may want to clean those up too. After making absolutely sure that you have the correct node name, you can simply remove the entire directory recursively from `/etc/pve/nodes/NODENAME`.

!!! code

    ```shell
    rm -rf /etc/pve/nodes/NODENAME
    ```

!!! warning

    The node’s SSH keys will remain in the authorized_key file. This means that the nodes can still connect to each other with public key authentication. You should fix this by removing the respective keys from the `/etc/pve/priv/authorized_keys` file.

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

!!! code "Create a partition"

    ```shell
    sgdisk -N 1 /dev/sdb
    ```
!!! code "Create a [P]hysical [V]olume (PV) without confirmation and 250K metadatasize."

    ```shell
    pvcreate --metadatasize 250k -y -ff /dev/sdb1
    ```

!!! code "Create a volume group named `vmdata` on /dev/sdb1"

    ```shell
    vgcreate vmdata /dev/sdb1
    ```

## :material-pool: Create a LVM-thin pool

!!! code ""

    ```shell
    lvcreate -L 80G -T -n vmstore vmdata
    ```

## :material-harddisk-plus: [Resize LXC Disks][10]

!!! tip

    This can be done from the GUI, but sometimes the LXC doesn't register the change.
    
From node

!!! code "Stop the LXC"

    ```shell
    pct stop 108
    ```

!!! code "Increase the absolute size to 20G"

    ```shell
    pct resize 108 rootfs 20G
    ```

!!! code "Check the file system"

    ```shell
    e2fsck -f /dev/pve/vm-108-disk-0
    ```

!!! code "Resize the file system (optional)"

    ```shell
    resize2fs /dev/pve/vm-108-disk-0
    ```

!!! code "Start the LXC"

    ```shell
    pct start 108
    ```

## :material-harddisk-plus: [Resize VM Disks][3]

### :frame_photo: Step 1: Increase/resize disk from GUI console

### :material-harddisk-plus: Step 2: Extend physical drive partition

From inside of the VM, not from the control node.

!!! code "check free space"

    ```shell
    fdisk -l
    ```

!!! code "Extend physical drive partition"

    ```shell
    growpart /dev/sda 3
    ```

!!! code "See physical drive"

    === "root"
        ```shell
        pvdisplay
        ```
    === "sudo"
    
        ```shell
        sudo pvdisplay
        ```
    
    ```shell title="Output"
      --- Physical volume ---
      PV Name               /dev/sda3
      VG Name               ubuntu-vg
      PV Size               <30.25 GiB / not usable 16.50 KiB
      Allocatable           yes
      PE Size               4.00 MiB
      Total PE              7743
      Free PE               2048
      Allocated PE          5695
      PV UUID               nE8Q94-dVYI-8ZP3-VEar-vONW-Vday-L0JofP
    ```

!!! code "Instruct LVM that disk size has changed"

    ```shell
    pvresize /dev/sda3
    ```

!!! success "Check physical drive if has changed"

    ```shell
    pvdisplay
    ```

    ```shell title="Output"
    
    ```

### :brain: Step 3: Extend Logical volume

!!! code "View starting LV"

    ```shell
    lvdisplay
    ```

!!! code "Resize LV"

    ```shell
    lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
    ```

!!! success "View changed LV"

    ```shell
    lvdisplay
    ```

    ```shell title="Output"
    
    ```

### :open_file_folder: Step 4: Resize Filesystem

!!! code "Resize Filesystem"

    ```shell
    resize2fs /dev/ubuntu-vg/ubuntu-lv
    ```

!!! success "Confirm results"

    ```shell
    fdisk -l
    ```

    ```shell title="Output"
    
    ```

## :key: [private key /root/.ssh/id_rsa contents do not match][5]

!!! code "Run on all nodes"

    ```shell
    (
      cd /root/.ssh && \
      mv id_rsa id_rsa.bak && \
      mv id_rsa.pub id_rsa.pub.bak && \
      mv config config.bak
    )
    ```

!!! code "Run on all nodes"

    ```shell
    pvecm updatecerts
    ```

## :material-monitor: [Pass Disk to VM][6]

!!! code "List the disks by ID"

    ```shell
    ls -n /dev/disk/by-id/
    ```
    
!!! code "Attach the disk to the VM"

    ```
    /sbin/qm set [VM-ID] -virtio2 /dev/disk/by-id/[DISK-ID]
    ```

## :material-backup-restore: [Kill Backup Job][7]

!!! code ""

    ```shell
    vzdump -stop
    ```

!!! code ""

    ```shell
    ps awxf | grep vzdump
    ```

    ```shell title="Output"
    2444287 ?        Ds     0:00 task UPID:server_name:00254BFF:06D36C31:63BB7524:vzdump::root@pam:
    ```

!!! code ""

    ```shell
    kill -9 <process id>
    ```

## :bell: [Email Notifications using Gmail][9]

!!! code "Install dependencies"

    ```bash
    (
      apt update
      apt install -y libsasl2-modules mailutils
    )
    ```

Enable 2FA for the gmail account that will be used by going to [security settings](https://myaccount.google.com/security).

Create app password for the account.

1. Go to [App Passwords](https://security.google.com/settings/security/apppasswords)
2. Select app: `Mail`
3. Select device: `Other`
4. Type in: `Proxmox` or whatever you want here
  
!!! code "Write gmail credentials to file and hash it"

    ```bash
    echo "smtp.gmail.com youremail@gmail.com:yourpassword" > /etc/postfix/sasl_passwd
    ```

!!! code "Set file permissions to u=rw"

    ```shell    
    chmod 600 /etc/postfix/sasl_passwd
    ```
    
!!! code "Generate `/etc/postfix/sasl_passwd.db`"
    
    ```shell
    postmap hash:/etc/postfix/sasl_passwd
    ```

!!! warning

    Comment out the existing line containing just `relayhost=` since we are using this key in our configuration we just pasted in.

!!! abstract "Append the following to the end of the file: `/etc/postfix/main.cf` and comment out `relayhost=`"

    ```ini
    mydestination = $myhostname, localhost.$mydomain, localhost
    # relayhost = 
    mynetworks = 127.0.0.0/8
    inet_interfaces = loopback-only
    recipient_delimiter = +
    
    compatibility = 2
    
    relayhost = smtp.gmail.com:587
    smtp_use_tls = yes
    smtp_sasl_auth_enable = yes
    smtp_sasl_security_options =
    smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
    smtp_tls_CAfile = /etc/ssl/certs/Entrust_Root_Certification_Authority.pem
    smtp_tls_session_cache_database = btree:/var/lib/postfix/smtp_tls_session_cache
    smtp_tls_session_cache_timeout = 3600s
    ```

??? info "Example Screenshot"

    ![Screen Shot 2022-09-26 at 10 36 42 AM](https://user-images.githubusercontent.com/12147036/192343565-3d4c0235-07f7-4a82-8381-72e654368425.png)

!!! code "Reload postfix"

    ```shell
    postfix reload
    ```

!!! success "Test to make sure everything is hunky-dory"

    ```bash
    echo "sample message" | mail -s "sample subject" anotheremail@gmail.com
    ```

### :incoming_envelope: [SMTP Setup][8]

!!! example "Proxmox GUI"

    Server: `smtp.gmail.com`

    Encryption: `STARTTLS`

    Port: `587`

    Authenticate: :white_check_mark:

    Username: `username@gmail.com`

    Password: `password`

    From Address: `username@gmail.com`

    Recipient(s): `root@pam`

    Addtional Recipient(s): `email@gmail.com`

![test](https://pve.proxmox.com/pve-docs/images/screenshot/gui-datacenter-notification-smtp.png)

??? abstract "`/etc/pve/notifications.cfg`"

    ```ini
    smtp: example
            mailto-user root@pam
            mailto-user admin@pve
            mailto max@example.com
            from-address pve1@example.com
            username pve1
            server mail.example.com
            mode starttls
    ```

??? abstract "The matching entry in `/etc/pve/priv/notifications.cfg`, containing the secret token"

    ```ini
    smtp: example
            password somepassword
    ```

### :material-bullseye-arrow: Targets to notify

WIP

## VM Trim

It tells your VM to report all deleted (unused) blocks to the hypervisor (like Proxmox, VMware, etc.) so the host system can reclaim that storage space.

This is especially important for thinly-provisioned disks.

Here’s a breakdown of the command and the process:

- `sudo`: Runs the command as the 'root' superuser, which is required.

- `fstrim`: The command to "trim" or discard unused blocks.

- `-a`: (all) Runs the command on all mounted filesystems that support it.

- `-v`: (verbose) Prints out how much space was trimmed from each filesystem.

!!! code ""

    ```
    sudo fstrim -av
    ```

## [QDevice](https://www.techtutorials.tv/sections/promox/proxmox-cluster-qdevice-raspberry-pi/)

How to add a Raspberry Pi to a Proxmox cluster that only has two nodes.

### Raspberry Pi

Install the corosync-qnetd package

```shell
sudo apt install corosync-qnetd
```

Allow root SSH Login

```shell
sudo nano /etc/ssh/sshd_config
```

!!! abstract "/etc/ssh/sshd_config"

    ```
    PermitRootLogin yes
    ```

Restart service

```shell
sudo systemctl restart ssh
```

Change root password

```shell
sudo passwd root
```

View the IP address

```
hostname -I
```

### PVE Nodes

```shell
apt install corosync-qdevice
```

Install the corosync-qdevice package on all nodes

```shell
pvecm qdevice setup <qdevice_ip_address>
```

Check the results

```shell
pvecm status
```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=homepage>
- <https://pimox-scripts.com/scripts?id=Homepage>
- <https://pve.proxmox.com/wiki/>
- <https://pve.proxmox.com/pve-docs/chapter-pvecm.html#_corosync_external_vote_support>

[1]: <https://www.proxmox.com/en/>
[2]: <https://pve.proxmox.com/wiki/Cluster_Manager#_remove_a_cluster_node>
[3]: <https://forum.proxmox.com/threads/resize-ubuntu-vm-disk.117810/post-510089>
[4]: <https://docs.goauthentik.io/integrations/services/proxmox-ve/>
[5]: <https://forum.proxmox.com/threads/cant-connect-to-destination-address-using-public-key-task-error-migration-aborted.42390/post-663678>
[6]: <https://pve.proxmox.com/wiki/Logical_Volume_Manager_(LVM)>
[7]: <https://forum.proxmox.com/threads/backup-job-is-stuck-and-i-cannot-stop-it-or-even-kill-it.120835/#post-524962>
[8]: <https://pve.proxmox.com/wiki/Notifications#notification_targets>
[9]: <https://gist.github.com/tomdaley92/9315b9326d4589c9652ce0307c9c38a3>
[10]: <https://pakstech.com/blog/proxmox-increase-lxc-disk/>
