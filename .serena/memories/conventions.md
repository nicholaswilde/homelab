# Conventions

## Bash Scripting
- Shebang: `#!/usr/bin/env bash`.
- Safe defaults: `set -e`, `set -o pipefail`.
- Style: 2-space indentation, `function` keyword for definitions, UPPERCASE constants.
- Logic encapsulation: entrypoint function `main "$@"` at end of file.
- Logging: `log "INFO|WARN|ERRO|DEBU" "message"` formatted with Catppuccin Mocha colors.
- Linting: ShellCheck compliant.

## Python Scripting
- Shebang: `#!/usr/bin/env python3`.
- Style: Strict PEP 8, 4-space indentation, `snake_case` functions/variables.
- Type hints: Enforced on all function signatures.
- Docstrings: Required on all public functions, classes, and modules.
- Imports: Standard library -> third-party -> local (separated by blank lines).

## Documentation (MkDocs & Zensical)
- Structure: App docs in `docs/apps/`, tools in `docs/tools/`, hardware in `docs/hardware/`.
- Headings: ATX headings with Material emoji shortcodes (`# :emoji: Title`).
- Links: Relative links pointing to `.md` files; numbered reference links at document bottom.
- Admonitions: Zensical syntax (`!!! note`, `!!! tip`, `!!! warning`, `!!! danger`).

## Git & Commits
- Commit messages: Conventional Commits format (`type(scope): description`). Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.
- Auto-closing issues: requires `Fixes #<issue>` pushed to remote.
- Never commit secrets, credentials, or `.env` files.
