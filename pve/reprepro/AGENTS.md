# :robot: reprepro AGENT Instructions

This document outlines the steps to update reprepro configurations for new Debian/Ubuntu distributions.

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

