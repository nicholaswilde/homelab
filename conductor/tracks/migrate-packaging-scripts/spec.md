# Spec: /migrate packaging scripts

## :dart: Goal
Unify and centralize all source-based compilation and packaging definitions under the modular `builders/` framework, deprecating standalone root-level package scripts.

## :gear: Requirements
- Create dedicated builder project definitions (Taskfiles) for `neovim`, `pvetui`, and `lastpass-cli` under `builders/projects/`.
- Utilize `nfpm` for clean, user-space, non-interactive packaging of built binaries into `.deb` packages.
- Integrate the new projects into the `builders` master Taskfile and check-update sync framework (`sync.sh`).
- Delete legacy standalone scripts `package-neovim.sh`, `package-pvetui.sh`, and `package-lastpass-cli.sh`.
- Remove matching packaging tasks from the root `Taskfile.yml`.
