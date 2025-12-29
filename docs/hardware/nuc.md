---
tags:
  - hardware
  - proxmox
  - amd64
---
# :simple-intel: Intel NUC

I'm in the process of converting my [Intel NUC][2] to be used as another `amd64` Proxmox node.

## :gear: Config

!!! example ""

    OS: [Proxmox 9][1]

    Manufacturer: `Intel`

    Model: `NUC10i3FNK`

    Generation: `10`

    CPU: `Intel i3`

    RAM: `32GB`

    Drive: `WIP`

    Hostname: `nuc-01`

    IP: `192.168.2.143`

    MAC: `1c:69:7a:a6:86:d5`

## :zap: Speed Test

| Rank | Send Speed | Receive Speed | Verdict |
| :--- | :--- | :--- | :--- |
| #1 | 936 Mbps | 936 Mbps | The King. Flawless in both directions. |

### :pencil: Usage

To start the `iperf3` server:

!!! code "Server"

    ```shell
    iperf3 -s
    ```

## :link: References

[1]: <https://www.proxmox.com/en/>
[2]: <https://www.intel.com/content/dam/support/us/en/documents/intel-nuc/NUC10i357FN_TechProdSpec.pdf>
