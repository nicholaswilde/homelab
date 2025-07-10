---
tags:
  - tool
---
# ![gemini](https://cdn.jsdelivr.net/gh/selfhst/icons/png/google-gemini.png){ width="32" } Gemini

[Google Gemini][1] is used as an AI agent that can be used directly in a terminal.

I use the Gemini cli to help generate bash script files and markdown documents for mkdocs-material.

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

## :pencil: Usage

!!! example

    ```shell
    git clone https://github.com/google-gemini/gemini-cli
    cd gemini-cli
    gemini
    > Give me a summary of all of the changes that went in yesterday
    ```

## :link: References

- <https://github.com/google-gemini/gemini-cli>

[1]: <https://github.com/google-gemini/gemini-cli>
[2]: <https://aistudio.google.com/apikey>
