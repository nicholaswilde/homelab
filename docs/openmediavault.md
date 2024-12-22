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

## :fontawesome-solid-universal-access: Access

- Port: `80`
- Username: `admin`
- Password: `openmediavault`

## :material-content-save-cog: Reinstall

[Recover drive][1]

Mounted after reinstall and not before.

remount

```shell
omv-firstaid
```

## Static IP

```yaml
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
 
## :link: References

- https://www.youtube.com/watch?v=Bce7VT3kJ4g

[1]: <https://www.reddit.com/r/OpenMediaVault/s/vgdGfywcij>
