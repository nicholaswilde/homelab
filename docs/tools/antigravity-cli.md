---
tags:
  - tools
---
# :robot: Antigravity CLI

[Antigravity CLI][1] is used as an AI agent that can be used directly in a
terminal.

I use the Antigravity CLI to help generate bash script files and markdown documents
for zensical. It is my preferred coding agent for homelab automation.

I also use the Antigravity CLI to provision Proxmox containers using the provided MCP
servers.

## :hammer_and_wrench: Installation

!!! example ""
    
    :material-information-outline: Config path: `~/.antigravity/`
    
!!! code ""

    ```shell
    curl -fsSL https://antigravity.google/cli/install.sh | bash
    ```

    ```shell
    antigravity
    ```

## :gear: Config

1. Obtain an API key for your preferred AI model.
2. Set it as an environment variable in your terminal. Replace `YOUR_API_KEY` with your generated key.
3. My current [settings.json][12] can be found in my dotfiles repository.

!!! code ""

    === ".env"
  
        ```ini
        export ANTIGRAVITY_API_KEY="YOUR_API_KEY"
        ```

    === "Manual"
    
        ```shell
        export ANTIGRAVITY_API_KEY="YOUR_API_KEY"
        ```

## :writing_hand: Syntax Files

Syntax files are used to customize the iutput from Antigravity.

??? abstract "docs/ANTIGRAVITY.md"

    ```markdown
    --8<-- "AGENTS.md"
    ```
    
[AGENTS.md files][3] can also be used to enable the use of other AI agents.

Enable `antigravity-cli` to use `AGENTS.md` files.

!!! abstract "~/.antigravity/settings.json"

    ```json
    { "contextFileName": "AGENTS.md" }
    ```

## :robot: MCP Servers

[MCP servers](https://modelcontextprotocol.io/docs/getting-started/intro) are used to extract information from my homelab.

### :simple-github: GitHub MCP Server

The [GitHub MCP Server][4] can be used to allow Antigravity to interact with GitHub repositories.

!!! abstract "~/.antigravity/settings.json"

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

The [proxmox-mcp-plus][7] can be used to allow Antigravity to interact with Proxmox VE.

!!! abstract "~/tools/antigravity/pve01.config.json"

    ```json
    --8<-- "tools/antigravity/pve01.config.json.enc"
    ```

!!! abstract "~/.antigravity/settings.json"

    ```json
    {
        "mcpServers": {
            "pve01": {
                "command": "${HOME}/.local/share/uv/tools/proxmox-mcp/bin/python",
                "args": ["-m", "proxmox_mcp.server"],
                "env": {
                    "PROXMOX_MCP_CONFIG": "${HOME}/git/nicholaswilde/homelab/tools/antigravity/pve01.config.json"
                }
            },
            "pve04": {
                "command": "${HOME}/.local/share/uv/tools/proxmox-mcp/bin/python",
                "args": ["-m", "proxmox_mcp.server"],
                "env": {
                    "PROXMOX_MCP_CONFIG": "${HOME}/git/nicholaswilde/homelab/tools/antigravity/pve04.config.json"
                }
            }
        }
    }
    ```

#### Build and Load

The Docker image for `proxmox-mcp-plus` needs to be built and loaded manually.

!!! code

    ```shell
    cd tools/antigravity/proxmox-mcp-plus
    task load
    ```

### :material-lan: UniFi Network MCP

The [UniFi Network MCP][8] allows Antigravity to interact with UniFi Network controllers.

!!! abstract "~/.antigravity/settings.json"

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

The [AdGuard Home MCP][9] allows Antigravity to interact with AdGuard Home for DNS management.

!!! abstract "~/.antigravity/settings.json"

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

The [Home Assistant MCP][10] allows Antigravity to interact with Home Assistant for IoT device control.

#### :hammer_and_wrench: Activation

1.  **Add Integration:** Go to your Home Assistant instance, navigate to **Settings** -> **Devices & Services**, and click **Add Integration**. Search for "Model Context Protocol" and add it.
2.  **Generate Token:** Click on your user profile icon in the bottom left corner of the sidebar. Scroll down to the "Long-Lived Access Tokens" section and click **Create Token**. Give it a name (e.g., "Antigravity MCP") and copy the generated token.

!!! abstract "~/.antigravity/settings.json"

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

!!! abstract "~/.antigravity/settings.json"

    ```json
    {
        "mcpServers": {
            "nano-banana": {
                "command": "nanobanana-mcp-server",
                "env": {
                    "ANTIGRAVITY_API_KEY": "YOUR_API_KEY"
                }
            }
        }
    }
    ```

## :art: Theme

The [Catppuccin theme][6] can be used to customize the appearance of the Antigravity CLI.

1. Download the mocha flavor of the Catppuccin theme.

!!! code ""

    ```shell
    wget https://raw.githubusercontent.com/catppuccin/antigravity-cli/main/themes/mocha.json -O ${HOME}/.antigravity/catppuccin-mocha.json
    ```

2. Add the `theme` property to your `settings.json` file.

!!! abstract "~/.antigravity/settings.json"

    ```json
    {
      "ui": {
        "theme": "${HOME}/.antigravity/catppuccin-mocha.json"
      }
    }
    ```

## :pencil: Usage

Once installed and authenticated, start interacting with Antigravity from the shell. See [Antigravity CLI Commands](antigravity-commands.md) for custom commands available in this project.

!!! example

    ```shell
    git clone https://github.com/nicholaswilde/antigravity-cli
    cd antigravity-cli
    antigravity
    > Give me a summary of all of the changes that went in yesterday
    ```

!!! example "Start a chat"

    ```shell
    antigravity
    ```

!!! example "Pipe content to the CLI from `stdin`"

    ```shell
    echo "Explain the content of this file docs/README.md" | antigravity -p
    ```

!!! example "UniFi Network MCP"

    ```text
    > List all connected clients on my network.
    > Show me the status of my UniFi devices.
    > What are my current firewall rules?
    ```

## List Models

!!! code

    ```bash
    antigravity list-models
    ```

## :link: References

- <https://github.com/nicholaswilde/antigravity-cli>
- <https://github.com/nicholaswilde/proxmox-mcp-plus>
- <https://github.com/sirkirby/unifi-network-mcp>
- <https://github.com/fcannizzaro/mcp-adguard-home>
- <https://github.com/zhongweili/nanobanana-mcp-server>
- <https://github.com/nicholaswilde/dotfiles2/blob/main/.antigravity/settings.json>

[1]: <https://github.com/nicholaswilde/antigravity-cli>
[3]: <https://agents.md>
[4]: <https://github.com/github/github-mcp-server>
[6]: <https://github.com/catppuccin/antigravity-cli>
[7]: <https://github.com/nicholaswilde/proxmox-mcp-plus>
[8]: <https://github.com/sirkirby/unifi-network-mcp>
[9]: <https://github.com/fcannizzaro/mcp-adguard-home>
[10]: <https://www.home-assistant.io/integrations/mcp/>
[11]: <https://github.com/zhongweili/nanobanana-mcp-server>
[12]: <https://github.com/nicholaswilde/dotfiles2/blob/main/.antigravity/settings.json>