---
tags:
  - tools
---
# ![gemini](https://cdn.jsdelivr.net/gh/selfhst/icons/png/google-gemini.png){ width="32" } Google Gemini CLI

[Google Gemini CLI][1] is used as an AI agent that can be used directly in a terminal.

I use the Gemini CLI to help generate bash script files and markdown documents for mkdocs-material. It is my preferred coding agent at the moment since I already pay for Google One.

## :hammer_and_wrench: Installation

!!! example ""
    
    :material-information-outline: Config path: `~/.gemini/`
    
!!! code ""

    === "npx"

        ```shell
        npx https://github.com/google-gemini/gemini-cli
        ```

    === "npm"
    
        ```shell
        sudo npm install -g @google/gemini-cli
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

!!! abstact "~/.gemini/settings.json"

    ```json
    { "contextFileName": "AGENTS.md" }
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

## :link: References

- <https://github.com/google-gemini/gemini-cli>

[1]: <https://github.com/google-gemini/gemini-cli>
[2]: <https://aistudio.google.com/apikey>
[3]: <https://agents.md>
