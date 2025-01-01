---
# :house_with_garden: Homelab :test_tube:

[![task](https://img.shields.io/badge/Task-Enabled-brightgreen?style=for-the-badge&logo=task&logoColor=white)](https://taskfile.dev/#/)
[![ci](https://img.shields.io/github/actions/workflow/status/nicholaswilde/homelab/ci.yaml?label=ci&style=for-the-badge&branch=main)](https://github.com/nicholaswilde/homelab/actions/workflows/ci.yaml)

A repo for my homelab setup

## :frame_with_picture: Background

I just want to document and share my homelab setup and experiences.

My current setup is Proxmox installed on an AMD64 desktop computer, old AMD64 laptop, and a Raspberry Pi 4 8GB.

I also have an Intel NUC running Ubuntu server with Home Assistant and add ons in  Docker containers.

I also have a Raspberry Pi Zero W running and NTP server.

!!! note

    All commands run on LXCs are being run as `root` and so `sudo` is not required.

!!! note

    I tend to use [tteck's][2] [ProxmoxVE Helper Scripts][3] to create LXCs and not run in Docker containers to reduce resources.

## ​:scales: License

​[​Apache License 2.0](../LICENSE)

## ​:pencil:​Author

​This project was started in 2024 by [​Nicholas Wilde​][1].

[1]: <https://github.com/nicholaswilde/>
[2]: <https://github.com/tteck>
[3]: <>
