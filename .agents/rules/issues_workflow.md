# GitHub Issues Workflow

## Issue Management & Feature Tracking
- **No Conductor Tracks**: Do not create or track features/bugs in `conductor/tracks/` or `conductor/tracks.md`.
- **Use GitHub Issues**: Manage all new features, bug fixes, tasks, and backlogs via remote GitHub Issues using the GitHub CLI (`gh`).

## Non-Interactive `gh` Execution Invariant
- **Always Pipe to `cat`**: When running `gh` commands, always pipe to `cat` (e.g., `rtk gh issue list | cat`, `gh issue view 123 | cat`) or invoke with non-interactive flags (`--json ...`, `-q ...`) to prevent interactive pagers or terminal prompts from hanging execution.
- **Common Command Patterns**:
  - List issues: `rtk gh issue list -L 20 | cat`
  - View issue: `rtk gh issue view <issue-id> | cat`
  - Create issue: `rtk gh issue create --title "<title>" --body "<body>" | cat`
  - Close issue with commit: Include `Fixes #<issue-id>` in git commit message.
