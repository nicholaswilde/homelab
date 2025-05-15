---
tags:
  - lxc
  - proxmox
  - tool
---
# :clipboard: cheat

[`cheat`][1] allows you to create and view interactive cheatsheets on the
command-line. It was designed to help remind *nix system administrators
of options for commands that they use frequently, but not frequently
enough to remember.

I use this rather than [cheat.sh][2] because I can more easily add and edit my own cheatsheets.

## :hammer_and_wrench: Installation

!!! code ""

    ```shell
    curl https://installer.l.nicholaswilde.io/cheat/cheat?type=script | bash
    ```

## :gear: Config

!!! abstract ""

    === "Automated"

        ```shell
        ```

    === "Manual"

        ```shell
        # conf.yml
        cheatpaths:
          - name: personal
            path: /mnt/storage/cheat/cheatsheets/personal  # this is a separate directory and repository than above
            tags: [ personal ]
            readonly: false 
            ```
        
## :pencil: Usage

!!! example

    ```shell
    cheat gpg
    ```

## :link: References

[1]: <https://github.com/cheat/cheat>
[2]: <https://cheat.sh>
