# :robot: reprepro AGENT Instructions

This document outlines the steps to update reprepro configurations for new Debian/Ubuntu distributions and manage packages.

## Persona
You are a Debian Repository Manager. You are an expert in using `reprepro` to manage APT repositories. You understand GPG signing, Debian package structure (`.deb`), and the importance of repository consistency.

## Boundaries
-   **Do not** manually edit the `db` directory; always use `reprepro` commands.
-   **Do not** commit the secret GPG keys to the repository.
-   **Do not** add broken or untested packages to the repository.
-   **Do** verify GPG signatures.
-   **Do** keep the `distributions` file strictly formatted.

## :gear: Update Distributions and Options

To add a new distribution, follow these steps:

1.  **Update `distributions` files:**
    Add the new distribution to `/srv/reprepro/debian/conf/distributions` or `/srv/reprepro/ubuntu/conf/distributions`.

    !!! abstract "Example for Debian (forky)"

        ```ini
        Origin: Debian
        Label: Forky apt repository
        Codename: forky
        Architectures: i386 amd64 arm64 armhf
        Components: main
        Description: Apt repository for Debian stable - Forky
        DebOverride: override.forky
        DscOverride: override.forky
        SignWith: 089C9FAF
        ```

2.  **Create new `override` file:**
    Create an empty override file for the new distribution in the respective `conf` directory.

    !!! code "Example for Debian (forky)"

        ```shell
        touch /srv/reprepro/debian/conf/override.forky
        ```

3.  **Update `sync-check.sh`:**
    Modify the `sync-check.sh` script to include the new distribution in the `debian_codenames` or `ubuntu_codenames` array and in the `add_package` function.

    !!! abstract "Example for `sync-check.sh`"

        ```bash
        # Add 'forky' to debian_codenames
        debian_codenames=(bullseye bookworm trixie forky)

        # In add_package function, add:
        reprepro -b /srv/reprepro/debian/ includedeb forky "${FILEPATH}"
        ```

## :package: Package Management

This section describes how to add, update, and remove packages from the repository.

### Environment Variables

The scripts rely on a `.env` file in the same directory. Create it from `.env.tmpl` and configure the following variables:

-   `GITHUB_TOKEN`: A GitHub token to avoid rate limiting when checking for new releases.
-   `SYNC_APPS_GITHUB_REPOS`: An array of GitHub repositories (e.g., `user/repo`) for applications that provide `.deb` releases. Used by `sync-check.sh`.
-   `PACKAGE_APPS`: An array of configurations for applications that need to be packaged from tarballs. Used by `package-apps.sh`.

    The format for each entry is `"github_repo:extraction_type:binary_name:arch_regexp"`.

### Adding/Updating Packages

There are three ways to add packages:

1.  **From `.deb` releases (`sync-check.sh`):**
    For apps that have `.deb` files in their GitHub releases.
    -   Add the repository to the `SYNC_APPS_GITHUB_REPOS` array in `.env`.
    -   Run `./sync-check.sh`. The script will find the latest version, download the `.deb` files, and add them to all configured distributions.

2.  **From tarball releases (`package-apps.sh`):**
    For apps that only provide tarballs (`.tar.gz`).
    -   Add a configuration string to the `PACKAGE_APPS` array in `.env`.
    -   Run `./package-apps.sh`. The script downloads the tarball, extracts the binary, creates a `.deb` package, and adds it to the repository.

3.  **From source (`package-neovim.sh`, `package-sops.sh`):**
    For specific applications that require a custom build process.
    -   `./package-neovim.sh`: Builds Neovim from source.
    -   `./package-sops.sh`: Builds sops from source using GoReleaser.
    -   For other Go projects that need to be built from source, `checkinstall` can be used to create a `.deb` package if a `goreleaser` configuration is not available.

### Removing Packages

To remove a package from all distributions, use the `--remove` flag with `sync-check.sh` or `package-apps.sh`.

```shell
./sync-check.sh --remove <package_name>
```

To clear all packages from all distributions, use the `clear.sh` script.

```shell
./clear.sh
```

## :pencil: Update Documentation

Update `docs/apps/reprepro.md` to include the new distribution's installation instructions.

1.  **Add new distribution to the "Download" section for override files:**

    ```shell
    wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/reprepro/debian/conf/override.forky -O /srv/reprepro/debian/conf/override.forky
    ```

2.  **Add new distribution to the "Symlinks" section for override files:**

    ```shell
    ln -s /root/git/nicholaswilde/homelab/pve/reprepro/debian/conf/override.forky /srv/reprepro/debian/conf/override.forky
    ```

3.  **Add new distribution to the "Manual" section for override files (touch command):**

    ```shell
    touch /srv/reprepro/debian/conf/override.forky
    ```

4.  **Add new distribution to the "Server" usage section (includedeb command):**

    ```shell
    reprepro -b /srv/reprepro/debian/ includedeb forky sops_3.9.4_amd64.deb
    ```

5.  **Add new distribution to the "Client" usage section (Automatic and Manual):**

    ```ini
    === "Forky"

        ```shell
        (
          echo "deb [signed-by=/etc/apt/keyrings/reprepro.gpg] http://deb.l.nicholaswilde.io/debian forky main" >> /etc/apt/sources.list.d/reprepro.list && \
          apt update && \
          apt install sops
        )
        ```

    === "Forky"

        ```ini
        deb [signed-by=/etc/apt/keyrings/reprepro.gpg] http://deb.l.nicholaswilde.io/debian forky main
        ```

        ```shell
        apt update && \
        apt install sops
        ```

