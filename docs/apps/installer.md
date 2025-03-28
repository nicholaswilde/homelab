---
tags:
  - lxc
  - proxmox
---
# :inbox_tray: Installer

[Installer][1] is used to quickly install pre-compiled binaries from Github releases.

For setup apps that have are not supported by apt package manager, such as task,  this method is used to install and update them. It makes it easier to install and update the apps without having to manually download them or install a another package system in the container, such as npm, pip, or homebrew.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `3000`

!!! code ""

    ```shell
    curl -s https://i.jpillora.com/installer! | bash
    ```

## :gear: Config

!!! abstract "Install location"

    ```shell
    /usr/local/bin/installer
    ```

!!! abstract "/etc/systemd/system/installer.service"

    === "Manual"
    
        ```ini
        [Unit]
        Description=Quickly install pre-compiled binaries from Github releases

        [Service]
        Type=simple
        ExecStart=/usr/local/bin/installer
        Restart=on-failure
        ExecReload=/bin/kill -USR1 $MAINPID
        StandardOutput=append:/var/log/installer.log
        StandardError=inherit

        [Install]
        WantedBy=multi-user.target
        ```

## :pencil: Usage

!!! code "install user/repo from github"

    ```shell
    curl https://i.jpillora.com/<user>/<repo>@<release>! | bash
    ```

!!! code "search web for github repo query"

    ```shell
    curl https://i.jpillora.com/<query>! | bash
    ```

*Or you can use* `wget -qO- url | bash`

**Path API**

- `user` Github user (defaults to @jpillora, customisable if you host your own, searches the web to pick most relevant `user` when `repo` not found)
- `repo` Github repository belonging to `user` (**required**)
- `release` Github release name (defaults to the **latest** release)
- `!` When provided, downloads binary directly into `/usr/local/bin/` (defaults to working directory)

**Query Params**

- `?type=` Force the return type to be one of: `script` or `homebrew`
    - `type` is normally detected via `User-Agent` header
    - `type=homebrew` is **not** working at the moment
- `?insecure=1` Force `curl`/`wget` to skip certificate checks
- `?as=` Force the binary to be named as this parameter value

## :bulb: Examples

* https://i.jpillora.com/serve
* https://i.jpillora.com/cloud-torrent
* https://i.jpillora.com/yudai/gotty@v0.0.12
* https://i.jpillora.com/mholt/caddy
* https://i.jpillora.com/caddy
* https://i.jpillora.com/rclone
* https://i.jpillora.com/ripgrep?as=rg

    ```shell
    $ curl -s i.jpillora.com/mholt/caddy! | bash
    Downloading mholt/caddy v0.8.2 (https://github.com/mholt/caddy/releases/download/v0.8.2/caddy_darwin_amd64.zip)
    ######################################################################## 100.0%
    Downloaded to /usr/local/bin/caddy
    $ caddy --version
    Caddy 0.8.2
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/installer.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/installer.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "installer/task-list.txt"
    ```

## :link: References

[1]: <https://github.com/jpillora/installer>
