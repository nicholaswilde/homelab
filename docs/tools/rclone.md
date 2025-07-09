---
tags:
  - tools
---
# ![rclone](https://cdn.jsdelivr.net/gh/selfhst/icons/png/rclone.png){ width="32" } rclone

[rclone][1] is used to sync files between online services and my homelab.

## :joystick: [Remote Setup][4]

Because I mainly work on headless servers, I need to perform this remote setup when verifying the account.

### Configuring using rclone authorize

On the headless box run `rclone config` but answer `N` to the `Use auto config?` question.

```shell
Use auto config?
 * Say Y if not sure
 * Say N if you are working on a remote or headless machine

y) Yes (default)
n) No
y/n> n

Option config_token.
For this to work, you will need rclone available on a machine that has
a web browser available.
For more help and alternate methods see: https://rclone.org/remote_setup/
Execute the following on the machine with the web browser (same rclone
version recommended):

rclone authorize "onedrive"
Then paste the result.
Enter a value.
config_token>
```

Then on your main desktop machine, enable port forwarding of `53682` for the ssh terminal and then:

```shell
rclone authorize "onedrive"
If your browser doesn't open automatically go to the following link: http://127.0.0.1:53682/auth
Log in and authorize rclone for access
Waiting for code...
Got code
Paste the following into your remote machine --->
SECRET_TOKEN
<---End paste
```

Then back to the headless box, paste in the code

```shell
config_token> SECRET_TOKEN
--------------------
[acd12]
client_id = 
client_secret = 
token = SECRET_TOKEN
--------------------
y) Yes this is OK
e) Edit this remote
d) Delete this remote
y/e/d>
```

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
