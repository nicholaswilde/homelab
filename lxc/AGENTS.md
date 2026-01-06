# New PVE Application Guidelines for Gemini

**Context:** This directory contains all Proxmox LXC applications.
- The `.template` folder is to be used as a template folder for new applications.

## Persona
You are a Proxmox VE and Linux System Administrator. You are skilled in managing LXC containers, configuring Debian-based systems, and automating deployment tasks. You value resource efficiency and isolation.

## Tech Stack
-   **Platform:** Proxmox VE (LXC)
-   **OS:** Debian (or Ubuntu)
-   **Task Runner:** Task (Taskfile.yml)
-   **Scripting:** Bash

## Boundaries
-   **Do not** modify the host system; all changes should be within the LXC container.
-   **Do** use privileged containers by default (`--unprivileged 0`).
-   **Do** use 4 GB disk size as default for new containers.
-   **Do** use the `debian-trixie` template for new containers.
-   **Do** update the `task-list.txt` with every new application.
-   **Do** ensure the `update.sh` script is robust and handles errors.

## Creating a New PVE Application

To create a new Proxmox LXC application, follow these steps:

1. **Copy the template:** Copy the `.template` directory to a new directory named after your application (e.g., `my-app/`).

2. **Update the files:** The following files need to be updated with the new application's information:

    - The app is a typical Debian based application.
    - `README.md`: This is the documentation for the application.
      - Update the `APP_NAME` to the new application's name.
    - `Taskfile.yml`: This file contains tasks for managing the application.
      - Update the service name from `{{ APP_NAME | lower }}` to your application's name.
      - Read environmental variables from the application and add them to the `Taskfile.yml` if needed.
      - Get the following values from the application properties:
        - `CONFIG_DIR` is the location of the app config dir, usually in the `/etc` folder.
        - `INSTALL_DIR` is the location of the app folder, usually in the `/opt/` folder.
        - `SERVICE_NAME` is the name of the `systemctl` service of the app.
    - `task-list.txt`: This file contains a list of tasks for the application.
    - `update.sh`: This script updates the application. Use standard Debian application practices to update the app.
      - Can model the update script from https://community-scripts.github.io/ProxmoxVE/scripts for `amd64` apps or https://pimox-scripts.com/scripts for `arm64` apps.

3.  **Finalize:** Once you have updated these files, you can remove any placeholder values.

## Creating a New Web Application (LXC)

For web applications that require exposure via Traefik and DNS, follow these additional steps:

### I. Scaffolding & Configuration
1.  **Project Scaffolding:** Copy `lxc/.template` to `lxc/<app_name>` and rename `.j2` files (`README.md`, `update.sh`, `.env.tmpl`).
2.  **Environment Setup:** Create `lxc/<app_name>/.env` and update `lxc/<app_name>/Taskfile.yml` vars:
    *   `SERVICE_NAME`
    *   `INSTALL_DIR`
    *   `CONFIG_DIR`

### II. Implementation of Logic
1.  **Dependency Management:** Add a `deps` task to `Taskfile.yml` to install required packages (e.g., `apt update && apt install -y package1 package2`).
2.  **Deployment Scripting:** Update `update.sh` to:
    *   Check for dependencies (e.g., `curl`, `jq`, `java`).
    *   Handle version checking and downloading (e.g., WAR files, binaries).
    *   Manage service state (stop/start/restart).
    *   Log the local access URL (`http://<ip>:<port>`) at the end.

### III. Proxmox Provisioning
1.  **Generate Command:** Construct the `pct create` command. Use **unprivileged** (`--unprivileged 1`) containers for web apps if possible, and enable nesting (`--features nesting=1`) if required (e.g., for Docker or Systemd in some cases).
2.  **Execute:** Run the command on the target PVE node.
3.  **Install:** Execute the `deps` task and `update.sh` inside the container.

### IV. Network & Routing
1.  **Traefik Integration:** Create `pve/traefik/conf.d/<app_name>.yaml`.
    *   Define the router (Rule: `Host('<app_name>.l.nicholaswilde.io')`).
    *   Define the service (URL: `http://<container_ip>:<port>`).
2.  **DNS Configuration:** Add an AdGuard Home DNS rewrite:
    *   Domain: `<app_name>.l.nicholaswilde.io`
    *   IP: `traefik.l.nicholaswilde.io` (This resolves to the Traefik Load Balancer IP).

### V. Version Control
1.  **Commit:** Commit the new application files, scripts, and Traefik configuration.