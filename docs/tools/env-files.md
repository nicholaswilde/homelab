---
tags:
 - tool
---
# :pencil: .env Files

`.env` files are used to store variables and secrets. There are used whenver possible.

!!! note

    Because they can hold secrets, they are ignored by git.

## :material-content-copy: Template

Since the file is ignored by git, the template file may be copied, if it exists.

!!! quote ".env.tmpl"

    ```shell
    cp .env.tmpl .env
    ```

## :key: Secrets

If secrets are kept in the `.env` file, the file is encrypted using [SOPS][1] and stored as `.env.enc`.

## :pencil: Service

WIP

## :simple-task: Task

WIP

## :simple-docker: Docker Compose

WIP

## :link: References

[1]: <./sops.md>
