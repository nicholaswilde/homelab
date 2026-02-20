---
tags:
  - lxc
  - proxmox
---
# :simple-adguard: AdGuard Home

[AdGuard Home][1] (AGH) is used to filter ads and as my DNS rewites (assign hostnames to IP addresses).

I have two instances of AGH running: one as an LXC and one on a bare metal Raspberry Pi 2.

Syncing between the instances are done using [AdGuard Home Sync][2]

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `3000`

    :material-information-outline: Configuration path: `/opt/AdGuardHome`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(curl -sL https://github.com/community-scripts/ProxmoxVE/raw/main/ct/adguard.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(curl -sL https://github.com/asylumexp/Proxmox/raw/main/ct/adguard.sh)"
        ```

## :gear: Config

!!! abstract "/opt/AdGuardHome/AdGuardHome.yaml"

    ```yaml
    rewrites:
        - domain: adguard02.l.nicholaswilde.io
          answer: 192.168.3.250
    ```

### :handshake: Service

!!! abstract "`/etc/systemd/system/AdGuardHome.service`"

    === "Automatic"

        ```shell
        cat > /etc/systemd/system/AdGuardHome.service <<EOF
        --8<-- "adguardhome/AdGuardHome.service"
        EOF
        ```

    === "Download"

        ```shell
        curl -Lo /etc/systemd/system/AdGuardHome.service https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/adguardhome/AdGuardHome.service
        ```
        
    === "Manual"

        ```ini
        --8<-- "adguardhome/AdGuardHome.service"
        ```
    
!!! code "Enable service"

    === "Manual"
    
        ```shell
        (
         systemctl enable AdGuardHome.service && \
         systemctl start AdGuardHome.service && \
         systemctl status AdGuardHome.service
        ) 
        ```

## :rocket: Upgrade

Upgrading the app is done [via the web GUI][3].

## :floppy_disk: Backup

Backups of the `AdGuardHome.yaml` file are managed by the `backup-adguardhome.sh` script. This script will automatically commit and push the encrypted `AdGuardHome.yaml.enc` file to the git repository when changes are detected.

### :writing_hand: Manual Backup

To perform a manual backup, run the following task:

!!! code ""

    === "Task"

        ```shell
        task backup
        ```

### :robot: Automatic Backup (Timer)

The backup script can be run periodically using a systemd timer.

#### :gear: Configuration

Before installing the timer, you may need to configure the path to the backup script in `pve/adguardhome/backup.service.tmpl`.

By default, the `ExecStart` path is set to:

!!! abstract "pve/adguardhome/backup.service.tmpl"

    ```ini
    ExecStart=/home/nicholas/git/nicholaswilde/homelab/pve/adguardhome/backup-adguardhome.sh
    ```

??? abstract "adguardhome/backup.service.tmpl"

    ```ini
    --8<-- "adguardhome/backup.service.tmpl"
    ```

??? abstract "adguardhome/backup.timer.tmpl"

    ```ini
    --8<-- "adguardhome/backup.timer.tmpl"
    ```

If your project is located elsewhere, you will need to update this path to the correct location of the `backup-adguardhome.sh` script.

#### :hammer_and_wrench: Installation

To install and enable the timer, run the following task. This will copy the service and timer files to `/etc/systemd/system/` and enable the timer.

!!! code ""

    === "Task"
    
        ```shell
        task bt:install
        ```

    === "Manual"

        ```shell
        (
          sudo cp ./backup.service.tmpl /etc/systemd/system/adguardhome-backup.service
          sudo cp ./backup.timer.tmpl /etc/systemd/system/adguardhome-backup.timer
          sudo systemctl daemon-reload
          sudo systemctl enable --now adguardhome-backup.timer
        )
        ```

#### :pencil: Usage

You can manage the timer using the following tasks:

- `task bt:status`: Check the status of the backup timer.
- `task bt:start`: Start the backup timer.
- `task bt:stop`: Stop the backup timer.
- `task bt:enable`: Enable the backup timer to start on boot.
- `task bt:disable`: Disable the backup timer from starting on boot.

#### :wastebasket: Uninstallation

To uninstall the timer, run the following task:

!!! code ""

    === "Task"
    
        ```shell
        task bt:uninstall
        ```

    === "Manual"

        ```shell
        (
          sudo systemctl disable --now adguardhome-backup.timer
          sudo rm /etc/systemd/system/adguardhome-backup.service
          sudo rm /etc/systemd/system/adguardhome-backup.timer
          sudo systemctl daemon-reload
        )
        ```
        
## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "adguardhome/task-list.txt"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=adguard>
- <https://pimox-scripts.com/scripts?id=adguard>

[1]: <https://adguard.com/en/adguard-home/overview.html>
[2]: <./adguardhome-sync.md>
[3]: <https://github.com/adguardteam/adguardhome/wiki/Getting-Started#update>