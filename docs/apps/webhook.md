---
tags:
  - lxc
  - proxmox
---
# :material-webhook: webhook

[webhook][1] is a lightweight incoming webhook server to run shell commands. It is used to trigger scripts automatically, for example, to update the [reprepro](./reprepro.md) repository when a new package is available.

## :hammer_and_wrench: Installation

The `webhook` binary can be downloaded directly from the project's GitHub releases.

!!! code "Install"

    ```shell
    # Download the latest binary for your architecture. This example is for amd64.
    curl -LO https://github.com/adnanh/webhook/releases/download/2.8.0/webhook-linux-amd64.tar.gz
    tar -xvzf webhook-linux-amd64.tar.gz
    sudo mv webhook-linux-amd64/webhook /usr/local/bin/
    ```

## :gear: Config

`webhook` is configured using a `hooks.yaml` file that defines the webhooks and the commands they execute. It is typically run as a systemd service to ensure it's always available.

### :handshake: Service

!!! code "Install service"

    === "Task"
    
        ```shell
        task install-service
        ```
        
    === "Manual"

        ```shell
        sudo cp ./webhook.service /etc/systemd/system/"
        ```

!!! abstract "/etc/systemd/system/webhook.service"

    ```ini
    --8<-- "webhook/webhook.service"
    ```

!!! code "Enable service"

    === "Task"

        ```shell
        (
          task enable && \
          task start && \
          task status
        )
        ```
        
    === "Manual"

        ```shell
        ( 
         sudo systemctl enable webhook.service && \
         sudo systemctl start webhook.service && \
         sudo systemctl status webhook.service
        )
        ```

### :rocket: Hooks

The hooks file defines the endpoints and the commands to be executed. This example shows a hook that triggers the `reprepro` update script.

??? abstract "`homelab/pve/webhook/hooks.yaml`"

    ```yaml
    --8<-- "webhook/hooks.yaml"    
    ```

## :pencil: Usage

### Trigger

To trigger a hook, send an HTTP request to the webhook URL from any machine on your network.

!!! code "Trigger hook"

    ```shell
    # The hook ID from hooks.yaml is specified in the URL
    curl http://<webhook-server-ip>:9000/hooks/redeploy-webhook
    ```

### :scroll: Logs

Logs for the `webhook` service and the scripts it executes are available through `journalctl`. It's helpful to distinguish between the logs from the webhook server itself and the output from the scripts it triggers.

#### Webhook Service Logs

These logs show the activity of the `webhook` server, such as incoming HTTP requests and hook matching. They are useful for debugging triggering issues.

!!! code "View Service Status and Recent Logs"

    === "Task"

        ```shell
        task status
        ```

    === "Manual"

        ```shell
        systemctl status webhook.service
        ```

!!! code "Follow Service Logs"

    ```shell
    journalctl -u webhook.service -f
    ```

#### Script Execution Logs

Thanks to the `logger` command in the hook configuration, the output of the `update-reprepro-service.sh` script is sent to the journal with a specific tag.

!!! code "Follow Script Logs"

    === "Task"

        ```shell
        task follow
        ```

    === "Manual"

        ```shell
        journalctl -f -t reprepro-updater
        ```
        
## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "webhook/task-list.txt"
    ```

## :link: References

- <https://github.com/adnanh/webhook>

[1]: <https://github.com/adnanh/webhook>