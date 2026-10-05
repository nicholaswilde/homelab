# Tech Stack

## Infrastructure & Runtime
- **Virtualization:** Proxmox VE (PVE cluster `pve01__`, node `pve04`).
- **Containers:** Docker, Docker Compose, Proxmox LXC (`debian-trixie`).
- **Base OS:** Debian Linux (primary), Ubuntu, Alpine Linux.
- **Reverse Proxy & Routing:** Traefik, WireGuard VPN.
- **DNS / Ad Blocking:** AdGuard Home, Unbound.
- **Secrets Management:** Mozilla SOPS, GnuPG (GPG).
- **Package Repository:** Debian reprepro host (`192.168.1.58`).

## Automation & Scripting
- **Task Runner:** Task (`go-task` via `Taskfile.yml`).
- **Python:** Python >=3.11 managed via `uv` (`uv run python <script>`, `uv add`).
- **Key Python Libraries:** `ruamel.yaml` (comment-preserving YAML), `packaging`, `requests`, `tabulate`.
- **Shell:** Bash (ShellCheck compliant), strict error handling (`set -e`, `set -o pipefail`).
- **Templating:** MiniJinja (`minijinja-cli` for `.tmpl.j2` templates).
- **Markdown Conversion:** `markitdown-rs`.

## Documentation
- **Engine:** MkDocs with Material for MkDocs and Zensical syntax extensions (`pymdown-extensions`).
- **Diagrams:** Mermaid.
- **Linters:** Markdownlint, Yamllint, Linkcheck.

## MCP Integrations
- Proxmox MCP Plus, UniFi Network MCP, Gitea MCP, AdGuard Home MCP, Syncthing MCP, Serena MCP.
