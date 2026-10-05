# Serena MCP Semantic Coding Rules

Serena MCP provides Language Server Protocol (LSP) backed semantic coding tools, token-efficient AST symbol search, reference-aware refactoring, and persistent project memories.

## Project Memories
- Core memories exist in the project:
  - `mem:core`: Top-level source map and invariants.
  - `mem:tech_stack`: Infrastructure, tools, languages, runtimes.
  - `mem:suggested_commands`: Common operations (Taskfile, Python, RTK).
  - `mem:conventions`: Code styles, documentation, and Git conventions.
  - `mem:task_completion`: Quality gates and verification checks.
- Read memory via `read_memory(memory_name: "<name>")`.
- Discover memories via `list_memories`.
- Persist new project invariants via `write_memory`. Follow rules in `mem:memory_maintenance`.

## Code Intelligence & AST Operations
- **AST Exploration:** Use `get_symbols_overview` and `find_symbol` for token-efficient inspection of source files before reading full files.
- **Diagnostics:** Check file diagnostics via `get_diagnostics_for_file`.
- **Semantic Edits & Refactoring:** Use `rename_symbol` and `safe_delete_symbol` for cross-file symbol changes. Use `insert_before_symbol`, `insert_after_symbol`, and `replace_symbol_body` for precise symbol modifications.
- **Activation:** Active project is `homelab`. If switching context, ensure project is active with `activate_project`.
