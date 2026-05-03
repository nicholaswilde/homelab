---
tags:
  - tool
  - automation
---
# :anchor: Webhook

[Webhook][1] is a lightweight incoming webhook server that allows you to create HTTP endpoints (hooks) on your server, which you can use to execute configured commands.

## :hammer_and_wrench: Installation

!!! code "Debian/Ubuntu"

    ```shell
    apt install webhook
    ```

## :gear: Configuration

Webhooks are defined in a JSON file (typically `hooks.json`). Each hook specifies an ID, the command to execute, and how to handle arguments.

### :material-file-code: Example `hooks.json`

```json
[
  {
    "id": "rebuild-app",
    "execute-command": "/path/to/script.sh",
    "command-working-directory": "/path/to/wd",
    "pass-arguments-to-command": [
      { "source": "string", "name": "--option" },
      { "source": "string", "name": "value" }
    ]
  }
]
```

## :rocket: Service Setup

To run webhook as a background service, create a systemd unit file.

!!! abstract "`/etc/systemd/system/webhook.service`"

    ```ini
    [Unit]
    Description=Webhook Listener
    After=network.target

    [Service]
    Type=simple
    User=root
    WorkingDirectory=/path/to/working/dir
    ExecStart=/usr/bin/webhook -hooks /path/to/hooks.json -verbose -port 9000
    Restart=on-failure
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    ```

!!! code "Enable Service"

    ```shell
    systemctl daemon-reload
    systemctl enable --now webhook
    ```

## :link: References

- <https://github.com/adnanh/webhook>

[1]: <https://github.com/adnanh/webhook>
