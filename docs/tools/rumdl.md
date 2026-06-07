---
tags:
 - tool
---
# :memo: rumdl

[rumdl][1] is a high-performance Markdown linter and formatter written in Rust.

## :hammer_and_wrench: Installation

You can install `rumdl` using several common package managers.

!!! code ""

    === "cargo"

        ```shell
        cargo install rumdl
        ```

    === "brew"

        ```shell
        brew install rumdl
        ```

    === "npm"

        ```shell
        npm install -g rumdl
        ```

    === "pip"

        ```shell
        pip install rumdl
        ```

## :gear: Config

`rumdl` can be configured using a `.rumdl.toml` file in the project root.

!!! abstract ".rumdl.toml"

    ```toml
    # Enable/disable specific rules
    [rules]
    # Example rule settings
    MD013 = false # Line length
    ```

To initialize a new configuration file:

```shell
rumdl init
```

## :pencil: Usage

### CLI Commands

**1. Check all Markdown files in the current directory**

!!! code ""

    ```shell
    rumdl check .
    ```

**2. Automatically fix lint issues**

!!! code ""

    ```shell
    rumdl check --fix .
    ```

**3. Format Markdown files**

!!! code ""

    ```shell
    rumdl fmt .
    ```

## :link: References

- <https://github.com/rvben/rumdl>
- <https://rumdl.dev/>

[1]: <https://github.com/rvben/rumdl>
