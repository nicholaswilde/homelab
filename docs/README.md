# :house_with_garden: Homelab :test_tube:
[![task](https://img.shields.io/badge/Task-Enabled-brightgreen?style=for-the-badge&logo=task&logoColor=white)](https://taskfile.dev/#/)
[![ci](https://img.shields.io/github/actions/workflow/status/nicholaswilde/homelab/ci.yaml?label=ci&style=for-the-badge&branch=main)](https://github.com/nicholaswilde/homelab/actions/workflows/ci.yaml)

A repo for my homelab setup

---

## :book: Documentation

Documentation can be found [here][1].

---

## :framed_picture: Background

I just want to document and share my homelab setup and experiences.

My current setup is Proxmox installed on an AMD64 desktop computer, old AMD64 laptop, and a Raspberry Pi 4 8GB.

I also have an Intel NUC running Ubuntu server with Home Assistant and add ons in  Docker containers.

I also have a Raspberry Pi Zero W running and NTP server.

---

## :construction: Development

New pages for this site can be created using [jinja2][3] and the `.template.md.j2` file.

```shell title="Install"
pipx install jinja2-cli
```

```shell title="Create new page"
jinja2 .template.md.j2 -D app_name=New App -D app_port=8080 -D config_path=/opt/new-app > new-app.md
```

---

## :balance_scale: License

​[​Apache License 2.0](../LICENSE)

---

## :pencil:​ Author

​This project was started in 2024 by [​Nicholas Wilde​][2].

[1]: <https://nicholaswilde.io/homelab/>
[2]: <https://github.com/nicholaswilde/>
[2]: <https://pypi.org/project/Jinja2/>
