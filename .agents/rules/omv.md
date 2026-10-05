# OpenMediaVault (OMV) Networking Rules

When configuring or modifying network settings on an OpenMediaVault (OMV) system:

- **Never edit network files directly:** Do NOT touch `/etc/netplan` or `/etc/systemd/network` directly; manual edits will be overwritten by OMV automation.
- **Database updates:** Inspect and modify configuration via the OMV database command line utility:
  ```bash
  omv-confdbadm read conf.system.network.interface
  ```
- **Apply changes:** Deploy changes via the Salt configuration runner:
  ```bash
  omv-salt deploy run systemd-networkd
  ```
