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
    bash: _get_comp_words_by_ref: command not found
    ```

This error indicates that `bash-completion` is not correctly set up or sourced. To resolve this, ensure the following:

1.  **Install `bash-completion`**: Make sure the `bash-completion` package is installed on your system.

    !!! code ""

        ```shell
        sudo apt install bash-completion
        ```

2.  **Source `bash_completion.sh`**: Verify that `/etc/profile.d/bash_completion.sh` is sourced in your shell's startup files (e.g., `.bashrc` or `.profile`). This file sets up the `bash-completion` environment.

    !!! code ""

        ```shell
        source /etc/profile.d/bash_completion.sh
        ```

3.  **Run `bat` completion command**: Ensure that the `bat` completion script is loaded. Add the following line to your `~/.bashrc` file:

    !!! code ""

        ```shell
        eval "$(bat --completion bash)"
        ```

    After adding, reload your shell configuration:

    !!! code ""

        ```shell
        source ~/.bashrc
        ```

## :link: References

- <https://github.com/sharkdp/bat>
- <https://github.com/catppuccin/bat>

[1]: <https://github.com/sharkdp/bat>
[2]: <https://github.com/catppuccin/bat>
