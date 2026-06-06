---
tags:
  - tool
---
# :simple-jinja: minijinja-cli

[minijinja-cli][1] is used as a template engine to help generate documents, such as mkdocs markdown pages or traefik config
files.

## :hammer_and_wrench: Installation

!!! code ""

    === "Homebrew"

        ```shell
        brew install minijinja-cli
        ```

    === "Cargo"

        ```shell
        cargo install minijinja-cli
        ```

## :pencil: Usage

!!! example

    ```shell
    minijinja-cli .template.md.j2 -D APP_NAME="New App" -D APP_PORT=8080 -D CONFIG_PATH=/opt/new-app > new-app.md
    ```

## :link: References

[1]: <https://github.com/mitsuhiko/minijinja>
