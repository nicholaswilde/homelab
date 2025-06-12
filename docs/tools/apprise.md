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

### :mailbox: [Email](https://github.com/caronc/apprise/wiki/Notify_email)

!!! note

    Google Users using the 2 Step Verification Process will be required to generate an app-password from [here][3] that you can use in the `passkey` field.

!!! code "Notification URL List"

    ```shell
    mailto://user:passkey@gmail.com
    ```

## :pencil: Usage

!!! example

    ```shell
    apprise -vv -t 'my title' -b 'my notification body' 'mailto://user:passkey@gmail.com'
    ```

## :link: References

- <https://github.com/caronc/apprise>

[1]: <https://github.com/caronc/apprise>
[2]: <https://github.com/caronc/apprise/wiki/config>
[3]: <https://security.google.com/settings/security/apppasswords>
