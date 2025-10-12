# Project Overview for Gemini

This project contains various utilities, including Bash scripts for automation and Markdown files for documentation.

**General Guidelines:**
- Be concise and clear in all generated content.
- Follow standard practices for the respective file types.
- Prioritize security and efficiency in code.

## Project Structure and Guidelines

This project is organized into several key directories, each with specific guidelines and purposes:

- **`docker/`**: Contains all Docker applications. New applications should be created by copying the `.template` directory and updating the relevant files (`.env.tmpl.j2`, `compose.yaml.j2`, `README.md.j2`, `Taskfile.yml`).
- **`docs/`**: Houses all project documentation in Markdown format, generated using MkDocs with the Material theme. Adheres to specific Markdown style guidelines, including headings with emojis, admonitions, and a consistent content structure for applications, tools, and hardware.
- **`pve/`**: Contains all Proxmox LXC applications. New applications should be created by copying the `.template` directory and updating `README.md`, `Taskfile.yml`, `task-list.txt`, and `update.sh`.
- **`scripts/`**: Stores all project Bash and Python scripts. Both types of scripts have strict coding style guidelines, including shebangs, commented headers, function declarations, variable naming conventions, and logging practices.
- **`vm/`**: Contains configurations and templates for virtual machines.
