---
tags:
  - about
---
# :rocket: Future

Ramblings and stream of conscienceness on the future of my homelab.

## :straight_ruler: Size

I currently use a shallow full size 8U rack mounted to a wall.

In general, I like to keep the footprint small and out of way, but also accessible.

One thought is to go to a mini rack, but then I'd have to get rid of my current switch.

The other concern is the number of ports, which I like to keep connected to RJ45 ports routed to rooms in the house, althrough some are not being used.

:question: Do I disconnect the ports that I'm not using from the patch panel and figure out a solution when I need them :thinking:?

## :cd: OS

### :desktop_computer: Desktop

I don't use many desktop environments. When I do, it's either ChromeOS or Windows 11.

I don't have a desire at the moment to try anything new.

### :material-server: Server

My favorite server OS is Debian which I got used to when I started with Ubuntu. I prefer Debian over Ubuntu, at the moment, due to it's smaller size and just install the applications that I need.

I tried Arch a while ago, but was too finicky to setup and time consuming.

I haven't tried Alpine linux, other than when compiling my own Docker images.

What I would like to try is [NixOS][4] because it's [infractructure as code][3] and it is easy to backup.

## :file_cabinet: NAS

I'd like to have some type of NAS to properly store my files as well has some kind of backup.

I currently have 5TB external drive attached to my [HP Pro desk][1], but it's not backed up in any way and not very compact.

My initial thoughts is to use 4 SSDs on a Raspberry Pi 5 using a [Radxa Penta SATA HAT][2] due to it's compactness, but
the the speeds may suffer due to the RPi's 1 Gbit speeds. :question: Do I actually need more than 1Gbit speeds :thinking:?

## :pencil: Text Editor

I would like to learn [Neovim][5] to become more proficient at editing text files on the command line.

## :clock1: NTP Server

I would like to build a Stratum 1 NTP server using a Raspberry Pi and a GPS module. See [Issue #371][6].

[1]: <../hardware/hp-prodesk-600-g3.md>
[2]: <https://radxa.com/products/accessories/penta-sata-hat/>
[3]: <https://www.redhat.com/en/topics/automation/what-is-infrastructure-as-code-iac>
[4]: <https://nixos.org/>
[5]: <https://neovim.io/>
[6]: <https://github.com/nicholaswilde/homelab/issues/371>
