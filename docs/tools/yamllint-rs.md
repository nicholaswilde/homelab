---
tags:
 - tool
---
# :page_with_curl: yamllint-rs

[yamllint-rs][1] is a fast, high-performance YAML linter written in Rust, designed as a drop-in replacement for the Python-based `yamllint`.

## :hammer_and_wrench: Installation

You can install `yamllint-rs` using Cargo, or run it via Docker.

!!! code ""

    === "cargo"

        ```shell
        cargo install yamllint-rs
        ```

    === "docker"

        ```shell
        docker run --rm -v $(pwd):/work -w /work yamllint-rs:latest --recursive .
        ```

## :gear: Config

`yamllint-rs` is compatible with the standard `yamllint` configuration format. It automatically discovers and uses `.yamllint` files in the project root.

!!! abstract ".yamllint"

    ```yaml
    ---
    extends: default

    rules:
      line-length:
        max: 120
        allow-non-breakable-words: true
    ```

## :pencil: Usage

### CLI Commands

**1. Lint a specific file or folder**

!!! code ""

    ```shell
    yamllint-rs file.yaml
    ```

**2. Lint all YAML files recursively in the current directory**

!!! code ""

    ```shell
    yamllint-rs --recursive .
    ```

**3. Automatically fix autofixable violations**

!!! code ""

    ```shell
    yamllint-rs --fix .
    ```

## :link: References

- <https://github.com/AvnerCohen/yamllint-rs>
- <https://crates.io/crates/yamllint-rs>

[1]: <https://github.com/AvnerCohen/yamllint-rs>
