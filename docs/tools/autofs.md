---
tags:
  - tool
---
# :fontawesome-solid-hard-drive: Autofs

## :hammer_and_wrench: Installation

WIP

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
