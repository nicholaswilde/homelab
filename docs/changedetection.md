---
tags:
  - lxc
---
# ![title](https://raw.githubusercontent.com/selfhst/icons/400886b4f5cd552ef373e4550cb0be7344402cce/svg/changedetection.svg){ width="32" } Change Detection

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `5000`
    
=== "AMD64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/changedetection.sh)"
    ```

=== "ARM64"

    ```shell
    bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/changedetection.sh)"
    ```

## :gear: Config

```shell
apt install apprise
```

```shell title="Test"
apprise -vv -t 'my title' -b 'my notification body' 'mailto://email:passkey@gmail.com'
```

```shell title="Notification URL List"
mailto://email:passkey@gmail.com
```

## :link: References

- <https://github.com/caronc/apprise>
- <https://pimox-scripts.com/scripts?id=Change+Detection>
- <https://community-scripts.github.io/ProxmoxVE/scripts?id=changedetection>