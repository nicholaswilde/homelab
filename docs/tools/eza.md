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
        sudo apt install eza
        ```

    === "brew"

        ```shell
        brew install eza
        ```

## :gear: Config

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

!!! code "A common alias: long format, all files, icons, and Git status"

    ```bash
    eza -l --sort=size --reverse
    ```
    
## :link: References

[1]: <https://github.com/eza-community/eza>
