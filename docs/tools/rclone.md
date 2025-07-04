---
tags:
  - tools
---
# ![rclone](https://cdn.jsdelivr.net/gh/selfhst/icons/png/rclone.png){ width="32" } rclone

[rclone][1] is used to sync files between online services and my homelab.

## :joystick: [Remote Setup][4]

Because I mainly work on headless servers, I need to perform this remote setup when verifying the account.

WIP

## ![gdrive](https://cdn.jsdelivr.net/gh/selfhst/icons/png/google-drive.png){ width="24" } [Google Drive][3]

I use Google Drive as an offsite backup for some of my sensative data, such as [Vaultwarden][5].

WIP

## ![gphotos](https://cdn.jsdelivr.net/gh/selfhst/icons/png/google-photos.png){ width="24" } Google Photos

!!! warning

    Unfortunately, Google has recently [removed a large portion of the API access to Google Photos][2] and so I am not using `rclone` to sync photo albums with my homelab.

## :link: References

- <https://rclone.org/remote_setup/>
- <https://rclone.org/>
- <https://rclone.org/googlephotos/>
- <https://rclone.org/drive/>

[1]: <https://rclone.org/>
[2]: <https://issuetracker.google.com/issues/112096115>
[3]: <https://rclone.org/drive/>
[4]: <https://rclone.org/remote_setup/>
[5]: <../apps/vaultwarden.md>
