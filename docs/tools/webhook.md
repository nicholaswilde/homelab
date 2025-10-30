---
tags:
 - tool
---
# webhook

[webhook][1] is a lightweight incoming webhook server to run shell commands

## :hammer_and_wrench: Installation

You can download pre-compiled binaries from the [GitHub releases page][2].

!!! code ""

    === "reprepro"

        ```shell
        sudo apt install webhook
        ```

    === "apt"

        ```shell
        sudo apt install webhook
        ```

    === "Docker"

        ```shell
        docker pull adnanh/webhook
        ```

    === "brew"

        ```shell
        brew install webhook
        ```

## :gear: Config

webhook is configured using a single JSON or YAML file (e..g., hooks.json) that contains an array of hook definitions.
A minimal hooks.json file looks like this:

=== "YAML"

    !!! abstract "hook.yaml"

        ```yaml
        - id: redeploy-my-app
          execute-command: /var/scripts/redeploy.sh
          command-working-directory: /var/scripts/
        ```

    !!! abstract "`hook.json`"

        ```json
        [
          {
            "id": "redeploy-my-app",
            "execute-command": "/var/scripts/redeploy.sh",
            "command-working-directory": "/var/scripts/"
          }
        ]
        ```

To secure your webhook, you should add a trigger-rule. A common method is to use a secret, which can be passed as a URL parameter or in the payload.

Here is a more secure example that triggers the hook only if the secret "my-secret-token" is provided:

!!! abstract "`hook.json`"

    ```json
    [
      {
        "id": "redeploy-my-app",
        "execute-command": "/var/scripts/redeploy.sh",
        "command-working-directory": "/var/scripts/",
        "trigger-rule": {
          "match": {
            "type": "value",
            "value": "my-secret-token",
            "parameter": {
              "source": "url",
              "name": "secret"
            }
          }
        }
      }
    ]
    ```

## :pencil: Usage

**1. Run the Server**

Start the webhook server, pointing it to your configuration file. By default, it runs on port `9000`.

!!! code ""

    ```shell
    webhook -hooks /etc/webhook/hooks.json -verbose
    ```

- `-hooks`: Specifies the path to your hook configuration file.
- `-verbose`: (Optional) Provides detailed logging.

**2. Trigger the Hook**

You can trigger a hook by sending an HTTP POST request to its endpoint.

!!! code "Simple Hook (no trigger rule)"

    ```shell
    curl -X POST http://your-server-ip:9000/hooks/redeploy-my-app
    ```

!!! code "Secure Hook (with URL secret)"

    ```shell
    curl -X POST http://your-server-ip:9000/hooks/redeploy-my-app?secret=my-secret-token
    ```

The command specified in your hooks.json (`/var/scripts/redeploy.sh` in this example) will then be executed on the server.

## :link: References

- <https://github.com/adnanh/webhook>

[1]: <https://github.com/adnanh/webhook>



