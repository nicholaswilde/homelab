# Suggested Commands

## Task Automation (`go-task`)
- `task lint`: Run full lint suite (Yamllint, Markdownlint, Linkcheck).
- `task markdownlint`: Lint markdown documentation.
- `task yamllint`: Lint YAML files.
- `task linkcheck`: Verify documentation hyperlinks.
- `task build`: Build documentation site via Zensical/MkDocs.
- `task serve`: Serve documentation locally on port 8000.
- `task generate-docs-nav`: Regenerate MkDocs navigation tree.
- `task spellcheck-file FILE=<path>`: Run focused spellcheck on a specific file.

## Python via `uv`
- `uv run python <script>`: Execute Python scripts inside virtual environment.
- `uv add <dependency>`: Add dependency to project.

## LXC Application Version Check & Updates
- Version Comparison (read-only):
  - `rtk uv run python scripts/check_app_version.py <app_name>`: Compare installed vs upstream release version.
  - `rtk uv run python scripts/check_app_version.py --all`: Compare all registered homelab apps.
- Generic LXC updater: `rtk uv run python scripts/lxc_update.py <app_name> [-v <version>]` (or via `scripts/homelab_update.py <app_name>`).
  - `localsend`: Directly run `rtk uv run python scripts/lxc_update.py localsend` without probing.
  - `drawio`: Directly run `rtk uv run python scripts/lxc_update.py drawio [-v <version>]`.
  - `wallos`: Directly run `rtk uv run python scripts/lxc_update.py wallos --node pve03`.
  - `changedetection`: Directly run `rtk uv run python scripts/lxc_update.py changedetection --node pve04`.
  - `stirling-pdf`: Directly run `rtk uv run python scripts/lxc_update.py stirling-pdf --node pve04 [-v <version>]`.
  - `homepage`: Directly run `rtk uv run python scripts/lxc_update.py homepage --node pve04 [-v <version>]`.
  - `convertx`: Directly run `rtk uv run python scripts/lxc_update.py convertx --node pve04 [-v <version>]`.
  - `reactive-resume`: Directly run `rtk uv run python scripts/lxc_update.py reactive-resume --node pve04 [-v <version>]`.
  - `withoutbg`: Directly run `rtk uv run python scripts/lxc_update.py withoutbg --node pve03 [-v <version>]`.

## Token-Optimized CLI Commands (`rtk`)
- Always prefix bash shell commands with `rtk` where available:
  - `rtk git status`, `rtk git diff`, `rtk git log`, `rtk git add`, `rtk git commit`
  - `rtk rg <pattern>`, `rtk find <pattern>`, `rtk read <file>`
  - `rtk docker ps`, `rtk docker logs <container>`

## Application Sync & Deployment
- App sync helper: `.gemini/commands/app_sync.md` (`/app sync <app_name>`).
