---
tags:
  - tool
  - ai
---
# :sparkles: Google Jules

[Google Jules][1] is a CLI tool that integrates with Google Gemini to perform software engineering tasks directly in your repository.

## :hammer_and_wrench: Installation

To use Jules with the Google Gemini CLI, you need to install it globally via npm.

!!! code ""

    === "npm"

        ```shell
        npm install -g @google/jules
        ```

## :gear: Config

Jules requires authentication with GitHub.

!!! code "Login"

    ```shell
    jules login
    ```

You may also need to configure it to work with Gemini CLI if it isn't automatically detected, but usually, Gemini CLI calls it directly.

## :pencil: Usage

Jules is primarily used through the Google Gemini CLI using the `/jules` command, but it can also be used standalone.

!!! code "Status"

    ```shell
    jules status
    ```

!!! code "Gemini CLI integration"

    ```shell
    gemini
    > /jules
    ```

## :link: References

- <https://jules.google.com>

[1]: <https://jules.google.com>
