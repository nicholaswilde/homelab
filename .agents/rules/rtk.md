# RTK (Rust Token Killer) Rules

## Golden Rule
**Always prefix shell commands with `rtk`**. If filter exists, RTK compresses output. Else, it passes through safely.

**Chain Rule:** Use `rtk` on each command in `&&` chains:
```bash
rtk git add . && rtk git commit -m "msg" && rtk git push
```

## Workflows
- **Git:** `rtk git status`, `rtk git diff`, `rtk git log`, `rtk git add`, `rtk git commit`, `rtk git push`
- **Search & Files:** `rtk rg <pattern>` (prefer over grep), `rtk find <pattern>`, `rtk read <file>`, `rtk ls <path>`
- **Docker / Infra:** `rtk docker ps`, `rtk docker logs <container>`, `rtk docker images`
- **Output Filtering:** `rtk err <cmd>` (errors only), `rtk summary <cmd>`
- **Python / Dependencies:** `rtk uv run <cmd>`
- **Custom Project Filters:** Defined in `.rtk/filters.toml`.
