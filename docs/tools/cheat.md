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

!!! code "Make the config dir"

    ```shell
    mkdir -p ~/.config/cheat
    ```

!!! abstract "~/.config/cheat/conf.yml"

    === "Automated"

        ```shell
        cat > ~/.config/cheat/conf.yml <<EOF
        ---
        cheatpaths:
          - name: community                
            path: /mnt/storage/cheat/cheatsheets/community
            tags: [ community ]            
            readonly: true

          - name: personal
            path: /mnt/storage/cheat/cheatsheets/personal  # this is a separate directory and repository than above
            tags: [ personal ]
            readonly: false
        EOF
        ```

    === "Manual"

        ```yaml
        ---
        cheatpaths:
          - name: community                
            path: /mnt/storage/cheat/cheatsheets/community
            tags: [ community ]            
            readonly: true

          - name: personal
            path: /mnt/storage/cheat/cheatsheets/personal
            tags: [ personal ]
            readonly: false 
        ```

!!! code "Download cheatsheets locally"

    ```shell
    (
      mkdir -p /mnt/storage/cheat/cheatsheets
      git clone git@github.com:nicholaswilde/cheatsheets.git /mnt/storage/cheat/cheatsheets/personal
    )
    ```

## :pencil: Usage

!!! code "Show gpg cheatsheet"

    ```shell
    cheat gpg
    ```

!!! code "Edit gpg cheatsheet"

    ```shell
    cheat -e gpg
    ```

## :link: References

[1]: <https://github.com/cheat/cheat>
[2]: <https://cheat.sh>