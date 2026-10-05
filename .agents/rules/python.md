# Python Execution Rules

- **Virtual Environment:** Always run Python scripts using `uv run python <script>`.
- **Dependencies:** Never use raw `pip`. Manage dependencies using `uv add <package>` or `uv remove <package>`.
- **Standards:**
  - Strict PEP 8 compliance.
  - 4-space indentation, snake_case for functions and variables.
  - Type hints enforced on all function signatures.
  - Docstrings required on all public modules, classes, and functions.
  - Imports ordered: Standard library, third-party, local modules (separated by single blank line).
