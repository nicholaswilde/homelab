---
tags:
  - tools
---
# ![gemini](https://cdn.jsdelivr.net/gh/selfhst/icons/png/google-gemini.png){ width="32" } Google Gemini CLI

[Google Gemini CLI][1] is used as an AI agent that can be used directly in a terminal.

I use the Gemini CLI to help generate bash script files and markdown documents for zensical. It is my preferred coding agent at the moment since I already pay for Google One.

## :hammer_and_wrench: Installation

!!! example ""
    
    :material-information-outline: Config path: `~/.gemini/`
    
!!! code ""

    === "npm"
    
        ```shell
        npm install -g @google/gemini-cli
        ```

    === "npx"

        ```shell
        npx https://github.com/google-gemini/gemini-cli
        ```

    ```shell
    gemini
    ```

## :gear: Config

1. Generate a key from [Google AI Studio][2].
2. Set it as an environment variable in your terminal. Replace `YOUR_API_KEY` with your generated key.

!!! code ""

    === ".env"
  
        ```ini
        export GEMINI_API_KEY="YOUR_API_KEY"
        ```

    === "Manual"
    
        ```shell
        export GEMINI_API_KEY="YOUR_API_KEY"
        ```

## :writing_hand: Syntax Files

Syntax files are used to customize the iutput from Gemini.

??? abstract "docs/GEMINI.md"

    ```markdown
    --8<-- "AGENTS.md"
    ```
    
[AGENTS.md files][3] can also be used to enable the use of other AI agents.

Enable `gemini-cli` to use `AGENTS.md` files.

!!! abstract "~/.gemini/settings.json"

    ```json
    { "contextFileName": "AGENTS.md" }
    ```

## :robot: MCP Servers

### :simple-github: GitHub MCP Server

The [GitHub MCP Server][4] can be used to allow Gemini to interact with GitHub repositories.

!!! abstract "~/.gemini/settings.json"

    ```json
    {
        "context": {
            "fileName": "AGENTS.md"
        },
        "mcpServers": {
            "MCP_DOCKER": {
                "command": "docker",
                "args": [
                    "mcp",
                    "gateway",
                    "run"
                ]
            },
            "github": {
                "command": "docker",
                "args": [
                    "run",
                    "-i",
                    "--rm",
                    "-e",
                    "GITHUB_PERSONAL_ACCESS_TOKEN",
                    "ghcr.io/github/github-mcp-server"
                ],
                "env": {
                    "GITHUB_PERSONAL_ACCESS_TOKEN": "$GITHUB_MCP_PAT"
                }
            }
        },
        "security": {
            "auth": {
                "selectedType": "oauth-personal"
            }
        },
        "general": {
            "previewFeatures": true
        }
    }
    ```

- `context.fileName`: Specifies the file to use for context, in this case `AGENTS.md`.
- `general.previewFeatures`: Set to `true` to enable preview features such as Gemini 3.0.
- `GITHUB_MCP_PAT`: This environment variable must be set with your GitHub PAT for the `github` MCP server.

<<<<<<< HEAD
## :palette: Theme
=======
### :simple-proxmox: ProxmoxMCP-Plus

The [ProxmoxMCP-Plus][7] can be used to allow Gemini to interact with Proxmox VE.

!!! abstract "~/tools/gemini/proxmox-mcp-plus/config.json"

    ```json
    --8<-- "gemini/proxmox-mcp-plus/config.json.tmpl"
    ```

!!! abstract "~/.gemini/settings.json"

    ```json
    {
        "mcpServers": {
            "proxmox": {
                "command": "docker",
                "args": [
                    "run",
                    "-i",
                    "--rm",
                    "-v",
                    "/path/to/proxmox-config:/app/proxmox-config",
                    "proxmox-mcp-plus"
                ]
            }
        }
    }
    ```

!!! tip

    Multiple Proxmox nodes can be managed by specifying different configuration files for each server.

!!! abstract "~/.gemini/settings.json"

    ```json
    {
        "mcpServers": {
            "pve01": {
                "command": "docker",
                "args": [
                    "run",
                    "-i",
                    "--rm",
                    "-v",
                    "/path/to/pve01-config:/app/proxmox-config",
                    "proxmox-mcp-plus"
                ]
            },
            "pve02": {
                "command": "docker",
                "args": [
                    "run",
                    "-i",
                    "--rm",
                    "-v",
                    "/path/to/pve02-config:/app/proxmox-config",
                    "proxmox-mcp-plus"
                ]
            }
        }
    }
    ```

