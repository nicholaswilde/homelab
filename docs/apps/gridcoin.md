---
tags:
  - vm
  - proxmox
---
# :simple-bitcoin: Gridcoin

## :hammer_and_wrench: Installation

!!! quote ""

    ```shell
    (
      add-apt-repository ppa:gridcoin/gridcoin-stable && \
      apt update && \
      apt install -y gridcoinresearch
    )
    ```

## :gear: Config

!!! quote "Get rpcuser and rpcpassword"

    ```shell
    gridcoinresearchd
    ```

!!! abstract "~/.GridcoinResearch/gridcoinresearch.conf"

    ```ini
    addnode=addnode-us-central.cycy.me
    addnode=ec2-3-81-39-58.compute-1.amazonaws.com
    addnode=gridcoin.network
    addnode=seeds.gridcoin.ifoggz-network.xyz
    addnode=seed.gridcoin.pl
    addnode=www.grcpool.com
    rpcuser=gridcoinrpc
    rpcpassword=mypassword
    datadir=/mnt/storage/gridcoin
    boincdatadir=/var/lib/boinc-client/
    email=ncwilde43@gmail.com
    ```

## :handshake: Service

!!! abstract "/etc/systemd/system/gridcoinresearchd.service"

    === "Manual"

        ```ini
        [Unit]
        Description=Gridcoin Research Daemon
        After=network.target

        [Service]
        User=root
        Group=root
        Type=forking
        ExecStart=/usr/bin/gridcoinresearchd -daemon
        ExecStop=/usr/bin/gridcoinresearchd stop
        Restart=always
        RestartSec=10
        RemainAfterExit=yes

        [Install]
        WantedBy=multi-user.target
        ```
        
!!! quote "Enable service"

    ```shell
    (
      systemctl daemon-reload && \
      systemctl enable gridcoinresearchd.service && \
      systemctl start gridcoinresearchd.service
    )
    ```

## :pencil: Usage

!!! quote ""

    ```shell
    gridcoinresearchd getmininginfo
    ```

!!! quote "Get current block count"

    ```shell
    gridcoinresearchd getblockcount
    ```

Compare to [current block count][1].

!!! quote "Get wallet address"

    ```shell
    gridcoinresearchd getnewaddress
    ```

!!! quote "Check wallet balance"

    ```shell
    gridcoinresearchd listaddressgroupings
    ```

## :link: References

- <https://gridcoin.us/wiki/rpc.html>
- <https://cascadiarecovery.com/how-to-setup-boinc-on-raspberry-pi-4-64-bit-with-dietpi-and-headless-gridcoin-solo-or-pool-mining/>
- <https://gridcoin.ch/faucet> - Daily
- <https://www.gridcoinstats.eu/faucet> - 30 min

[1]: <https://www.gridcoinstats.eu/block>
