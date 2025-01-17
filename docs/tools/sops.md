---
tags:
 - tool
---
# :key: SOPS

[SOPS][1] is used to encrypt and decrypt secrets in my homelab.

Typically, my secrets are kept in `.env` files that are read as environmental variables and then used my configs.

[age][2] is my encryption of choice.

## :hammer_and_wrench: Installation

```shell
brew install sops
```

## :gear: Config

```shell title="keys"
(
  [ -d ~/.config/sops/age ] || mkdir -p ~/.config/sops/age && \
  lpass show sops-age --attach=att-2571789250549588435-38084 -q > ~/.config/sops/age/keys.txt
)
```

[1]: <https://getsops.io/>
[2]: <https://github.com/FiloSottile/age>