#### Build and Load

The Docker image for `proxmox-mcp-plus` needs to be built and loaded manually.

!!! code

    ```shell
    cd tools/gemini/proxmox-mcp-plus
    task load
    ```

### :material-lan: UniFi Network MCP

The [UniFi Network MCP][8] allows Gemini to interact with UniFi Network controllers.

!!! abstract "~/.gemini/settings.json"

    ```json
    {
        "mcpServers": {
          "unifi": {
            "command": "docker",
            "args": [
              "run",
              "-i",
              "--rm",
              "-e", "UNIFI_URL",
              "-e", "UNIFI_USERNAME",
              "-e", "UNIFI_PASSWORD",
              "-e", "UNIFI_SITE",
              "-e", "UNIFI_IGNORE_SSL",
              "ghcr.io/sirkirby/unifi-network-mcp"
            ],
            "env": {
              "UNIFI_URL": "https://unifi.l.nicholaswilde.io",
              "UNIFI_USERNAME": "admin",
              "UNIFI_PASSWORD": "password",
              "UNIFI_SITE": "154bj8wf",
              "UNIFI_IGNORE_SSL": "false"
            }
          }
        }
    }
    ```

!!! tip

    To find the `UNIFI_SITE` value, check the URL in the UniFi GUI. For example, in `https://unifi.l.nicholaswilde.io/network/154bj8wf/dashboard`, the site ID is `154bj8wf`.

## :art: Theme
>>>>>>> 3faf7a4cdccfbb717557099145a721404801d20f

The [Catppuccin theme][6] can be used to customize the appearance of the Gemini CLI.

1. Download the mocha flavor of the Catppuccin theme.

!!! code ""

    ```shell
    wget https://raw.githubusercontent.com/catppuccin/gemini-cli/main/themes/mocha.json -O ${HOME}/.gemini/catppuccin-mocha.json
    ```

2. Add the `theme` property to your `settings.json` file.

!!! abstract "~/.gemini/settings.json"

    ```json
    {
      "theme": "${HOME}/.gemini/catppuccin-mocha.json"
    }
    ```

## :pencil: Usage

Once installed and authenticated, start interacting with Gemini from the shell.

!!! example

    ```shell
    git clone https://github.com/google-gemini/gemini-cli
    cd gemini-cli
    gemini
    > Give me a summary of all of the changes that went in yesterday
    ```

!!! example "Start a chat"

    ```shell
    gemini
    ```

!!! example "Pipe content to the CLI from `stdin`"

    ```shell
    echo "Explain the content of this file docs/README.md" | gemini -p
    ```

!!! example "UniFi Network MCP"

    ```text
    > List all connected clients on my network.
    > Show me the status of my UniFi devices.
    > What are my current firewall rules?
    ```

## List Models

!!! note

    Assuming that your Gemini key is stored in the `GEMINI_API_KEY` environmental variable and `jq` is installed.

!!! code

    ```bash
    curl "https://generativelanguage.googleapis.com/v1beta/models?key=${GEMINI_API_KEY}" | jq -r '.models[].name'
    ```

## :link: References

- <https://github.com/google-gemini/gemini-cli>
- <https://github.com/github/github-mcp-server/blob/6a57e75d729f9767827bc4f96e80ff9bd8538a46/docs/installation-guides/install-gemini-cli.md>
- <https://github.com/catppuccin/gemini-cli>
<<<<<<< HEAD
=======
- <https://github.com/RekklesNA/ProxmoxMCP-Plus>
- <https://github.com/sirkirby/unifi-network-mcp>
>>>>>>> 3faf7a4cdccfbb717557099145a721404801d20f

[1]: <https://github.com/google-gemini/gemini-cli>
[2]: <https://aistudio.google.com/apikey>
[3]: <https://agents.md>
[4]: <https://github.com/github/github-mcp-server>
[5]: <https://github.com/github/github-mcp-server/blob/6a57e75d729f9767827bc4f96e80ff9bd8538a46/docs/installation-guides/install-gemini-cli.md>
[6]: <https://github.com/catppuccin/gemini-cli>
<<<<<<< HEAD
=======
[7]: <https://github.com/RekklesNA/ProxmoxMCP-Plus>
[8]: <https://github.com/sirkirby/unifi-network-mcp>
>>>>>>> 3faf7a4cdccfbb717557099145a721404801d20f
