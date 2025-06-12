---
tags:
  - tool
  - notifications
---
# :mailbox: Apprise

[Apprise][1] is used as a notification app that supports multiple protocols and integrations.

## :hammer_and_wrench: Installation

!!! code ""

    === "apt"

        ```shell
        apt install apprise
        ```

## :gear: [Config][2]

!!! example

    ```shell
    apprise -vv -t 'my title' -b 'my notification body' 'mailto://email:passkey@gmail.com'
    ```

### :mailbox: [Email](https://github.com/caronc/apprise/wiki/Notify_email)

!!! code "Notification URL List"

    ```shell
    mailto://email:passkey@gmail.com
    ```

## :link: References

- <https://github.com/caronc/apprise>

[1]: <https://github.com/caronc/apprise>
[2]: <https://github.com/caronc/apprise/wiki/config>
