--- 
tags:
  - lxc
  - proxmox
---
# ![title](https://raw.githubusercontent.com/selfhst/icons/400886b4f5cd552ef373e4550cb0be7344402cce/svg/changedetection.svg){ width="32" } Change Detection

[Change Detection][1] is used to monitor websites and send notifications for when the websites have changed. I typically use this to be notified of when a new release of an OS image is released.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `5000`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/ct/changedetection.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(curl -sL https://github.com/asylumexp/Proxmox/raw/main/ct/changedetection.sh)"
        ```

## :gear: Config

!!! code ""

    ```shell
    apt install apprise
    ```

!!! success "Test"

    ```shell
    apprise -vv -t 'my title' -b 'my notification body' 'mailto://user:passkey@gmail.com'
    ```

!!! abstract "Notification URL List"

    ```shell
    mailto://user:passkey@gmail.com
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/changedetection.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/changedetection.yaml"
    ```

## :pencil: Usage

### :octicons-rss-24: Monitoring Gitea Releases

To monitor Gitea releases for a repository, use the RSS feed URL format:

!!! code ""

    ```ini
    https://gitea.com/<owner>/<repo>/releases.rss
    ```

### :octicons-git-commit-24: Monitoring GitHub Commits

For repositories that do not use releases, you can monitor commits using the Atom feed URL:

!!! code ""

    ```ini
    https://github.com/<owner>/<repo>/commits.atom
    ```

## :rocket: Upgrade

!!! code ""

    ```shell
    (
      echo 'bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/ct/changedetection.sh)"' | tee -a ~/.bash_aliases && \
      source ~/.bashrc && \
      update
    )
    ```

## :bell: Notifications

1. [Apprise][2]

## :robot: Automated LXC Updates

I use ChangeDetection to monitor for new Debian standard releases and automatically trigger a Proxmox LXC template rebuild.

### :key: SSH Key Configuration

The automation requires passwordless SSH access from the ChangeDetection LXC to the Proxmox nodes.

!!! code "Generate Automation Key"

    ```shell
    ssh-keygen -t ed25519 -f /root/.ssh/id_pve_automation -N ""
    ```

!!! code "Add to Proxmox Nodes"

    ```shell
    ssh-copy-id -i /root/.ssh/id_pve_automation root@<pve_node_ip>
    ```

### :anchor: Webhook Setup

The [webhook][3] tool listens for HTTP requests from ChangeDetection and executes the trigger script.

!!! abstract "Hooks Configuration (`pve/changedetection/hooks.json`)"

    ```json
    --8<-- "pve/changedetection/hooks.json"
    ```

!!! abstract "Systemd Service (`pve/changedetection/webhook-pve.service`)"

    ```ini
    --8<-- "pve/changedetection/webhook-pve.service"
    ```

!!! code "Enable Service"

    ```shell
    cp pve/changedetection/webhook-pve.service /etc/systemd/system/
    systemctl enable --now webhook-pve
    ```

For general installation and service setup, see the [Webhook Tool Documentation][3].

### :material-shimmer: Trigger Script

The `trigger-lxc-update.sh` script orchestrates the remote execution of the rebuild process on the specified Proxmox host.

**Location:** `pve/changedetection/trigger-lxc-update.sh`

### :material-web: ChangeDetection.io Setup

To trigger the rebuild when a change is detected:

1.  Edit the watch item for the Debian standard release.
2.  Go to the **Notifications** tab.
3.  Add the following URL to the **Notification URL List**:

!!! success "Notification URL"

    ```text
    json://localhost:9000/hooks/rebuild-amd64
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "pve/changedetection/task-list.txt"
    ```

## :link: References

- <https://github.com/caronc/apprise>
- <https://pimox-scripts.com/scripts?id=Change+Detection>
- <https://community-scripts.github.io/ProxmoxVE/scripts?id=changedetection>

[1]: <https://changedetection.io/>
[2]: <../tools/apprise.md>
[3]: <../tools/webhook.md>
