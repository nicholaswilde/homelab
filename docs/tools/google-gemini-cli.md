---
tags:
  - cli
  - google
  - gemini
  - tools
---
# :gem: Google Gemini CLI

The [Google Gemini CLI][1] is a powerful, open-source tool that brings the capabilities of the Gemini models directly to the command-line interface. This allows for interaction with Gemini for a wide range of tasks, from code generation and bug fixing to content creation and in-depth research, all within the familiar terminal environment.

## :hammer_and_wrench: Installation

### :white_check_mark: Prerequisites

- Node.js (version 20 or higher)

### :rocket: Instructions

Run the CLI directly using `npx` or install it globally with `npm`.

!!! code ""

    === "npx"
    
        ```shell
        npx https://github.com/google-gemini/gemini-cli
        ```

    === "npm"
        
        ```shell
        npm install -g @google/gemini-cli
        ```

## :gear: Config

Upon first execution, the CLI will prompt for authentication. Sign in with a personal Google account, which provides a generous free tier of requests. For more demanding use cases, authentication can also be done using a Gemini API key or a Vertex AI API key.

## :pencil: Usage

Once installed and authenticated, start interacting with Gemini from the shell.

### :speech_balloon: Start a chat

```shell
gemini chat
```

### :page_facing_up: Use a file as context

```shell
gemini chat "Explain the content of this file" -f README.md
```

### :arrow_right: Pipe content to the CLI

```shell
cat main.py | gemini chat "what is the purpose of this python script?"
```

## :link: References

- <https://github.com/google-gemini/gemini-cli>
- <https://developers.google.com/gemini/cli>

[1]: https://github.com/google-gemini/gemini-cli
