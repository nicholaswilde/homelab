---
tags:
  - lxc
  - proxmox
---
# ![ventoy](https://a.fsdn.com/allura/p/ventoy/icon?83b3cf3559dee8e8a1302821225c2e6076b1e2fded2a1ddc8c229a99eb9efd5a?&w=90){ width="32" } Ventoy

[Ventoy][1] is used as an app to serve multipe ISOs on a bootable USB drive.
The drive is consistently plugged into the node and updated automatically using `cp -u`.
It is meant to be synchronized with ISOs saved in Proxmox or downloaded via qTorrent.

The way that it works is that an NFS share and USB drive are mounted using autofs. A cronjob is run nightly to sync the ISO files on the NFS with the thumb drive.

!!! warning

    Continuous writes to USB drives will degrade the life of the drive.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `24680`

    :material-information-outline: Configuration path: `/opt/ventoy`    

    :material-file-key: .env: `true`

!!! quote "`homelab/pve/ventoy/install.sh`"

    === "Task"

        ```shell
        task install
        ```

    === "root"

        ```shell
        ./install.sh
        ```

    === "sudo"

        ```shell
        sudo ./install.sh
        ```

## :gear: Config

!!! abstract ".env"

    === "Template"
	
	      ```shell
	      cp .env.tmpl .env
	      nano .env
	      ```
 
    === "Manual"

	      ```dotenv
	      --8<-- "ventoy/.env.tmpl"
	      ```

### :handshake: Service

!!! abstract "/etc/systemd/system/ventoy.service"

    === "Automatic"

        ```shell
        cat > /etc/systemd/system/ventoy.service <<EOF
        --8<-- "ventoy/ventoy.service"
        EOF
        ```

    === "Download"

        ```shell
        wget https://github.com/nicholaswilde/homelab/raw/refs/heads/main/pve/ventoy/ventoy.service -O /etc/systemd/system/ventoy.service
        ```
        
    === "Manual"

        ```ini
        --8<-- "ventoy/ventoy.service"
        ```
    
!!! quote "Enable service"

    ```shell
    (
     systemctl enable ventoy.service && \
     systemctl start ventoy.service && \
     systemctl status ventoy.service
    ) 
    ```

### :alarm_clock: Cronjob

!!! quote "2 A.M. nightly"

    === "Automatic"
    
        ```shell
        (crontab -l 2>/dev/null; echo "0 2 * * * find /mnt/storage/downloads -type f -name \"*.iso\" -exec cp -u {} /mnt/usb \;  >/dev/null 2>&1") | crontab -
        ```
	    
    === "Manual"

        ```shell
	      crontab -e
        ```

        ```ini
        0 2 * * * find /mnt/storage/downloads -type f -name \"*.iso\" -exec cp -u {} /mnt/usb \;  >/dev/null 2>&1"
        ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/ventoy.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/ventoy.yaml"
    ```

## :pencil: Usage

The app may be installed and updated on the USB drive via the web app.

!!! quote "Start web server"

    === "Task"
    
        ```shell
        task serve
        ```

    === "Manual"

        ```shell
        (
          cd /opt/ventoy && \
          sudo bash -c bash VentoyWeb.sh -H "0.0.0.0"
        )
        ```

!!! quote "Sync ISOs"

    === "Task"

        ```shell
        task sync
        ```
    
    === "Manual"

        ```shell
        find /mnt/storage/downloads -type f -name \"*.iso\" -exec cp -u {} /mnt/usb \;
        ```

## :rocket: Upgrade

!!! quote ""

    === "Task"

        ```shell
        task update
        ```

Then update the USB drive from the Web GUI.

## :link: References

- <https://www.ventoy.net/en/index.html>

[1]: <https://www.ventoy.net/en/index.html>
