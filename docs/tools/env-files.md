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

!!! code ".env.tmpl"

    ```shell
    cp .env.tmpl .env
    ```

## :key: Secrets

If secrets are kept in the `.env` file, the file is encrypted using [SOPS][1] and stored as `.env.enc`.

!!! warning

    Storing encrypted secrets in a public repo is risky and is not recommended!

## :handshake: Service

!!! abstract "appname.service"

    ```ini
    [Service]
    EnvironmentFile=/root/git/nicholaswilde/homelab/pve/appname/.env
    ```

## :simple-task: Task

!!! abstract "Taskfile.yml"

    ```yaml
    dotenv:
      - .env
    ```

## :simple-docker: Docker Compose

!!! abstract "compose.yaml"

    ```yaml
    services:
      appname:
        env_file:
          - .env
    ```

## :scroll: Shell Script

!!! abstract "script.sh"

    ```shell
    DEFAULT_VALUE=foo
    source .env
    ```
    
## :link: References

[1]: <./sops.md>
