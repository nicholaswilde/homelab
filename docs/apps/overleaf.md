---
tags:
  - lxc
  - proxmox
  - docker
---
# :simple-overleaf: Overleaf

[Overleaf][1] is a collaborative, cloud-based LaTeX editor used for writing, editing, and publishing
scientific documents. This instance runs the Community Edition via the [Overleaf Toolkit][2] on a
dedicated Proxmox LXC container.

The stack consists of three Docker containers managed by the toolkit:

- **sharelatex** – the main Overleaf web application (`sharelatex/sharelatex:{{ version }}`)
- **mongo** – MongoDB 8.0 for document storage
- **redis** – Redis 7.4 for session and queue management

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `8080`

    :material-information-outline: Toolkit path: `/root/overleaf-toolkit/`

    :material-information-outline: Config path: `/root/overleaf-toolkit/config/`

    :material-information-outline: Data path: `/root/overleaf-toolkit/data/`

### :simple-proxmox: Proxmox LXC

Create a Debian LXC with Docker installed, then install the toolkit:

!!! code ""

    ```shell
    # Clone the toolkit
    git clone https://github.com/overleaf/toolkit.git /root/overleaf-toolkit
    cd /root/overleaf-toolkit

    # Initialize default config
    bin/init
    ```

### :gear: Configure

Edit `/root/overleaf-toolkit/config/overleaf.rc`:

!!! abstract "`config/overleaf.rc`"

    ```shell
    PROJECT_NAME=overleaf
    OVERLEAF_DATA_PATH=data/overleaf
    SERVER_PRO=false
    OVERLEAF_LISTEN_IP=0.0.0.0
    OVERLEAF_PORT=8080
    SIBLING_CONTAINERS_ENABLED=false
    MONGO_ENABLED=true
    MONGO_DATA_PATH=data/mongo
    MONGO_IMAGE=mongo
    MONGO_VERSION=8.0
    REDIS_ENABLED=true
    REDIS_DATA_PATH=data/redis
    REDIS_IMAGE=redis:7.4
    REDIS_AOF_PERSISTENCE=true
    ```

Edit `/root/overleaf-toolkit/config/variables.env`:

!!! abstract "`config/variables.env`"

    ```shell
    OVERLEAF_APP_NAME="Our Overleaf Instance"
    ENABLED_LINKED_FILE_TYPES=project_file,project_output_file
    ENABLE_CONVERSIONS=true
    EMAIL_CONFIRMATION_DISABLED=true
    EXTERNAL_AUTH=none
    ```

### :rocket: Start

!!! code ""

    ```shell
    cd /root/overleaf-toolkit
    bin/up
    ```

### :bust_in_silhouette: Create Admin User

After first start, navigate to `http://<ip>:8080/launchpad` to create the first admin user.

## :pencil: Usage

### :arrows_counterclockwise: Start / Stop

!!! code "Start"

    ```shell
    cd /root/overleaf-toolkit && bin/start
    ```

!!! code "Stop"

    ```shell
    cd /root/overleaf-toolkit && bin/stop
    ```

### :arrow_up: Upgrade

!!! code ""

    ```shell
    cd /root/overleaf-toolkit && bin/upgrade
    ```

### :stethoscope: Doctor

Run the health check tool to verify the setup:

!!! code ""

    ```shell
    cd /root/overleaf-toolkit && bin/doctor
    ```

### :page_facing_up: Logs

!!! code ""

    ```shell
    cd /root/overleaf-toolkit && bin/logs
    ```

### :floppy_disk: Backup Config

!!! code ""

    ```shell
    cd /root/overleaf-toolkit && bin/backup-config ~/overleaf-config-backup
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "overleaf/task-list.txt"
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/overleaf.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/overleaf.yaml"
    ```

## :link: References

- <https://github.com/overleaf/toolkit>
- <https://github.com/overleaf/overleaf>
- <https://www.overleaf.com/learn/latex/Creating_a_document_in_LaTeX>

[1]: <https://www.overleaf.com/>
[2]: <https://github.com/overleaf/toolkit>
