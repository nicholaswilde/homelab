---
tags:
 - tool
---
# :zap: uv

[uv][1] is an extremely fast, unified Python package and project manager written in Rust. It serves as a drop-in replacement for `pip`, `pip-tools`, `pipx`, `poetry`, `pyenv`, `virtualenv`, and more.

## :hammer_and_wrench: Installation

You can install `uv` using Astral's standalone installer, or via package managers.

!!! code ""

    === "curl (macOS/Linux)"

        ```shell
        curl -LsSf https://astral.sh/uv/install.sh | sh
        ```

    === "powershell (Windows)"

        ```powershell
        powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
        ```

    === "brew"

        ```shell
        brew install uv
        ```

    === "pip/pipx"

        ```shell
        pip install uv
        # or
        pipx install uv
        ```

## :gear: Config

`uv` can be configured globally using a `uv.toml` or per-project in `pyproject.toml` under the `[tool.uv]` table.

!!! abstract "pyproject.toml"

    ```toml
    [tool.uv]
    dev-dependencies = [
        "pytest>=8.0.0",
    ]
    ```

## :pencil: Usage

### Project Management

**1. Initialize a new project**

!!! code ""

    ```shell
    uv init my-project
    ```

**2. Add dependencies**

!!! code ""

    ```shell
    uv add requests
    ```

**3. Run a script/command in the environment**

!!! code ""

    ```shell
    uv run python main.py
    ```

**4. Lock and sync dependencies**

!!! code ""

    ```shell
    uv sync
    ```

### Pip-Compatible Interface

`uv` provides a fast alternative to standard `pip` commands under the `uv pip` namespace.

**1. Create a virtual environment**

!!! code ""

    ```shell
    uv venv
    ```

**2. Install packages**

!!! code ""

    ```shell
    uv pip install -r requirements.txt
    ```

**3. Compile dependencies**

!!! code ""

    ```shell
    uv pip compile pyproject.toml -o requirements.txt
    ```

## :link: References

- <https://github.com/astral-sh/uv>
- <https://astral.sh/uv>

[1]: <https://github.com/astral-sh/uv>
