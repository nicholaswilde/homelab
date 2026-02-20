---
tags:
  - lxc
  - proxmox
  - docker
---
# :robot: MCP Server :desktop_computer:

An [MCP server][1] that serves custom [AGENTS.md files][2] and bash scripts.

This is a Python project designed to serve as an MCP (Multi-Cloud Platform) server. It utilizes FastAPI for the web framework and Uvicorn as the ASGI server. The project also includes an agents-library for managing agent-related rules and prompts.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8080`

!!! code "`homelab/docker/mcp-server`"

    === "Task"
    
        ```shell
        task up
        ```

    === "Docker Compose"
    
        ```shell
        docker compose up
        ```

## :gear: Config

!!! abstract "`homelab/docker/mcp-server/.env`"

    ```ini
    --8<-- "mcp-server/.env.tmpl"
    ```

??? abstract "`homelab/docker/mcp-server/compose.yaml`"

    ```yaml
    --8<-- "mcp-server/compose.yaml"
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/mcp-server.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/mcp-server.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "mcp-server/task-list.txt"
    ```

## :link: References

- <https://github.com/nicholaswilde/mcp-server>

[1]: <https://github.com/nicholaswilde/mcp-server>
[2]: <https://agents.md>