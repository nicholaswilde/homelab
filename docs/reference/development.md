---
tags:
  - reference
---
# :construction: Development

The development of my homelab is mainly done by watching YouTube videos and occasionally browsing Reddit.

## :page_facing_up: New Document Pages

New pages for this site can be created using [jinja2][3] and the `.template.md.j2` file.

!!! quote "Create new page"

    ```shell
    jinja2 .template.md.j2 -D app_name="New App" -D app_port=8080 -D config_path=/opt/new-app > new-app.md
    ```

## :link: References

[3]: <../tools/jinja2-cli.md>
