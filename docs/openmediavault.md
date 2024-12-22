---
tags:
  - vm
  - proxmox
---
# :simple-openmediavault: OpenMediaVault

## :material-content-save-plus: Install

- Download ISO into Proxmox
- Create new VM
- Mount existing USB drive.
- Install omv into VM.

## :fontawesome-solid-universal-access: Default Access

- Port: `80`
- Username: `admin`
- Password: `openmediavault`

### :key: Change Password

Top right person icon -> Change Password

### New User

Users -> Users

- Groups: `openmediavault-admin,users`

## :material-content-save-cog: Reinstall

[Recover drive][1]

Mounted after reinstall and not before.

remount

```shell
omv-firstaid
```

## Static IP

### GUI

Network -> Interfaces -> ens18

- Method: `Static`
- Address: `192.168.2.19`
- Netmask: `255.255.0.0`
- Gateway: `192.168.0.0`

```yaml "Dynamic"
# /etc/netplan/20-openmediavault-ens18.yaml 
network:
  ethernets:
    ens18:
      match:
        macaddress: bc:24:11:16:73:c0
      dhcp4: yes
      dhcp4-overrides:
        use-dns: true
        use-domains: true
      dhcp6: no
      link-local: []
```

## NFS

### Server

- Client: `192.168.2.0/24`
- Permission: `Read/Write`
- Extra options: `subtree_check,insecure,no_root_squash`

### Client

```shell
apt install autofs
```

```ini
# /etc/auto.master
+auto.master
/mnt /etc/auto.nfs --ghost --timeout=60
```

```ini
# /etc/auto.nfs
storage -fstype=nfs4,rw,insecure 192.168.2.19:/storage
```

Test

```shell
showmount -e 192.168.2.19
```

Mount

```shell
systemctl restart autofs.service
systemctl status autofs.service
```


## :link: References

- https://www.youtube.com/watch?v=Bce7VT3kJ4g

[1]: <https://www.reddit.com/r/OpenMediaVault/s/vgdGfywcij>
