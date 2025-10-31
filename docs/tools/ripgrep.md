---
tags:
 - tool
---
# :magnify: ripgrep

[ripgrep][1] is a line-oriented search tool that recursively searches your current directory for a regex pattern.

## :hammer_and_wrench: Installation

You can download pre-compiled binaries from the [GitHub releases page][2].

!!! code ""

    === "reprepro"

        ```shell
        sudo apt install ripgrep
        ```

    === "apt"

        ```shell
        sudo apt install ripgrep
        ```

    === "brew"

        ```shell
        brew install ripgrep
        ```

## :gear: Config

Ripgrep can be configured with a configuration file. By default, ripgrep will look for a configuration file in `$XDG_CONFIG_HOME/ripgrep/config` or `$HOME/.ripgreprc`.

!!! abstract "$HOME/.ripgreprc"

    ```ini
    --type-not=markdown
    --smart-case
    ```

## :pencil: Usage

**1. Find a pattern in a file**

!!! code ""

    ```shell
    rg "pattern" file.txt
    ```

**2. Recursively search for a pattern**

!!! code ""

    ```shell
    rg "pattern"
    ```

**3. Find files that contain a pattern**

!!! code ""

    ```shell
    rg -l "pattern"
    ```

**4. Search for a pattern in a specific file type**

!!! code ""

    ```shell
    rg "pattern" -g "*.js"
    ```

## :link: References

- <https://github.com/BurntSushi/ripgrep>

[1]: <https://github.com/BurntSushi/ripgrep>
[2]: <https://github.com/BurntSushi/ripgrep/releases>
