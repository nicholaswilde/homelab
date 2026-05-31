# :package: Reprepro Repository Service

This directory manages the local Debian/Ubuntu/Raspberry Pi package repositories using `reprepro`. It hosts custom and synchronized `.deb` packages for the homelab infrastructure.

## :gear: Architecture

The package repository structure is split into three main distributions:
1. **Debian** (Suites: `bullseye`, `bookworm`, `trixie`)
2. **Ubuntu** (Suites: `jammy`, `noble`, `oracular`, `plucky`, `questing`)
3. **Raspberry Pi** (Suites: `bookworm`, `trixie` under `raspi` distribution codename)

The system consists of:
- **`builders/`**: A unified, modular builder system that manages compilation and packaging of custom packages (e.g., Neovim, fzf, btop, sops, restic, lnav) for various architectures including standard `amd64` and `armv6/armhf`.
- **`update-reprepro-service.sh`**: The main synchronization and import script that fetches dynamic packages from GitHub and adds built `.deb` packages to the repository.
- **Webhook Listener**: A systemd service (`reprepro-webhook.service`) running on port `9000` that triggers automated builds and repository updates.

---

## :hammer_and_wrench: Task Runner Commands

Use the local `Taskfile.yml` to manage repository operations:

- **Initialize environment**: `task init` (Creates `.env` from template)
- **Decrypt secrets**: `task decrypt` (Decrypts `.env.enc` using SOPS)
- **Encrypt secrets**: `task encrypt` (Encrypts `.env` to `.env.enc` using SOPS)
- **Bootstrap repository**: `task bootstrap` (Installs system dependencies, creates directory structure, and symlinks configurations)
- **List packages**: `task list` (Lists all package versions in the repository)
- **Run update sync**: `task update-reprepro` (Manually triggers `update-reprepro-service.sh` to download and import packages)
- **Manage Webhook Service**:
  - Install service: `task wh:install`
  - View service logs: `task wh:logs`
  - Check status: `task wh:status`
  - Test webhook: `task wh:test`

---

## :key: GPG Repository Signing

The repository uses GPG to sign release indices:
- Public key: `public.gpg.key`
- Clients must trust this key to install packages without warnings:
  ```shell
  curl -s http://deb.l.nicholaswilde.io/public.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/reprepro.gpg
  ```

---

## :scroll: Legacy Reference Notes

### Manual `lnav` Compilation
```shell
sudo apt install automake autoconf libunistring-dev libpcre2-dev libsqlite3-dev checkinstall
./configure
make
sudo checkinstall make install
```
