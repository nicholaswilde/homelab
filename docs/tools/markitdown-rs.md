---
tags:
 - tool
---
# :arrows_counterclockwise: markitdown-rs

[markitdown-rs][1] is a fast, high-performance command-line tool and Rust library for converting various document formats (such as PDF, DOCX, XLSX, PPTX, and more) into Markdown. It is inspired by Microsoft's Python-based `markitdown`.

## :hammer_and_wrench: Installation

You can install `markitdown` via Cargo:

!!! code ""

    ```shell
    cargo install markitdown
    ```

## :gear: Config

`markitdown-rs` runs out of the box with zero configuration.

## :pencil: Usage

### CLI Commands

**1. Convert a file to Markdown (outputs to stdout)**

!!! code ""

    ```shell
    markitdown document.pdf
    ```

**2. Convert a file and save to a specific output file**

!!! code ""

    ```shell
    markitdown document.docx -o document.md
    ```

## :link: References

- <https://github.com/uhobnil/markitdown-rs>
- <https://crates.io/crates/markitdown>

[1]: <https://github.com/uhobnil/markitdown-rs>
