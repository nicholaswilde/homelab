# Implementation Plan: /consolidate raspi script

## Phase 1: Builder Adaptations
- [x] Verify that all Rust/Go-based builders (like `fd`, `sd`, `bat`, `eza`, `glow`) correctly compile for `armhf+armv6`.
- [x] Create a `builders/projects/btop` definition to handle C++ ARMv6 compilation.
- [x] Create a `builders/projects/fzf` definition for Go ARMv6 compilation.

## Phase 2: Configuration & Environment
- [x] Ensure that dynamic sync entries are defined in `.env` and `.env.tmpl` for all standard packages.
- [x] Verify that `update-reprepro-service.sh` properly imports armv6 debs to the `raspi` codename.

## Phase 3: Cleanup
- [x] Delete `update-raspi.sh` from the repository.
- [x] Remove `update-raspi` task from the root `Taskfile.yml`.
- [x] Regenerate `task-list.txt`.
