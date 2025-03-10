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
    jinja2 .template.md.j2 -D app_name="New App" -D app_port=8080 -D config_path=/opt/new-app > new-app.md
    ```

## :link: References

[1]: <https://github.com/mattrobenolt/jinja2-cli>
