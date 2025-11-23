---
tags:
  - tool
---
# :cat: bat

[bat][1] is a `cat` clone with syntax highlighting and Git integration.

## :hammer_and_wrench: Installation

`bat` is available in the `reprepro` repository.

!!! code ""

    === "amd64"

        ```shell
        sudo apt update
        sudo apt install bat
        ```

    === "arm64"

        ```shell
        sudo apt update
        sudo apt install bat
        ```

On Debian and Ubuntu, the executable might be installed as `batcat` instead of `bat` due to a name conflict with another package. To use `bat` directly, you can create a symbolic link or an alias:

!!! code "Symbolic Link"

    ```shell
    mkdir -p ~/.local/bin
    ln -s /usr/bin/batcat ~/.local/bin/bat
    ```

!!! code "Alias"

    ```shell
    echo "alias bat='batcat'" >> ~/.bashrc
    source ~/.bashrc
    ```

## :gear: Config

`bat` can be configured using a configuration file. You can find the default configuration directory by running `bat --config-dir`.

To set a theme permanently, you can export the `BAT_THEME` environment variable in your shell's configuration file (e.g., `.bashrc` or `.zshrc`).

!!! code "Set Theme"

    ```shell
    export BAT_THEME="TwoDark"
    ```

You can also add new themes by creating a `themes` folder within `bat`'s configuration directory and rebuilding the cache.

!!! code "Add Themes"

    ```shell
    mkdir -p "$(bat --config-dir)/themes"
    # Add theme files to the directory
    bat cache --build
    ```

### :cat: Catppuccin Theme

To install the [Catppuccin theme][2] for `bat`, follow these steps:

!!! code "Install Catppuccin Theme"

    ```shell
    mkdir -p "$(bat --config-dir)/themes"
    curl -Lo "$(bat --config-dir)/themes/Catppuccin-mocha.tmTheme" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin-mocha.tmTheme
    bat cache --build
    ```

To use the Catppuccin theme, set `BAT_THEME` to `Catppuccin-mocha`:

!!! code "Set Catppuccin Theme"

    ```shell
    export BAT_THEME="Catppuccin-mocha"
    ```

## :pencil: Usage

To view a file:

!!! code ""

    ```shell
    bat filename.txt
    ```

To not show line numbers:

!!! code ""

    ```shell
    bat -p config.yaml
    ```

To show line numbers:

!!! code ""

    ```shell
    bat -n config.yaml
    ```

To concatenate multiple files:

!!! code ""

    ```shell
    bat file1.txt file2.txt
    ```

## Troubleshooting

When using `bat` and pressing ++tab++

!!! failure

    ```
    bat /opt/stirk-bash: _get_comp_words_by_ref: command not found
    ```

Need to re-add `/etc/profile./bash_completions.sh`

!!! abstract "/etc/profile./bash_completions.sh"

    ```bash
    # shellcheck shell=sh disable=SC1091,SC2166,SC2268,SC3028,SC3044,SC3054
    # Check for interactive bash and that we haven't already been sourced.
    if [ "x${BASH_VERSION-}" != x -a "x${PS1-}" != x -a "x${BASH_COMPLETION_VERSINFO-}" = x ]; then
    
        # Check for recent enough version of bash.
        if [ "${BASH_VERSINFO[0]}" -gt 4 ] ||
            [ "${BASH_VERSINFO[0]}" -eq 4 -a "${BASH_VERSINFO[1]}" -ge 2 ]; then
            [ -r "${XDG_CONFIG_HOME:-$HOME/.config}/bash_completion" ] &&
                . "${XDG_CONFIG_HOME:-$HOME/.config}/bash_completion"
            if shopt -q progcomp && [ -r /usr/share/bash-completion/bash_completion ]; then
                # Source completion code.
                . /usr/share/bash-completion/bash_completion
            fi
        fi
    
    fi
    ```

## :link: References

- <https://github.com/sharkdp/bat>
- <https://github.com/catppuccin/bat>

[1]: <https://github.com/sharkdp/bat>
[2]: <https://github.com/catppuccin/bat>
