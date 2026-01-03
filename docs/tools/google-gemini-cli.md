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
        "mcpServers": {
            "github": {
                "command": "github-mcp-server",
                "args": ["stdio"],
                "env": {
                    "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_GITHUB_PAT"
                }
            }
        }
    }
    ```

- `GITHUB_PERSONAL_ACCESS_TOKEN`: This environment variable must be set with your GitHub PAT for the `github` MCP server.

### :simple-proxmox: proxmox-mcp-plus

The [proxmox-mcp-plus][7] can be used to allow Gemini to interact with Proxmox VE.

!!! abstract "~/tools/gemini/pve01.config.json"

    ```json
    --8<-- "tools/gemini/pve01.config.json.enc"
    ```

!!! abstract "~/.gemini/settings.json"

    ```json
    {
        "mcpServers": {
            "pve01": {
                "command": "${HOME}/.local/share/uv/tools/proxmox-mcp/bin/python",
                "args": ["-m", "proxmox_mcp.server"],
                "env": {
                    "PROXMOX_MCP_CONFIG": "${HOME}/git/nicholaswilde/homelab/tools/gemini/pve01.config.json"
                }
            },
            "pve04": {
                "command": "${HOME}/.local/share/uv/tools/proxmox-mcp/bin/python",
                "args": ["-m", "proxmox_mcp.server"],
                "env": {
                    "PROXMOX_MCP_CONFIG": "${HOME}/git/nicholaswilde/homelab/tools/gemini/pve04.config.json"
                }
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
            "command": "unifi-network-mcp",
            "env": {
              "UNIFI_HOST": "192.168.1.148",
              "UNIFI_USERNAME": "admin",
              "UNIFI_PASSWORD": "password",
              "UNIFI_PORT": "443",
              "UNIFI_SITE": "154bj8wf",
              "UNIFI_VERIFY_SSL": "false",
              "UNIFI_CONTROLLER_TYPE": "auto"
            }
          }
        }
    }
    ```

!!! tip

    To find the `UNIFI_SITE` value, check the URL in the UniFi GUI. For example, in `https://unifi.l.nicholaswilde.io/network/154bj8wf/dashboard`, the site ID is `154bj8wf`.

### :simple-adguard: AdGuard Home MCP

The [AdGuard Home MCP][9] allows Gemini to interact with AdGuard Home for DNS management.

!!! abstract "~/.gemini/settings.json"

    ```json
    {
        "mcpServers": {
            "adguard": {
                "command": "npx",
                "args": [
                    "-y",
                    "@fcannizzaro/mcp-adguard-home"
                ],
                "env":{
                    "ADGUARD_URL": "http://192.168.2.13",
                    "ADGUARD_USERNAME": "admin",
                    "ADGUARD_PASSWORD": "password"
                }
            }
        }
    }
    ```

### :simple-homeassistant: Home Assistant MCP

The [Home Assistant MCP][10] allows Gemini to interact with Home Assistant for IoT device control.

#### :hammer_and_wrench: Activation

1.  **Add Integration:** Go to your Home Assistant instance, navigate to **Settings** -> **Devices & Services**, and click **Add Integration**. Search for "Model Context Protocol" and add it.
2.  **Generate Token:** Click on your user profile icon in the bottom left corner of the sidebar. Scroll down to the "Long-Lived Access Tokens" section and click **Create Token**. Give it a name (e.g., "Gemini MCP") and copy the generated token.

!!! abstract "~/.gemini/settings.json"

    ```json
    {
        "mcpServers": {
            "homeassistant": {
                "httpUrl": "http://ha.l.nicholaswilde.io:8123/api/mcp",
                "headers": {
                    "Authorization": "Bearer YOUR_LONG_LIVED_ACCESS_TOKEN"
                }
            }
        }
    }
    ```

### :material-fruit-cherries: Nanobanana MCP

The [Nanobanana MCP][11] is used to watch for repository commit updates.

!!! abstract "~/.gemini/settings.json"

    ```json
    {
        "mcpServers": {
            "nano-banana": {
                "command": "nanobanana-mcp-server",
                "env": {
                    "GEMINI_API_KEY": "YOUR_GEMINI_API_KEY"
                }
            }
        }
    }
    ```

## :art: Theme

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
      "ui": {
        "theme": "${HOME}/.gemini/catppuccin-mocha.json"
      }
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
- <https://github.com/nicholaswilde/proxmox-mcp-plus>
- <https://github.com/sirkirby/unifi-network-mcp>
- <https://github.com/fcannizzaro/mcp-adguard-home>
- <https://github.com/zhongweili/nanobanana-mcp-server>

[1]: <https://github.com/google-gemini/gemini-cli>
[2]: <https://aistudio.google.com/apikey>
[3]: <https://agents.md>
[4]: <https://github.com/github/github-mcp-server>
[5]: <https://github.com/github/github-mcp-server/blob/6a57e75d729f9767827bc4f96e80ff9bd8538a46/docs/installation-guides/install-gemini-cli.md>
[6]: <https://github.com/catppuccin/gemini-cli>
[7]: <https://github.com/nicholaswilde/proxmox-mcp-plus>
[8]: <https://github.com/sirkirby/unifi-network-mcp>
[9]: <https://github.com/fcannizzaro/mcp-adguard-home>
[10]: <https://www.home-assistant.io/integrations/mcp/>
[11]: <https://github.com/zhongweili/nanobanana-mcp-server>