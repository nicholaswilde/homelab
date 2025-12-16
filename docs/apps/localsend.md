---
tags:
  - lxc
  - proxmox
---
# :simple-localsend: LocalSend Web App

[LocalSend][1] is a free and open-source cross-platform app that allows you to securely share files and messages with nearby devices over your local network without the need for an internet connection.

I use this as a self-hosted web app to transer files between my Chromebook, or other system that uses a browser.

!!! note

    The current version of the web app is not compatible with the mobile app nor [LocalSend Go][2]

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8080`

Clone the repo.

=== "root"

    ```shell
    git clone https://github.com/localsend/web.git /opt/localsend
    cd /opt/localsend
    ```

=== "sudo"

    ```shell
    sudo mkdir -p /opt/localsend
    sudo chown -R $USER:$USER /opt/localsend
    git clone https://github.com/localsend/web.git /opt/localsend
    cd /opt/localsend
    ```

Make sure to install [pnpm](https://pnpm.io).

```bash
npm install -g pnpm
```

Get dependencies

```bash
pnpm install
```

Start the development server

```bash
pnpm run dev
```

## Deployment

Generates the static website in the `dist` directory.

```bash
pnpm run generate
```

### :simple-caddy: Caddy

Caddy needs to be installed to run the LXC as a webserver.

=== "root"

    ```shell
    apt install -y git curl caddy
    ```

=== "sudo"

    ```shell
    sudo apt install -y git curl caddy
    ```

## :gear: Config

WIP

### :simple-caddy: Caddy

```ini title="/etc/caddy/Caddyfile"
--8<-- "localsend/caddy/Caddyfile"
```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/localsend.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/localsend.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "localsend/task-list.txt"
    ```

## :link: References

- <https://github.com/localsend/web>

[1]: <https://github.com/localsend/web>
[2]: <../tools/localsend-go.md>
