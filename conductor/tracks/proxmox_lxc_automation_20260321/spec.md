# Specification: Proxmox LXC Automation

## Overview
This track aims to automate the creation and configuration of Proxmox LXC containers across different node architectures (x86_64 and aarch64/Pimox). The tool will guide the user through node selection, resource allocation, and network configuration to ensure a consistent setup aligned with the project's standards.

## Functional Requirements
1.  **Architecture Detection:** Automatically identify the architecture of the target Proxmox node to select appropriate templates.
2.  **Node Selection:** Prompt the user to select the target Proxmox node if one is not specified.
3.  **Template Management:** Support `debian-12` (Trixie/Bookworm) as the primary OS template.
4.  **Interactive Configuration:** Prompt for:
    - Resource allocation: CPU cores, RAM, Disk size.
    - Network: Bridge name, IP configuration (DHCP or Static), Gateway.
    - Privileges: Toggle between privileged and unprivileged containers (defaulting to the project's standard).
5.  **Automation Interface:** Implement as a `Taskfile` task or a supporting Bash script.
6.  **Password Management:** Integrate with `pass show default-lxc-password` as defined in `workflow.md`.

## Non-Functional Requirements
1.  **Consistency:** Ensure created containers follow the standards in `workflow.md` (unprivileged: 0).
2.  **Idempotency:** The script should handle existing container IDs or names gracefully.
3.  **Error Handling:** Provide clear feedback if a node is unreachable or resources are insufficient.

## Acceptance Criteria
1.  A new LXC can be created on an x86_64 node using the automation.
2.  A new LXC can be created on an aarch64 (Pimox) node using the automation.
3.  The user is prompted for a node if none is specified.
4.  The container is correctly configured with the specified resources and network settings.
5.  The container follows the project's unprivileged status standard.

## Out of Scope
- Automated dashboard integration (this remains a manual post-provisioning step as per `workflow.md`).
- Backup configuration within the creation script.
- Migration between nodes.
