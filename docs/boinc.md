---
tags:
  - vm
---
# BOINC

## :material-content-save-plus: Installation

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

```shell title="Default dir"
/etc/boinc-client/
```

## Troubleshooting

If gui_rpc_auth.cfg is blank, create a backup and restart service.

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
