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

## :pencil: Usage

To view a file:

!!! code ""

    ```shell
    bat filename.txt
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

## :link: References

- <https://github.com/sharkdp/bat>

[1]: <https://github.com/sharkdp/bat>
