---
tags:
 - tool
---
# :simple-task: Task

[Task][1] is used to help automate tasks, such as `make`.

## :hammer_and_wrench: Installation

!!! code ""

    === "reprepeo"

        ```shell
        apt install task
        ```
        
    === "installer"
    
        ```shell
        curl https://installer.l.nicholaswilde.io/go-task/task! | bash
        ```

## :gear: Config

Most apps should have `Taskfiles.yml` in their directories to help manage the apps.

## :pencil: Usage

!!! code "Change to app directory"

    ```shell
    cd pve/<appname>
    ```

!!! code "List available commands"

    ```shell
    task
    ```

!!! code "Run task"

    ```shell
    task restart
    ```

## :broom: Common Tasks

| Task        | Description  |
| :---------: | ------------ |
| `serve`   | Start a web server        |
| `up`      | Start a Docker container  |
| `restart` | Restart a systemd service |
| `upgrade` | Update the repo and update the running Docker container |
| `update`  | Update the running Docker container |
| `mklinks` | Make symlinks to config files |
| `deps`    | Install dependencies |

## :link: References

[1]: <https://taskfile.dev/>
