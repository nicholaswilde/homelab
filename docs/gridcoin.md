---
tags:
  - vm
---
# Gridcoin

## :gear: Config

Get rpcuser and rpcpassword by running.

```shell
gridcoinresearchd
```

```ini title="~/.GridcoinResearch/gridcoinresearch.conf"
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

```ini title="/etc/systemd/system/gridcoinresearchd.service"
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

```shell
(
  systemctl daemon-reload && \
  systemctl enable gridcoinresearchd.service && \
  systemctl start gridcoinresearchd.service
)
```

## Usage

```shell
gridcoinresearchd getmininginfo
```

```shell title="Get current block count"
gridcoinresearchd getblockcount
```

Compare to [current block count][1].

```shell title="Get wallet address"
gridcoinresearchd getnewaddress
```

```shell title="Check wallet balance"
gridcoinresearchd listaddressgroupings
```

## :link: References

- <https://gridcoin.us/wiki/rpc.html>
- <https://cascadiarecovery.com/how-to-setup-boinc-on-raspberry-pi-4-64-bit-with-dietpi-and-headless-gridcoin-solo-or-pool-mining/>
- <https://gridcoin.ch/faucet> - Daily
- <https://www.gridcoinstats.eu/faucet> - 30 min

[1]: <https://www.gridcoinstats.eu/block>
