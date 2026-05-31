# Implementation Plan: /consolidate raspi script

## Phase 1: Builder Adaptations
- [ ] Verify that all Rust/Go-based builders (like `fd`, `sd`, `bat`, `eza`, `glow`) correctly compile for `armhf+armv6`.
- [ ] Create a `builders/projects/btop` definition to handle C++ ARMv6 compilation.
- [ ] Create a `builders/projects/fzf` definition for Go ARMv6 compilation.

## Phase 2: Configuration & Environment
- [ ] Ensure that dynamic sync entries are defined in `.env` and `.env.tmpl` for all standard packages.
- [ ] Verify that `update-reprepro-service.sh` properly imports armv6 debs to the `raspi` codename.

## Phase 3: Cleanup
- [ ] Delete `update-raspi.sh` from the repository.
- [ ] Remove `update-raspi` task from the root `Taskfile.yml`.
- [ ] Regenerate `task-list.txt`.
