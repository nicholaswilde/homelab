# reprepro

https://nicholaswilde.io/homelab/apps/reprepro/

## [lnav](https://github.com/tstack/lnav/)

```shell
sudo apt install automake autoconf libunistring-dev libpcre2-dev libsqlite3-dev checkinstall
./configure
make
sudo checkinstall make install
```

## armv6 apps that need separate build

- sops
- ripgrep
- glow

## armv6 apps that don't need separate build

- task
- bat
- fd
- duf https://github.com/muesli/duf/releases/download/v0.9.1/duf_0.9.1_linux_armv6.deb
- gh https://github.com/cli/cli/releases/download/v2.83.1/gh_2.83.1_linux_armv6.deb
- eza
- cheat https://github.com/cheat/cheat/releases/download/4.4.2/cheat-linux-arm6.gz
- sd https://github.com/chmln/sd/releases/download/v1.0.0/sd-v1.0.0-arm-unknown-linux-gnueabihf.tar.gz
- btop https://github.com/aristocratos/btop/releases/download/v1.4.5/btop-arm-linux-musleabi.tbz
