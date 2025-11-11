---
tags:
  - vm
  - proxmox
---
# :lucide-homeassistant: Home Assistant OS

My current setup consists of running Docker containers on my [NUC][1]. 

Evaluating if I want to convert to a VM running HAOS to better support add ons like Matter.

I am not that familiar with HAOS and I don't know how else to back it up other than the entire VM. Also concerned about latency but perhaps I integrate redis, if I am not already.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8123`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/vm/haos-vm.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=haos-vm>

[1]: <../hardware/nuc.md>