# /dashboard add `<name>` `<group>`

Automate the addition of a new service to the `homepage` dashboard.

## Protocol

1. **Validate Input:**
   - Ensure `<name>` is provided.
   - Ensure `<group>` exists in `pve/homepage/config/services.yaml` (or offer to create a new one).

2. **Prompt for Metadata:**
   - Prompt the user for:
     - `icon`: Simple Icon slug, MDI slug, or URL.
     - `href`: The destination URL (default: `https://<name_lower>.l.nicholaswilde.io`).
     - `description`: Optional brief description.

3. **Update Configuration:**
   - Use `scripts/dashboard_add.py` to parse and append the new service to the specified group.
   - Ensure no duplicate names exist in that group.

4. **Verification:**
   - Announce: "Service `<name>` added to group `<group>` on the dashboard."
   - Provide the updated snippet for the user to review.

5. **Optional Integration:**
   - If called as part of `/deploy`, use the app name and a reasonable default group.
