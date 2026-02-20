# /pve log `<node>` `[service]`

Fetch and summarize recent logs from a specific Proxmox node or service.

## Protocol

1. **Validate Input:**
   - Ensure `<node>` is provided (e.g., `pve01`, `pve03`, `pve04`).
   - `[service]` is optional.

2. **Fetch Logs:**
   - Use `scripts/pve_log.py` to:
     - Fetch cluster logs via `get_cluster_log` (or prefix-specific versions).
     - Filter logs by the specified node.
     - If service is provided, filter by `tag` or `msg` content.
     - Retrieve the last 20-50 lines.

3. **Summarize and Highlight:**
   - Identify entries with high priority (errors/warnings).
   - Format the output for readability.

4. **Announce Completion:**
   - Present the summarized logs to the user.
