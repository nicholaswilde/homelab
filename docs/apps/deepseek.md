---
tags:
  - lxc
  - vm
  - proxmox
  - docker
---
# ![deepseek](https://cdn.jsdelivr.net/gh/selfhst/icons/svg/deepseek.svg){ width="36" } DeepSeek

[DeepSeek][1] is a self-hosted AI. This instance actually uses [Open WebUI][2] installed with [Ollama][3] that pulls the [DeepSeek model][4].

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8080`

!!! code "`homelab/docker/deepseek`"

    === "Task"
    
        ```shell
        task up
        ```

    === "Docker Compose"
    
        ```shell
        docker compose up
        ```

## :gear: Config

If you'd like Open AI, create an account and [create an API key][5].

!!! abstract "`homelab/docker/deepseek/.env`"

    ```ini
    --8<-- "deepseek/.env.tmpl"
    ```

??? abstract "`homelab/docker/deepseek/compose.yaml`"

    ```yaml
    --8<-- "deepseek/compose.yaml"
    ```

Once Open WebUI is up and running, run the following command to pull the DeepSeek model.

!!! code ""

    === "Task"
        ```shell
        task deepseek
        ```

    === "Manual"

        ```shell
        docker exec -it deepseek bash -c "ollama pull deepseek-r1:1.5b"
        ```

!!! tip

    The above command pulls the `1.5b` [tag][4]. Other `tags` may be used.

The model may be installed [via the web UI][6], but is a bit more involved and beyond the scope of this page.

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/deepseek.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/deepseek.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "deepseek/task-list.txt"
    ```

## :link: References

- <https://www.deepseek.com/>
- <https://openwebui.com/>
- <https://ollama.com/>

[1]: <https://www.deepseek.com/>
[2]: <https://openwebui.com/>
[3]: <https://ollama.com/>
[4]: <https://ollama.com/library/deepseek-r1:1.5b>
[5]: <https://platform.openai.com/api-keys>
[6]: <https://docs.openwebui.com/getting-started/quick-start/starting-with-ollama>
