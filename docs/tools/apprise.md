---
tags:
  - tool
---
# :mailbox: apprise

[apprise][1] is used as a notification app that supports multiple protocols and integrations.

## :hammer_and_wrench: Installation

```shell
apt install apprise
```

## :gear: Config

```shell title="Test"
apprise -vv -t 'my title' -b 'my notification body' 'mailto://email:passkey@gmail.com'
```

```shell title="Notification URL List"
mailto://email:passkey@gmail.com
```

## :link: References

- <https://github.com/caronc/apprise>

[1]: <https://github.com/caronc/apprise>
