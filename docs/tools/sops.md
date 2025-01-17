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

### Keys

=== "SCP"

    ```shell
    (
      [ -d ~/.config/sops/age ] || mkdir -p ~/.config/sops/age
      scp nicholas@192.168.2.250/home/nicholas/.config/sops/age/keys.txt ~/.config/sops/age/
    )
    ```

=== "LastPass"

    ```shell
    (
      [ -d ~/.config/sops/age ] || mkdir -p ~/.config/sops/age
      lpass show sops-age --attach=att-2571789250549588435-38084 -q > ~/.config/sops/age/keys.txt
    )
    ```

## :link: References

[1]: <https://getsops.io/>
[2]: <https://github.com/FiloSottile/age>
