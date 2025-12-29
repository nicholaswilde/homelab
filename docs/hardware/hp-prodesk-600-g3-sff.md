---
tags:
  - proxmox
  - hardware
  - amd64
---
# :computer: HP ProDesk 600 G3 SFF

This computer was inherited and so I converted it to a [Proxmox][1] node.

## :gear: Config

!!! example ""

    OS: `Proxmox 9.1.4`
    
    RAM: `24GB`

    DRIVE: `SATA SSD`

## :zap: Speed Test

| Rank | Send Speed | Receive Speed | Verdict |
| :--- | :--- | :--- | :--- |
| #4 | 811 Mbps | 938 Mbps | The Limp. Great receiver, but struggles to send at full speed. |

### :pencil: Usage

To test the network speed, use `iperf3`.

!!! code "Send"

    ```shell
    iperf3 -c 192.168.2.143
    ```

!!! code "Receive"

    ```shell
    iperf3 -c 192.168.2.143 -R
    ```
    
## :link: References

[1]: <https://www.proxmox.com/en/>
