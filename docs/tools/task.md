---
tags:
 - tool
---
# :simple-task: Task

[Task][1] is used to help automate tasks, such as `make`.

## :hammer_and_wrench: Installation

!!! quote ""

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

!!! quote "Change to app directory"

    ```shell
    cd pve/<appname>
    ```

!!! quote "List available commands"

    ```shell
    task
    ```

!!! quote "Run task"

    ```shell
    task restart
    ```

## :link: References

[1]: <https://taskfile.dev/>
