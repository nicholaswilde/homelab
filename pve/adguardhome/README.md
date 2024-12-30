# AdGuard Home

## Encryption

Encrypted using [SOPS][2]

Key location

```
~/.config/sops/age/keys.txt
```

Encrypt 

```shell
sops -e AdGuardHome.yaml > AdGuardHome.yaml.enc
```

Decrypt

```shell
sops -d AdGuardHome.yaml.enc > AdGuardHome.yaml
```

[2]: <https://github.com/getsops/sops>
