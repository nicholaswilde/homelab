---
tags:
 - tool
---
# :material-share-variant: LocalSend

[LocalSend][1] is a free and open-source cross-platform app that allows you to securely share files and messages with nearby devices over your local network without the need for an internet connection.

## :hammer_and_wrench: Installation

!!! code ""

    === "apt"

        ```shell
        sudo apt install localsend
        ```

    === "brew"

        ```shell
        brew install localsend
        ```

## :pencil: Usage

**1. Send a file**

!!! code ""

    ```shell
    localsend send <file_path>
    ```

**2. Receive files**

!!! code ""

    ```shell
    localsend receive
    ```

**3. List nearby devices**

!!! code ""

    ```shell
    localsend discover
    ```

## :link: References

- <https://github.com/localsend/localsend>

[1]: <https://github.com/localsend/localsend>