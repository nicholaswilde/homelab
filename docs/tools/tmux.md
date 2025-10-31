---
tags:
  - tool
---
# :computer: tmux

[tmux][1] is a terminal multiplexer.

## :hammer_and_wrench: Installation

!!! code ""

    === "apt"

        ```shell
        sudo apt update
        sudo apt install tmux
        ```

    === "brew"

        ```shell
        brew install tmux
        ```

## :gear: Config

A basic `tmux` configuration can be set up in `~/.tmux.conf`.

!!! abstract "~/.tmux.conf"

    ```tmux
    # Set prefix key to 'Ctrl-a'
    set -g prefix C-a
    unbind C-b
    bind C-a send-prefix

    # Enable mouse support
    set -g mouse on

    # Set vi-mode for copy mode
    set-window-option -g mode-keys vi

    # Reload config file
    bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"
    ```

### :cat: Catppuccin Theme

To install the [Catppuccin theme][2] for `tmux`, follow these steps:

1. Clone the Catppuccin `tmux` plugin:

!!! code "Clone Catppuccin tmux plugin"

    ```shell
    git clone https://github.com/catppuccin/tmux ~/.tmux/plugins/catppuccin
    ```

2. Add the plugin to your `~/.tmux.conf` file:

!!! abstract "~/.tmux.conf"

    ```tmux
    set -g @plugin 'catppuccin/tmux'

    # Optional: Set Catppuccin flavor (mocha, macchiato, frappe, latte)
    set -g @catppuccin_flavour 'mocha'

    run '~/.tmux/plugins/tpm/tpm'
    ```

3. Install `tpm` (Tmux Plugin Manager) if you haven't already:

!!! code "Install tpm"

    ```shell
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ```

4. Start a new `tmux` session or reload your `tmux` configuration (`prefix + r`), then press `prefix + I` (capital I) to install the plugin.

## :pencil: Usage

To start a new `tmux` session:

!!! code ""

    ```shell
    tmux new -s my_session
    ```

To detach from a session:

!!! code ""

    ```shell
    tmux detach
    ```

To attach to an existing session:

!!! code ""

    ```shell
    tmux attach -t my_session
    ```

## :link: References

- <https://github.com/tmux/tmux>
- <https://github.com/catppuccin/tmux>

[1]: <https://github.com/tmux/tmux>
[2]: <https://github.com/catppuccin/tmux>
