---
tags:
  - lxc
  - proxmox
  - docker
---
# :simple-docker: docker-volume-backup

[docker-volume-backup][1] (`dvb`) is used to backup Docker volumes locally or to any S3, WebDAV, Azure Blob Storage, Dropbox
or SSH compatible storage.

## :hammer_and_wrench: Installation

`dvb` is used as a docker container inside of an already existing Docker compose file.

## :gear: Config

This example backs up [two volumes][2] in the same compose volume, `postgres_data` and `minio_data`.

!!! abstract "compose.yaml"

    ```yaml
    --8<-- "reactive-resume/compose.yaml:1:2,47:79,154:"
    ```

## :pencil: Usage

!!! code "Backup Manually"

    ```shell
    docker exec <container_ref> backup
    ```

## :link: References

- <https://offen.github.io/docker-volume-backup/>

[1]: <https://offen.github.io/docker-volume-backup/>
[2]: <https://offen.github.io/docker-volume-backup/recipes/#running-multiple-instances-in-the-same-setup>
