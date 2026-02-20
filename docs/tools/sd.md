---
tags:
 - tool
---
# :material-find-replace: sd

[sd][1] is an intuitive find & replace command line tool.

## :hammer_and_wrench: Installation

!!! code ""

    === "reprepro"

        ```shell
        sudo apt install sd
        ```

    === "apt"

        ```shell
        sudo apt install sd
        ```

    === "brew"

        ```shell
        brew install sd
        ```

## :pencil: Usage

**1. Replace a string**

!!! code ""

    ```shell
    echo "hello world" | sd "world" "there"
    # Output: hello there
    ```

**2. Replace all occurrences of a string**

!!! code ""

    ```shell
    echo "hello world world" | sd -s "world" "there"
    # Output: hello there there
    ```

**3. Replace using regular expressions**

!!! code ""

    ```shell
    echo "foo 123 bar" | sd "\d+" "NUM"
    # Output: foo NUM bar
    ```

**4. Replace in a file (in-place)**

!!! code ""

    ```shell
    sd "old_string" "new_string" file.txt
    ```

## :link: References

- <https://github.com/chmln/sd>

[1]: <https://github.com/chmln/sd>