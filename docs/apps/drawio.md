---
tags:
  - lxc
  - proxmox
---
# :simple-diagramsdotnet: Draw.io

[Draw.io][1] (diagrams.net) is a free and open-source diagramming application for creating flowcharts, wireframes, network architecture diagrams, and more.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Web UI Port: `8080`
    :material-webhook: Webhook Port: `9000`

Draw.io runs as a Java web application (WAR) hosted inside Tomcat 10 on Debian.

## :gear: Config

### Webhook Automation

Automated updates are triggered using [webhook][2] listening on port `9000`.

!!! abstract "`homelab/lxc/drawio/hooks.json`"

    ```json
    --8<-- "drawio/hooks.json"
    ```

!!! abstract "Systemd Service (`drawio-webhook.service`)"

    ```ini
    --8<-- "drawio/drawio-webhook.service"
    ```

### ChangeDetection Automation

[ChangeDetection][3] monitors upstream releases via GitHub's Atom feed:

- **Watch URL:** `https://github.com/jgraph/drawio/releases.atom`
- **Notification URL:** `post://192.168.1.237:9000/hooks/update-app?method=POST&header=Content-Type:application/json`

When a new release tag appears, ChangeDetection issues an HTTP POST to the webhook endpoint, triggering `update.sh -s` to fetch the new WAR file, stop Tomcat, deploy the new release, restart Tomcat, and send a summary email via Mailrise.

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/drawio.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/drawio.yaml"
    ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "drawio/task-list.txt"
    ```

## :link: References

- <https://github.com/jgraph/drawio>
- <https://www.drawio.com/>

[1]: <https://www.drawio.com/>
[2]: <../tools/webhook.md>
[3]: <changedetection.md>
