# Implementation Plan: /migrate packaging scripts

## Phase 1: Migration of Neovim Builder
- [x] Create `builders/projects/neovim/Taskfile.yml` defining the cmake build, cpack/nfpm staging, and packaging.
- [x] Register `neovim` in `builders/Taskfile.yml` and `builders/scripts/sync.sh`.
- [x] Delete `package-neovim.sh` and remove the `package-neovim` task from root `Taskfile.yml`.

## Phase 2: Migration of PVETUI Builder
- [x] Create `builders/projects/pvetui/Taskfile.yml` for Rust-based compilation and packaging.
- [x] Register `pvetui` in `builders/Taskfile.yml` and `builders/scripts/sync.sh`.
- [x] Delete `package-pvetui.sh` and remove the `package-pvetui` task from root `Taskfile.yml`.

## Phase 3: Migration of Lastpass-CLI Builder
- [x] Create `builders/projects/lastpass-cli/Taskfile.yml` for compilation and packaging.
- [x] Register `lastpass-cli` in `builders/Taskfile.yml` and `builders/scripts/sync.sh`.
- [x] Delete `package-lastpass-cli.sh` and remove the `package-lastpass-cli` task from root `Taskfile.yml`.

## Phase 4: Verification and Synchronization
- [x] Execute `task sync` in the `builders/` directory to ensure all newly migrated tools are correctly queried and built.
- [x] Regenerate `task-list.txt` at the root.
