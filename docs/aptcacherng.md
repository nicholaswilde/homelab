---
tags:
  - lxc
---
# Apt-Cacher NG

```ini "/etc/apt-cacher-ng/acng.conf"
CacheDir: /mnt/storage/aptcache
```

```shell
chown -R apt-cacher-ng:apt-cacher-ng /mnt/storage/aptcache
systemctl restart apt-cacher-ng.service
systemctl status apt-cacher-ng.service
journalctl -xeu apt-cacher-ng.service
```
