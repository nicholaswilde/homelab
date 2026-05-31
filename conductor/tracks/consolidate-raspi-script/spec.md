# Spec: /consolidate raspi script

## :dart: Goal
Consolidate Raspberry Pi 1/Zero (ARMv6) package building and synchronization into the main `builders/` and dynamic `update-reprepro-service.sh` frameworks, deprecating `update-raspi.sh`.

## :gear: Requirements
- Unify any standalone ARMv6 package builds (like `fzf`, `btop`) into modern modular `builders/projects/`.
- Ensure all other ARMv6 packages (like `duf`, `gh`, `glow`, `micro`) are dynamically synced via `SYNC_APPS_GITHUB_REPOS` in `.env` inside `update-reprepro-service.sh`.
- Safely deprecate and delete `update-raspi.sh` from the base reprepro directory.
- Remove `update-raspi` task and dependencies from the root `Taskfile.yml`.
