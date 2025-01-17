---
tags:
  - tool
---
# :fontawesome-solid-hard-drive: Autofs

[Autofs][1] is used to automatically connect to my NFS storage on my
containers/VMs so that they can share storage.

## :hammer_and_wrench: Installation

```shell
apt install autofs
```

## :material-laptop: Client

```shell
(
  apt install -y autofs && \
  echo '/mnt /etc/auto.nfs --ghost --timeout=60' | tee -a /etc/auto.master && \
  echo 'storage -fstype=nfs4,rw,insecure 192.168.2.19:/storage' | tee -a /etc/auto.nfs && \
  service autofs restart && \
  service autofs status
)
```

## :link: References

[1]: https://help.ubuntu.com/community/Autofs
