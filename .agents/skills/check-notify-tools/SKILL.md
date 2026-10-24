---
name: check-notify-tools
description: Compare GitHub release notifications with locally installed developer tools (e.g. zensical, task, shuck, uv, lnav). Triggers when checking notifications for tool updates or comparing installed tool versions.
---

# Check Tool Notifications

Compare GitHub release notifications against versions of CLI and developer tools installed locally on the workstation (e.g. `zensical`, `task`, `shuck`, `uv`, `lychee`, `lnav`).

## When to Use
- User asks: "compare tool versions from github notifications and what is locally installed"
- User asks: "check tool notifications"
- User asks: "are there any developer tool updates in github notifications?"
- User asks: "compare zensical or other tool versions with github notifications"

## Command Reference
Always run with `rtk`:

```bash
# Compare unread release notifications with locally installed tools
rtk uv run python scripts/check_notify_tools.py

# Include read notifications in check
rtk uv run python scripts/check_notify_tools.py --all

# Output structured JSON
rtk uv run python scripts/check_notify_tools.py --json
```

## Supported Tools
- **`zensical`**: Checked via local environment / `uv tool list`, upgraded via `uv tool upgrade zensical`.
- **`task`** (`go-task/task`): Checked via `task --version`, upgraded via `brew upgrade go-task`.
- **`shuck`** (`ewhauser/shuck`): Checked via `shuck --version`, upgraded via `brew upgrade ewhauser/tap/shuck`.
- **`lychee`** (`lycheeverse/lychee`): Checked via `lychee --version`.
- **`lnav`** (`tstack/lnav`): Checked via `lnav --version`.
- **`uv`** (`astral-sh/uv`): Checked via `uv --version`, upgraded via `uv self update`.
- **`gh`** (`cli/cli`): Checked via `gh --version`.
- **`sops`** (`getsops/sops`): Checked via `sops --version`.
- **`age`** (`FiloSottile/age`): Checked via `age --version`.
- Any GitHub release repository matching an executable in `$PATH` or in `uv tool list`.

## Output
Displays:
- Tool name
- Installed version
- Notified release version
- Status (`Up to date`, `Update available`, `Not installed`)
- Binary location
- Precise upgrade command (`uv tool upgrade ...`, `brew upgrade ...`, etc.)
