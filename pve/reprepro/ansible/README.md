# Ansible

If using `pipx` to install `jmespath`.

On control node:

```shell
(
  pipx install ansible
  pipx inject ansible jmespath
)
```

## Reprepro Host & Testing Info
*   **Reprepro Host IP**: `192.168.1.58`
*   **SSH Testing**: You can SSH directly into `192.168.1.58` to perform manual or automated test operations (e.g., verifying `reprepro` lists, logs, or package integrity).

