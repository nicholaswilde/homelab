---
tags:
  - proxmox
  - lxc
---
# :simple-traefikproxy: Traefik

Traefik is used as my reverse proxy.

## :gear: Config

!!! note

    Paths in config file should be absolute.

### :handshake: Service

```shell
/etc/systemd/system/traefik.service
```

## :file_folder: Logs

```shell
tail -n10 /var/log/traefik/traefik.log
```
