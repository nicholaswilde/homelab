# Immich

## :lock: Encrypt

```shell
sops -e .env > .env.enc
```

## :closed_lock_with_key: Decrypt

```shell
sops -d --input-type dotenv --output-type dotenv .env.enc
```
