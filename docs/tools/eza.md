---
tags:
 - tool
---
# eza

[eza][1] is a modern alternative to `ls`.

## :hammer_and_wrench: Installation

!!! code ""

    === "reprepro"

        ```shell
        sudo apt install eza
        ```

    === "apt"

        ```shell
        sudo mkdir -p /etc/apt/keyrings
        curl -sL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "Types: deb
        URIs: http://deb.gierens.de
        Suites: stable
        Components: main
        Signed-By: /etc/apt/keyrings/gierens.gpg" | sudo tee /etc/apt/sources.list.d/gierens.sources > /dev/null
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.sources
        sudo apt update
        sudo apt install -y eza
        ```

    === "brew"

        ```shell
        brew install eza
        ```

## :gear: Config

eza is backeard compatible with `ls` so you can add to your bash aliases and map it to `ls`.

!!! abstract "~/.bashrc"

    ```bash
    # Check if command exists
    function command_exists(){
      command -v "${1}" &> /dev/null
    }
    
    if command_exists eza; then
      alias ls='eza'
    fi
    ```

!!! code ""

    ```shell
    source ~/.bashrc
    ```

## :pencil: Usage

Here are some common ways to use `eza`, demonstrating its features beyond the standard `ls`.

!!! code "Show detailed long view, all files (including hidden), with a header"

    ```bash
    eza -la --header
    ```
!!! code "Display files as a tree (limited to 2 levels deep)"

    ```bash
    eza --tree --level=2
    ```

!!! tip

    Requires a [Nerd Font][2] to render icons

!!! code "A common alias: long format, all files, icons, and Git status"

    ```bash
    eza -la --icons --git
    ```
!!! code "Sort by file size, largest first"

    ```bash
    eza -l --sort=size --reverse
    ```

## :link: References

[1]: <https://github.com/eza-community/eza>
[2]: <https://www.nerdfonts.com/?hl=en-US>
