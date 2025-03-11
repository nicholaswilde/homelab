---
tags:
  - tool
---
# :simple-jinja: jinja2-cli

[jinja2-cli][1] is used as a template engine to help generate documents, such as mkdocs markdown pages or traefik config
files.

## :hammer_and_wrench: Installation

!!! code ""

    === "pipx"

        ```shell
        pipx install jinja2-cli
        ```

## :pencil: Usage

!!! example

    ```shell
    jinja2 .template.md.j2 -D APP_NAME="New App" -D APP_PORT=8080 -D CONFIG_PATH=/opt/new-app > new-app.md
    ```

## :link: References

[1]: <https://github.com/mattrobenolt/jinja2-cli>
