---
tags:
  - vm
  - proxmox
---
# ![boinc](https://boinc.berkeley.edu/logo/boinc32.bmp){ width="32" } BOINC

## :hammer_and_wrench: Installation

!!! example ""
    
    :material-information-outline: Configuration path: `/etc/boinc-client/`
    
!!! code ""

    ```shell
    (
      add-apt-repository universe && \
      apt update && \
      apt install boinc-client boinc-client-nvidia-cuda boinc-client-opencl && \
      usermod -aG boinc $(whoami) && \
      systemctl enable --now boinc-client && \
      ps aux | grep boinc
    )
    ```

## :gear: Config

## :pencil: Usage

Get key from [here][1].

!!! code ""

    ```shell
    (
      boinccmd --project_attach https://sech.me/boinc/Amicable/ <key> && \
      boinccmd --get_project_status
      boinccmd --get_task_summary
    )
    ```

## :stethoscope: Troubleshooting

If `gui_rpc_auth.cfg` is blank, create a backup and restart service.

```shell
cat /etc/boinc-client/gui_rpc_auth.cfg
```

```shell
(
  cd /etc/boinc-client/ && \
  mv gui_rpc_auth.cfg gui_rpc_auth.cfg.bak && \
  service boinc-client restart && \
  cat /etc/boinc-client/gui_rpc_auth.cfg
)
```

## :link: References

- <https://boinc.berkeley.edu/wiki/Installing_BOINC_on_Debian_or_Ubuntu>

[1]: <https://sech.me/boinc/Amicable/weak_auth.php>
