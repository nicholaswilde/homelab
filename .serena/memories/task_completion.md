# Task Completion

## Verification Checklist
1. **Tests & Coverage:**
   - Unit tests written and passing for all changed code.
   - Test coverage meets >80% threshold.
2. **Linting & Code Quality:**
   - Documentation / config: run `task lint` (or `task markdownlint` / `task yamllint` / `task linkcheck`).
   - Recipes / targeted spellcheck: `task spellcheck-file FILE=<path>`.
   - Python code: PEP 8 clean, typed, docstrings present.
   - Shell scripts: ShellCheck clean.
3. **Security Gate:**
   - Verify no `.env`, passwords, or unencrypted secrets are tracked:
     `git ls-files | grep -E "(\.env$|\.key$|\.secret$)"`
4. **Conductor Protocol:**
   - Update `plan.md` tasks (`[~]` -> `[x]`).
   - If completing a Conductor track, automatically move track directory to `conductor/archive/` and update `conductor/tracks.md`.
