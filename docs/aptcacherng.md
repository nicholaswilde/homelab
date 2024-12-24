---
tags:
  - lxc
---
# :material-cached: Apt-Cacher NG

## :material-server: Setup

```ini title="/etc/apt-cacher-ng/acng.conf"
CacheDir: /mnt/storage/aptcache
```

```shell
chown -R apt-cacher-ng:apt-cacher-ng /mnt/storage/aptcache
systemctl restart apt-cacher-ng.service
systemctl status apt-cacher-ng.service
journalctl -xeu apt-cacher-ng.service
```

```
http://aptcache.l.nicholaswilde.io:3142/acng-report.html
```

## :material-laptop: Client

```shell title="/etc/apt/apt.conf.d/00aptproxy"
(
 echo 'Acquire::http::Proxy "http://192.168.2.40:3142";' | tee /etc/apt/apt.conf.d/00aptproxy
 apt update
)
```
