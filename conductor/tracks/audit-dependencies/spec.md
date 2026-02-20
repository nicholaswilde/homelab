# Spec: /audit dependencies

## :dart: Goal
Maintain homelab security and performance by identifying outdated or vulnerable Docker images and dependencies.

## :gear: Requirements
- Scan all `compose.yaml` files for image tags.
- Query container registries (Docker Hub, GHCR) for newer versions.
- Report outdated versions and suggest updates.
- Check for security advisories related to current image versions if possible.
