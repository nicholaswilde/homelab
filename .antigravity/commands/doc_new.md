# /doc new `<name>` `<category>`

Automate the creation of new documentation files using existing templates, ensuring consistency with the Zensical style guide.

## Protocol

1. **Validate Input:**
   - Ensure `<name>` is provided.
   - Ensure `<category>` is one of: `apps`, `tools`, `hardware`, `os`.

2. **Select Template:**
   - If `<category>` is `apps`, ask if it's a `docker` app or a generic `lxc/vm` app.
   - Select the corresponding template:
     - `docker` app -> `docs/.template-docker.md.j2`
     - generic app -> `docs/.template.md.j2`
     - `tools` category -> `docs/.template-tool.md.j2`
     - default -> `docs/.template.md.j2`

3. **Variable Substitution:**
   - Use `scripts/doc_new.py` to prompt for:
     - `APP_PORT` (default: 3000)
     - `CONFIG_PATH` (optional)
     - `GITHUB_URL` (for tools)
     - `DESCRIPTION`
     - `TAGS` (comma-separated)

4. **Generate File:**
   - Create the file at `docs/<category>/<name_lower>.md`.
   - Ensure the name is URL-friendly (lowercase, hyphens instead of spaces).

5. **Update Navigation:**
   - Run `task generate-docs-nav` to update the MkDocs navigation.

6. **Announce Completion:**
   - Provide the path to the new documentation file.
