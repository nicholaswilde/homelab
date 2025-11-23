# New PVE Application Guidelines for Gemini

**Context:** This directory contains all Proxmox LXC applications.
- The `.template` folder is to be used as a template folder for new applications.

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
