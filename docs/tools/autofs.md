---
tags:
  - tool
---
# :fontawesome-solid-hard-drive: Autofs

[Autofs][1] is used to automatically connect to my NFS storage on my
containers/VMs so that they can share storage.

## :hammer_and_wrench: Installation

!!! code ""

    === "root"
    
        ```shell
        apt install autofs -y
        ```
    === "sudo"
    
        ```shell
        sudo apt install autofs -y
        ```

## :material-laptop: Client

!!! code ""

    === "root"
    
        ```shell
        (
          apt install -y autofs && \
          echo '/mnt /etc/auto.nfs --ghost --timeout=60' | tee -a /etc/auto.master && \
          echo 'storage -fstype=nfs4,rw,insecure 192.168.2.19:/storage' | tee -a /etc/auto.nfs && \
          systemctl restart autofs.service && \
          systemctl status autofs.service
        )
        ```

    === "sudo"
    
        ```shell
        (
          sudo apt install -y autofs && \
          echo '/mnt /etc/auto.nfs --ghost --timeout=60' | sudo tee -a /etc/auto.master && \
          echo 'storage -fstype=nfs4,rw,insecure 192.168.2.19:/storage' | sudo tee -a /etc/auto.nfs && \
          sudo systemctl restart autofs.service && \
          sudo systemctl status autofs.service
        )
        ```

## :link: References

[1]: https://help.ubuntu.com/community/Autofs