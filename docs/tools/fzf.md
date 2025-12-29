---
tags:
  - cli
  - search
---
# :search: fzf

[fzf][1] is a general-purpose command-line fuzzy finder. It's an interactive Unix filter for command-line that can be used with any list; files, command history, processes, hostnames, bookmarks, git commits, etc.

## :hammer_and_wrench: Installation

`fzf` can be installed using the system's package manager.

!!! code ""

    === "amd64"

        ```shell
        sudo apt update && \
        sudo apt install -y fzf
        ```

    === "arm64"

        ```shell
        sudo apt update && \
        sudo apt install -y fzf
        ```

### :gear: Shell Integration

To enable key bindings and fuzzy completion, add the following to your shell configuration file.

=== "Bash"

    Add to `~/.bashrc`:

    ```shell
    eval "$(fzf --bash)"
    ```

=== "Zsh"

    Add to `~/.zshrc`:

    ```shell
    source <(fzf --zsh)
    ```

## :pencil: Usage

After setting up shell integration, you can use the following key bindings:

- `Ctrl+R`: Fuzzy search command history.
- `Ctrl+T`: Fuzzy search files in the current directory and paste the path to the command line.
- `Alt+C`: Fuzzy search subdirectories and `cd` into the selected one.

### Examples

**Kill a process:**

```shell
kill -9 **<TAB>
```

**SSH to a host:**

```shell
ssh **<TAB>
```

**Search environment variables:**

```shell
env | fzf
```

## :rocket: Upgrade

!!! code ""

    === "Apt"

        ```shell
        sudo apt update && \
        sudo apt upgrade fzf
        ```

## :link: References

- <https://www.howtogeek.com/these-fzf-tricks-will-transform-how-you-use-the-linux-terminal/>
- <https://github.com/junegunn/fzf>

[1]: <https://github.com/junegunn/fzf>
