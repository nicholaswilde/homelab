# AI Agent Instructions (AGENTS.md)

This file serves as the primary entry point for AI agents interacting with this repository.

## Project Context & Architecture

Homelab is a centralized, automated repository managing home infrastructure across Proxmox VE, LXC containers, and Docker applications.

### Directory Layout
- `docker/`: Docker applications with `compose.yaml`, `.env.tmpl`, and `Taskfile.yml`.
- `lxc/`: Proxmox LXC system container configurations, update scripts, and service definitions.
- `pve/`: Proxmox VE node configurations (AdGuard Home, Traefik, Reprepro).
- `docs/`: Technical documentation built with Material for MkDocs / Zensical.
- `scripts/`: Python (`uv`) and Bash automation tooling.
- `vm/`: Virtual machine definitions.

### Infrastructure & Engineering Standards
- **Proxmox LXC Defaults:** Unprivileged (`--unprivileged 0`), Debian Trixie template, DHCP with SLAAC IPv6, nesting enabled (`--features nesting=1`), root SSH key access.
- **Docker Conventions:** Explicit pinned versions (no floating `latest`), `.env.tmpl` templates with SOPS-encrypted `.env.enc`, non-root execution where possible.
- **Scripting:**
  - **Bash:** `#!/usr/bin/env bash`, `set -o pipefail`, ShellCheck compliant, 2-space indent, `main "$@"` entrypoint, Catppuccin Mocha logging with terminal detection.
  - **Python:** Always execute via `uv run python <script>`. Strict PEP 8, type hints, docstrings.
- **Documentation:** MkDocs / Zensical with emoji headings (`# :emoji: Title`), relative `.md` links, Mermaid diagrams.
- **Idempotency & Safety:** All automation must be safe to rerun. Always ask before introducing new programming languages or performing destructive changes.
- **Task & Issue Management:** Track all new features and bug fixes using remote GitHub Issues via `gh` instead of Conductor tracks. Always pipe `gh` commands to `cat` (e.g., `rtk gh issue list | cat`, `gh issue view 123 | cat`) to avoid interactive prompts. Commits must contain `Fixes #<number>` to automatically close issues.

<!-- caveman-begin -->
## Caveman Mode
Respond terse like smart caveman. All technical substance stay. Only fluff die.

Rules:
- Drop: articles (a/an/the), filler (just/really/basically), pleasantries, hedging.
- Fragments OK. Short synonyms. Technical terms exact. Code unchanged.
- Pattern: [thing] [action] [reason]. [next step].
- Not: "Sure! I'd be happy to help you with that."
- Yes: "Bug in auth middleware. Fix:"

Switch level: /caveman lite|full|ultra|wenyan-lite|wenyan-full|wenyan-ultra
Stop: "stop caveman" or "normal mode"

Auto-Clarity: drop caveman for security warnings, irreversible actions, user confused. Resume after.

Boundaries: code/commits/PRs written normal.
<!-- caveman-end -->

<!-- ponytail-begin -->
## Ponytail (Lazy Senior Dev Mode) Guidelines
- **Stop at first rung that holds**:
  1. Need to build at all? (YAGNI)
  2. Already in codebase? Reuse existing helpers/utils/patterns.
  3. Stdlib does it? Use it.
  4. Native platform feature covers it? Use it.
  5. Installed dependency solves it? Use it.
  6. Can be one line? One line.
  7. Only then: write minimum working code.
- **Bug fix = root cause, not symptom**: Fix shared function/path rather than individual callers.
- **Rules**:
  - No unrequested abstractions, boilerplate, or avoidable dependencies.
  - Deletion over addition. Boring over clever. Fewest files possible.
  - Shortest working diff wins once problem understood.
  - Mark deliberate simplifications cutting real corner with `ponytail:` comment naming ceiling and upgrade path.
  - Output: `[code] → skipped: [X], add when [Y].`
<!-- ponytail-end -->

<!-- context-mode-begin -->
## Context-Mode Routing Guidelines
- **Derive, Do Not Dump**: Do NOT use `ctx_execute_file` or `ctx_execute` to dump whole file or full config. Print only specific value, matches, count, or known line range needed.
- **Tool Call Surface**: When using MCP wrappers, call `call_mcp_tool` with `ServerName: "context-mode_context-mode"` (or `"context-mode"`) and `ToolName: "ctx_execute"`, `"ctx_execute_file"`, `"ctx_batch_execute"`, `"ctx_fetch_and_index"`, `"ctx_search"`, or `"ctx_index"`.
- **Mandatory Routing**:
  - For analyze/count/filter/compare/search/parse/transform tasks, write code with `ctx_execute` and print only final answer.
  - For analyzing/exploring inside file, use `ctx_execute_file`. Use native `read_file` only when editing requires exact bytes or small known range.
  - Use `ctx_batch_execute` for multi-command repository reconnaissance.
  - Use `ctx_execute` for shell commands whose output may exceed short fixed answer.
  - Use `ctx_fetch_and_index` for web content, then `ctx_search` to query it.
  - Return only derived answers, concise summaries, selected snippets, or file paths.
