---
tags:
 - tool
---
# :link: lychee

[lychee][1] is a fast, asynchronous link checker written in Rust. It finds broken hyperlinks in Markdown, HTML, and other text files.

## :hammer_and_wrench: Installation

You can download pre-compiled binaries from the [GitHub releases page][2], or install it using a package manager.

!!! code ""

    === "apt"

        ```shell
        sudo apt install lychee
        ```

    === "brew"

        ```shell
        brew install lychee
        ```

    === "cargo"

        ```shell
        cargo install lychee
        ```

## :gear: Config

Lychee can be configured with a configuration file. In this repository, the configuration file is `lychee.toml` at the repo root.

!!! abstract "lychee.toml"

    ```toml
    timeout = 5
    max_retries = 2
    max_concurrency = 20
    accept = [200, 201, 202, 204, 206, 403, 405, 429, 520]
    exclude_all_private = true
    ```

## :pencil: Usage

### Task Tasks

**1. Run link checker (online)**

!!! code ""

    ```shell
    task linkcheck
    ```

**2. Run link checker (offline)**

!!! code ""

    ```shell
    task linkcheck-offline
    ```

**3. Run link checker on a specific file**

!!! code ""

    ```shell
    task linkcheck-file FILE="docs/index.md"
    ```

### CLI Commands

**1. Check links in a directory or file**

!!! code ""

    ```shell
    lychee .
    ```

**2. Check links offline (skip checking external URLs)**

!!! code ""

    ```shell
    lychee --offline .
    ```

**3. Check links in a specific file**

!!! code ""

    ```shell
    lychee file.md
    ```

## :link: References

- <https://github.com/lycheeverse/lychee>

[1]: <https://github.com/lycheeverse/lychee>
[2]: <https://github.com/lycheeverse/lychee/releases>
