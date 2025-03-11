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

### ![catppuuccin](https://raw.githubusercontent.com/catppuccin/website/refs/heads/main/public/favicon.png){ width="24" } [Catppuccin][2]

1. Copy your preferred flavor(s) from `src/` to `~/.config/micro/colorschemes`.
2. Add `export "MICRO_TRUECOLOR=1"` to your shell RC file (`bashrc`, `zshrc`, `config.fish`, etc).
3. Open Micro, press `Ctrl+e`, type set `colorscheme catppuccin-<flavor>` (where <flavor> is one of `latte`, `frappe`, `macchiato`, or `mocha`), and press `Enter`.

!!! code

    ```shell
    
    ```

## :link: References

[1]: <https://micro-editor.github.io/>
[2]: <https://github.com/catppuccin/micro>
