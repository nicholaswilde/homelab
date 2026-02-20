# /deploy `<app_name>` `<type>`

Automate the creation of a new application directory in `docker/` or `lxc/`
based on existing templates, ensuring all steps in `conductor/workflow.md`
are followed.

## Protocol

1. **Validate Input:**
   - Ensure `<app_name>` is provided and contains only lowercase letters, numbers,
     and hyphens.
   - Ensure `<type>` is either `docker` or `lxc`.

2. **Prepare Target Directory:**
   - Resolve the target path: `docker/<app_name>` or `lxc/<app_name>`.
   - If the directory already exists, announce an error and halt.
   - Create the directory.

3. **Copy Template Files:**
   - Identify the source template directory: `docker/.template/` or `lxc/.template/`.
   - Copy all files from the template directory to the target directory.

4. **Variable Substitution:**
   - For each `.j2` file in the target directory:
     - Parse the file for Jinja2-style variables (`{{ VAR_NAME }}`).
     - For each unique variable found:
       - If `VAR_NAME` is `APP_NAME`, use the provided `<app_name>`.
       - If `VAR_NAME` is `USER_NAME` and the environment has a default (e.g., from
         `git config`), use it.
       - Otherwise, use the `ask_user` tool to request the value from the user.
     - Substitute all variables in the file's content.
     - Write the substituted content to a new file without the `.j2` extension.
     - Delete the original `.j2` file.

5. **Finalize Scaffolding:**
   - If the type is `docker`, ensure `compose.yaml` is present and correctly configured.
   - If the type is `lxc`, ensure `Taskfile.yml` and `update.sh` are present.

6. **Create Deployment Track:**
   - Create a new track folder: `conductor/tracks/deploy-<app_name>/`.
   - Create `conductor/tracks/deploy-<app_name>/spec.md` with a basic goal to finalize
     the deployment.
   - Create `conductor/tracks/deploy-<app_name>/plan.md` with standard tasks (e.g.,
     "Configure environment", "Start service", "Verify functionality").
   - Create `conductor/tracks/deploy-<app_name>/metadata.json`.
   - Add the new track to `conductor/tracks.md`:
     `- [Deploy <app_name>](conductor/tracks/deploy-<app_name>/) [ ]`

7. **Dashboard Integration (Optional):**
   - Ask the user if they would like to add the service to the `homepage` dashboard.
   - If yes, use `/dashboard add <app_name> <group>` to register it.

8. **Announce Completion:**
   - Provide the path to the new application directory and the new track.
