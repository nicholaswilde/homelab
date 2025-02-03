---
# :house_with_garden: Homelab :test_tube:

[![task](https://img.shields.io/badge/Task-Enabled-brightgreen?style=for-the-badge&logo=task&logoColor=white)](https://taskfile.dev/#/)
[![ci](https://img.shields.io/github/actions/workflow/status/nicholaswilde/homelab/ci.yaml?label=ci&style=for-the-badge&branch=main)](https://github.com/nicholaswilde/homelab/actions/workflows/ci.yaml)

A repo for my [homelab][7] setup.

## :frame_with_picture: Background

I just want to document and share my homelab setup and experiences.

My current setup is Proxmox installed on an AMD64 desktop computer, and old AMD64 laptop, a Raspberry Pi 4 8GB, and a Raspberry Pi 5 16GB.

I also have an Intel NUC running Ubuntu server with Home Assistant and add ons in Docker containers.

I also have a Raspberry Pi Zero W running an NTP server.

!!! note

    All commands run on LXCs are being run as `root` and so `sudo` is not required.

!!! note

    The commands assume that this repo is cloned into a directory `/root/git/nicholaswilde/homelab`.
    
!!! note

    I tend to use [tteck's][2] [ProxmoxVE Helper Scripts][3] and [Proxmox arm64 Install Scripts][4] to create LXCs and not run in Docker containers to reduce resources.

!!! info

    Features or applications that I come across on the Internet and have not yet been incorporated into my homelab are tracked
    in the [repository issues][8].



## :hammer_and_wrench: Setup & Maintenance

My homelab is setup and maintained using [Ansible][5], which is documented [here][6].

## :construction: Development

Check out the [Development](./reference/development.md) page.

## ​:scales: License

​[​Apache License 2.0](./LICENSE)

## ​:pencil:​Author

​This project was started in 2024 by [​Nicholas Wilde​][1].

[1]: <https://github.com/nicholaswilde/>
[2]: <https://github.com/tteck>
[3]: <https://community-scripts.github.io/ProxmoxVE/>
[4]: <https://pimox-scripts.com/>
[5]: <https://www.redhat.com/en/ansible-collaborative>
[6]: <https://github.com/nicholaswilde/homelab-playbooks>
[7]: <https://linuxhandbook.com/homelab/>
[8]: <https://github.com/nicholaswilde/homelab/issues>
