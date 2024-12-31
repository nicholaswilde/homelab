---
tags:
 - setup
---
# :key: SOPS

## Installation

```shell
brew install sops
```

## :gear: Config

```shell
[ -d ~/.config/sops/age ] || mkdir -p ~/.config/sops/age
lpass show sops-age --attach=att-2571789250549588435-38084 -q > ~/.config/sops/age/keys.txt
```