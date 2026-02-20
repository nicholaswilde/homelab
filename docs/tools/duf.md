---
tags:
 - tool
---
# :material-harddisk: duf

[duf][1] is a Disk Usage Free Utility.

## :hammer_and_wrench: Installation

!!! code ""

    === "reprepro"

        ```shell
        sudo apt install duf
        ```

    === "apt"

        ```shell
        sudo apt install duf
        ```

    === "brew"

        ```shell
        brew install duf
        ```

## :pencil: Usage

**1. Show disk usage**

!!! code ""

    ```shell
    duf
    ```

**2. Show all file systems, including pseudo, duplicate, and inaccessible file systems**

!!! code ""

    ```shell
    duf --all
    ```

**3. List only local file systems**

!!! code ""

    ```shell
    duf --local
    ```

**4. Sort the output by a specific column**

!!! code ""

    ```shell
    duf --sort size
    ```

## :link: References

- <https://github.com/muesli/duf>

[1]: <https://github.com/muesli/duf>