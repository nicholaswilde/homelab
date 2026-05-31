# Implementation Plan: /migrate packaging scripts

## Phase 1: Migration of Neovim Builder
- [ ] Create `builders/projects/neovim/Taskfile.yml` defining the cmake build, cpack/nfpm staging, and packaging.
- [ ] Register `neovim` in `builders/Taskfile.yml` and `builders/scripts/sync.sh`.
- [ ] Delete `package-neovim.sh` and remove the `package-neovim` task from root `Taskfile.yml`.

## Phase 2: Migration of PVETUI Builder
- [ ] Create `builders/projects/pvetui/Taskfile.yml` for Rust-based compilation and packaging.
- [ ] Register `pvetui` in `builders/Taskfile.yml` and `builders/scripts/sync.sh`.
- [ ] Delete `package-pvetui.sh` and remove the `package-pvetui` task from root `Taskfile.yml`.

## Phase 3: Migration of Lastpass-CLI Builder
- [ ] Create `builders/projects/lastpass-cli/Taskfile.yml` for compilation and packaging.
- [ ] Register `lastpass-cli` in `builders/Taskfile.yml` and `builders/scripts/sync.sh`.
- [ ] Delete `package-lastpass-cli.sh` and remove the `package-lastpass-cli` task from root `Taskfile.yml`.

## Phase 4: Verification and Synchronization
- [ ] Execute `task sync` in the `builders/` directory to ensure all newly migrated tools are correctly queried and built.
- [ ] Regenerate `task-list.txt` at the root.
