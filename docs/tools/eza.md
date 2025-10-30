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

WIP

## :link: References

[1]: <https://github.com/eza-community/eza>
