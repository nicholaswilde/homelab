# /dashboard add `<name>` `<group>`

Automate the addition of a new service to the `homepage` dashboard.

## Protocol

1. **Validate Input:**
   - Ensure `<name>` is provided.
   - Ensure `<group>` exists in `pve/homepage/config/services.yaml` (or offer to create a new one).

2. **Verify and Prompt for Metadata:**
   - **Icon Selection & Validation:**
     - Research the correct icon slug or URL.
     - **Simple Icons:** Use `si-<slug>`. Verify the slug at [simpleicons.org](https://simpleicons.org/) or via search.
     - **Material Design Icons:** Use `mdi-<name>`. Verify the name at [pictogrammers.com/library/mdi/](https://pictogrammers.com/library/mdi/).
     - **Selfh.st Icons:** Use `sh-<name>`. Research available icons at [selfh.st/icons/](https://selfh.st/icons/).
     - **Direct URL:** If no shortcode exists, find a high-quality SVG or PNG URL (e.g., from official GitHub repos or [homelab-svg-assets](https://github.com/loganmarchione/homelab-svg-assets)).
   - **Prompt/Confirm:**
     - `icon`: The verified shortcode or URL.
     - `href`: The destination URL (default: `https://<name_lower>.l.nicholaswilde.io`).
     - `description`: Optional brief description.

3. **Update Configuration:**
   - Use `scripts/dashboard_add.py` to parse and append the new service to the specified group.
   - The script will automatically calculate and update the `columns` setting in `pve/homepage/config/settings.yaml` to ensure the category remains balanced (max 4 columns).
   - Ensure no duplicate names exist in that group.

4. **Verification:**
   - Announce: "Service `<name>` added to group `<group>` on the dashboard."
   - Provide the updated snippet for the user to review.

5. **Optional Integration:**
   - If called as part of `/deploy`, use the app name and a reasonable default group.
