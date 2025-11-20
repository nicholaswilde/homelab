---
tags:
  - tool
---
# ![syncthing](https://cdn.jsdelivr.net/gh/selfhst/icons/png/syncthing.png){ width="32" } Syncthing

[Syncthing][1] is used to syncronize my keys across my containers so I don't need to manually copy them over.

This is preferred over Ansible so that I can more easily update them by updating the source.

## :hammer_and_wrench: Installation

=== "root"

    ```shell
    (
      mkdir -p /etc/apt/keyrings  && \
      curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg  && \
      echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable-v2" | tee /etc/apt/sources.list.d/syncthing.list && \
      apt update && \
      apt install syncthing -y
    )
    ```

=== "sudo"

    ```shell
    (
      sudo mkdir -p /etc/apt/keyrings && \
      sudo curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg && \
      echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable-v2" | sudo tee /etc/apt/sources.list.d/syncthing.list && \
      sudo apt update && \
      sudo apt install syncthing
    )
    ```

## :gear: Config

### Service

=== "root"

    ```shell
    (
      wget -O /usr/lib/systemd/system/syncthing@.service https://github.com/syncthing/syncthing/raw/refs/heads/main/etc/linux-systemd/system/syncthing@.service
      systemctl enable syncthing@${USER}.service
      systemctl start syncthing@${USER}.service
    )
    ```

=== "sudo"

    ```shell
    (
      sudo wget -O /usr/lib/systemd/system/syncthing@.service https://github.com/syncthing/syncthing/raw/refs/heads/main/etc/linux-systemd/system/syncthing@.service
      sudo systemctl enable syncthing@${USER}.service
      sudo systemctl start syncthing@${USER}.service
    )
    ```

=== "root"

    ```
    sed -i "{s/127.0.0.1:8384/0.0.0.0:8384/g}" "${HOME}/.local/state/syncthing/config.xml"
    systemctl restart syncthing@${USER}.service
    ```

=== "sudo"

    ```
    sed -i "{s/127.0.0.1:8384/0.0.0.0:8384/g}" "${HOME}/.local/state/syncthing/config.xml"
    sudo systemctl restart syncthing@${USER}.service
    ```

### :desktop_computer: Control Node

1. Add managed node.
2. Add managed node to shared folders.

### :computer: Managed Node

1. Add control node.
2. Remove shared folder.
3. Accept shared folders from control node.

## Troubleshooting

To fix a stopped Syncthing folder

```shell title="Managed node"
syncthing --reset-database
systemctl restart syncthing@${USER}.service
```

Remote orphaned shared computer and then unshared folders, is needed in the GUI

Changed shared folders to `Receive Only`.

Reset and restart syncthing again.

Revert changes to folders if they say `Local`.

## :link: References

- <https://syncthing.net/>

[1]: <https://syncthing.net/>
