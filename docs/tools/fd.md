---
tags:
 - tool
---
# :file_folder: fd

[fd][1] is a simple, fast, and user-friendly alternative to `find`.

## :hammer_and_wrench: Installation

!!! code ""

    === "reprepro"

        ```shell
        sudo apt install fd-find
        ```

    === "apt"

        ```shell
        sudo apt install fd-find
        ```

    === "brew"

        ```shell
        brew install fd
        ```

## :gear: Config

`fd` can be configured with a configuration file. By default, `fd` will look for a configuration file in `$XDG_CONFIG_HOME/fd/config` or `$HOME/.fdrc`.

!!! abstract "$HOME/.fdrc"

    ```ini
    --hidden
    --exclude .git
    ```

## :pencil: Usage

**1. Find files by name**

!!! code ""

    ```shell
    fd "pattern"
    ```

**2. Find files by extension**

!!! code ""

    ```shell
    fd -e js
    ```

**3. Execute a command on found files**

!!! code ""

    ```shell
    fd ".md" -exec wc -l
    ```

**4. Search hidden files and directories**

!!! code ""

    ```shell
    fd -H "pattern"
    ```

## :link: References

- <https://github.com/sharkdp/fd>

[1]: <https://github.com/sharkdp/fd>