<!-- context-mode-end -->

<!-- codegraph-begin -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- codegraph-end -->

<!-- serena-begin -->
## Serena Semantic Code Tools

Serena MCP provides Language Server Protocol (LSP) backed semantic coding tools, token-efficient AST symbol search, reference-aware refactoring, and persistent project memories:

- **Project Activation**: When Serena is available, ensure the workspace is active before querying code. If Serena returns `No active project`, call `activate_project` with the project root directory.
- **Symbol Inspection Over File Dumps**: Do not dump entire source code files into context. Use `get_symbols_overview` for a high-level view of symbols in a file, or `find_symbol` to retrieve specific classes, functions, or methods with their bodies.
- **Pattern & Reference Search**: Use `search_for_pattern` to locate symbols when the exact path is unknown, and `find_referencing_symbols` to analyze blast radius and callers.
- **Atomic Refactoring**: Prefer Serena's reference-aware editing tools (`rename_symbol`, `safe_delete_symbol`, `replace_symbol_body`) over manual regex or line-based text edits when refactoring existing symbols.
- **Persistent Memory**: Use `read_memory`, `write_memory`, and `list_memories` to retrieve or store durable project facts and conventions across agent sessions (`mem:core`).
- **Diagnostics**: Use `get_diagnostics_for_file` to inspect LSP compiler/linter warnings and errors on modified files.
<!-- serena-end -->

<!-- headroom-begin -->
## Headroom MCP (Context Window Compression)
Use Headroom (`headroom`) MCP tools to manage context window consumption on large payloads:
- `headroom_compress`: Shrink large tool outputs or raw data.
- `headroom_retrieve`: Retrieve original content by hash if specific details needed.
- `headroom_stats`: Monitor headroom cache usage.
<!-- headroom-end -->

<!-- ripwire-begin -->
## Ripwire CLI Guidelines

Use `ripwire` CLI (prefixed with `rtk ripwire`) for AST codebase mapping, call graphs, blast radius, and structural queries:

- **CLI First**: Always invoke `rtk ripwire <dir> [flags]` via CLI; do NOT use MCP server.
- **Task Orientation**: `rtk ripwire <dir> --for="<task>"` for ranked signatures and bodies.
- **Task Bundle**: `rtk ripwire <dir> --pack-task="<task>" --legend=compact`.
- **Stack Trace / Error**: `rtk ripwire <dir> --from-trace=FILE --legend=compact` (`-` for stdin).
- **Call Graph**: `rtk ripwire <dir> --callers=SYM`, `--callees=SYM`, `--uses=SYM`.
- **Blast Radius**: `rtk ripwire <dir> --impact=SYM --legend=compact` before changing shared code.
- **Quality Delta & Gate**: `rtk ripwire <dir> --quality-delta --legend=compact` and `--test-gate --legend=compact`.
- **Atomic Edits**: `rtk ripwire <dir> --replace-symbol-body=SYM --edit-payload=FILE` without whole-file re-reading.
<!-- ripwire-end -->

<!-- ripgrep-guidelines-begin -->
## Ripgrep Guidelines
- **Pattern Searching**: Always use `rg` (ripgrep) or `rtk rg` instead of standard `grep` to search text inside files quickly and save token output.
- **Scope**: Use `-t py` for Python files, `-l` for file listing, keep context small (`-C 1`).
<!-- ripgrep-guidelines-end -->

<!-- taplo-rules-begin -->
## Taplo TOML Rules
- **Format**: Run `rtk taplo fmt` to format TOML files in-place.
- **Validation**: Run `rtk taplo lint` to validate TOML syntax and schema.
<!-- taplo-rules-end -->

<!-- uv-rules-begin -->
## Python Tooling & Execution with `uv`
When executing Python scripts in this workspace, always use `rtk uv run python <script>` instead of just `python` to ensure the correct virtual environment and dependencies are used. Do not use pip; use `rtk uv add` for managing dependencies. Keep `uv.lock` and `pyproject.toml` synchronized and committed.
<!-- uv-rules-end -->

## OpenMediaVault (OMV) Networking
When configuring or modifying network settings on an OpenMediaVault (OMV) system, never edit `/etc/netplan` or `/etc/systemd/network` files directly, as they will be overwritten. Instead, read and update the OMV database using `omv-confdbadm` (e.g., `omv-confdbadm read conf.system.network.interface`). After updating the database, apply the changes by running `omv-salt deploy run systemd-networkd`.

