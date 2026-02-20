# Spec: /dashboard integration

## :dart: Goal
Automate the addition of new services to the `homepage` dashboard configuration to ensure it remains a real-time reflection of the homelab's active services.

## :gear: Requirements
- Parse `pve/homepage/config/services.yaml`.
- Support adding new service definitions with standard fields (icon, href, description, status check).
- Integrate with the `/deploy` command to optionally add new deployments to the dashboard.
- Prevent duplicate entries.
