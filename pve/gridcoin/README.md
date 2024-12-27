# Gridcoin

## Config

### AppRise Email Address

Don't want to store the apprise email address in the script, so add to environmental variable instead.

```shell
# ~/.bashrc
# apprise email address
export EMAIL_ADDRESS='mailto://email:password@gmail.com'
```

```shell
source ~/.bashrc
```

### Crontab

Schedule to run script once every hour using cron.

```shell
crontab -e
```

```crontab
SHELL=/bin/bash
EMAIL_ADDRESS='mailto://email:password@gmail.com'
* * 7 * * /usr/bin/gridcoinresearchd --datadir=/mnt/storage/gridcoin/ backupwallet >/dev/null 2>&1
0 * * * * /root/git/nicholaswilde/homelab/pve/gridcoin/sync_check.sh >/dev/null 2>&1
```

Status can be seen using `journalctl`

```shell
journalctl -t sync_check
```

### Reset

To ensure that only 1 email is sent, the file `/tmp/sync_notification_sent` is checked to see if it exists.

To reset the script, delete the file.

```shell
rm /tmp/sync_notification_sent
```