## LXC Application Updates
When asked to update LXC web applications, run `scripts/lxc_update.py` directly with `rtk` without probing nodes or manual container inspection:
- `drawio`: `rtk uv run python scripts/lxc_update.py drawio [-v <version>]`
- `localsend`: `rtk uv run python scripts/lxc_update.py localsend`
- `wallos`: `rtk uv run python scripts/lxc_update.py wallos --node pve03`
- `changedetection`: `rtk uv run python scripts/lxc_update.py changedetection --node pve04`
- `stirling-pdf`: `rtk uv run python scripts/lxc_update.py stirling-pdf --node pve04 [-v <version>]`
- `homepage`: `rtk uv run python scripts/lxc_update.py homepage --node pve04 [-v <version>]`
- `convertx`: `rtk uv run python scripts/lxc_update.py convertx --node pve04 [-v <version>]`
- `reactive-resume`: `rtk uv run python scripts/lxc_update.py reactive-resume --node pve04 [-v <version>]`
- `withoutbg`: `rtk uv run python scripts/lxc_update.py withoutbg --node pve03 [-v <version>]`
- `gitea`: `rtk uv run python scripts/lxc_update.py gitea --node pve03 [-v <version>]`
- `bentopdf`: `rtk uv run python scripts/lxc_update.py bentopdf --node pve03`
- `pocket-id`: `rtk uv run python scripts/lxc_update.py pocket-id --node pve03`
- `homebox`: `rtk uv run python scripts/lxc_update.py homebox --node pve03`
- `omni-tools`: `rtk uv run python scripts/lxc_update.py omni-tools --node pve04`
- `gatus`: `rtk uv run python scripts/lxc_update.py gatus --node pve04`
- `vaultwarden`: `rtk uv run python scripts/lxc_update.py vaultwarden --node pve03 [-v <version>]`
- `freshrss`: `rtk uv run python scripts/lxc_update.py freshrss --node pve03`
- `yamtrack`: `rtk uv run python scripts/lxc_update.py yamtrack --node pve03`
- `solidcraft`: `rtk uv run python scripts/lxc_update.py solidcraft --node pve03 [-v <version>]`
- `installer`: `rtk uv run python scripts/lxc_update.py installer --node pve04`
- `cyberkeygen`: `rtk uv run python scripts/lxc_update.py cyberkeygen --node pve04 [-v <version>]`
When updating any web app not yet saved, set up its `update.sh` and persist its details across the 3 layers (Rules in `AGENTS.md` / `.agents/rules/`, Serena memories in `mem:core` / `mem:suggested_commands`, and RTK filters in `.rtk/filters.toml`) to streamline future runs.

## LXC Webhook & Auto-Update Hooks
To configure automated updates for an LXC application via ChangeDetection and Webhook:
- Scaffold, deploy, and register: `rtk uv run python scripts/lxc_webhook.py scaffold <app> && rtk uv run python scripts/lxc_webhook.py deploy <app> && rtk uv run python scripts/lxc_webhook.py cd-watch <app> --repo <owner/repo>`
- Skill: `.agents/skills/webhook-add/SKILL.md` (`/webhook add <app> <repo>`).

<!-- sensitive-information-protection-begin -->
## Security & Sensitive Data Invariants
- **NEVER commit sensitive data**: Never stage or commit passwords, secrets, API tokens, access keys, private keys, authentication credentials, unencrypted `.env` files, or configuration/settings files containing plain-text secrets.
- **Use SOPS for Secret Storage**: All secrets must be encrypted with SOPS (`.env.enc`, `secret.txt.enc`). Commit only `.enc` encrypted files and templates (`.env.tmpl`), never unencrypted secrets.
- **Pre-Commit Verification**: Run `rtk git diff --staged` or `rtk uv run python scripts/check_secrets.py` before committing to verify no plain-text secrets or passwords leak into git.
- **Explicit Staging**: Never use `git add .` when untracked secret files exist; stage explicitly by name.
<!-- sensitive-information-protection-end -->

<!-- rtk-begin -->
## RTK Command Guidelines

Prefix shell commands with `rtk` whenever a filter exists to save context tokens:
- **Git Operations**: `rtk git status`, `rtk git diff`, `rtk git log`, `rtk git commit`, `rtk git push`.
- **GitHub CLI**: `rtk gh issue list | cat`, `rtk gh pr status | cat` (always pipe to `cat` to bypass interactive pagers).
- **File Inspection**: `rtk ls`, `rtk read`, `rtk tree`, `rtk find`.
- **Search**: `rtk rg <pattern>` (preferred over grep).
- **Build & Tests**: `rtk test <cmd>`, `rtk err <cmd>`.
- **Tooling**: `rtk uv run <script>`, `rtk npx <cmd>`.
- **Sandbox Exception**: Inside `ctx_execute` / `ctx_batch_execute` sandbox code, skip `rtk` (only printed output enters context). Drop `rtk` when exact raw bytes or patch required (`git diff` patch).
<!-- rtk-end -->
