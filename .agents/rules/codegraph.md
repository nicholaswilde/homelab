# CodeGraph Rules

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root):

- **Reach for CodeGraph FIRST** before `grep`, `find`, or dumping file contents when locating symbols, architecture flows, call paths, or blast radiuses.
- **MCP Tool:** Call `codegraph_explore` (server: `codegraph`) with query describing the symbol, function, or call flow.
- **Shell Command:** `codegraph explore "<query>"` if running from shell.
- **Status & Maintenance:** Run `codegraph status` to check index freshness.
- **Trust Results:** CodeGraph returns verbatim AST parsed source lines and hops. Avoid redundant re-reading of returned symbols.
