---
tags:
  - lxc
  - proxmox
  - docker
---
# ![reactive-resume](https://raw.githubusercontent.com/AmruthPillai/Reactive-Resume/refs/heads/main/apps/artboard/public/favicon.png){ width="32" } Reactive Resume

[Reactive Resume][1] is a one-of-a-kind resume builder that keeps your privacy in mind.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `3000`

!!! code "`homelab/docker/reactive-resume`"

    === "Task"
    
        ```shell
        task up
        ```

    === "Docker Compose"
    
        ```shell
        docker compose up
        ```

## :gear: Config

!!! abstract "`homelab/docker/reactive-resume/.env`"

    ```ini
    --8<-- "reactive-resume/.env.tmpl"
    ```

??? abstract "`homelab/docker/reactive-resume/compose.yaml`"

    ```yaml
    --8<-- "reactive-resume/compose.yaml"
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/reactive-resume.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/reactive-resume.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "reactive-resume/task-list.txt"
    ```

## :link: References

- <https://github.com/AmruthPillai/Reactive-Resume>

[1]: <https://github.com/AmruthPillai/Reactive-Resume>