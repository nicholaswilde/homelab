---
tags:
  - tool
---
# :simple-microeditor: micro

[micro][1] is my editor of choice due to its modernity.

## :hammer_and_wrench: Installation

!!! code ""

    === "apt"
    
        ```shell
        apt install micro
        ```

    === "brew"

        ```shell
        brew install micro
        ```

## :gear: Config

!!! abstract "~/.config/micro/settings.json"

    === "Automated"

        ```shell
        (
          [ -d ~/.config/micro ] || mkdir -p ~/.config/micro
          wget https://github.com/nicholaswilde/dotfiles2/raw/refs/heads/main/.config/micro/settings.json -O ~/.config/micro/settings.json
        )
        ```

    === "Manual"

        ```shell
        # Ctrl + e
        set colorscheme twilight
        set tabsize 2
        set tabtospaces "true"
        ```

## :link: References

[1]: <https://micro-editor.github.io/>
