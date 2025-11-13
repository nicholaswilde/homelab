---
tags:
  - tool
---
# ![syncthing](https://cdn.jsdelivr.net/gh/selfhst/icons/png/syncthing.png){ width="32" } Syncthing

[Syncthing][1] is used to syncronize my keys across my containers so I don't need to manually copy them over.

This is preferred over Ansible so that I can more easily update them by updating the source.

## :hammer_and_wrench: Installation

Installed via `homelab-pull`.

## :gear: Config

### :desktop_computer: Control Node

1. Add managed node.
2. Add managed node to shared folders.

### :computer: Managed Node

1. Add control node.
2. Remove shared folder.
3. Accept shared folders from control node.

## Troubleshooting

To fix a stopped Syncthing folder

```shell title="Both managed and control node"
syncthing --reset-database
```

## :link: References

- <https://syncthing.net/>

[1]: <https://syncthing.net/>
