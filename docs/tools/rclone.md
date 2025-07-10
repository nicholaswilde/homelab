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

!!! code "headless box"

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

!!! code "desktop machine"

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

!!! code "headless box"

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

### :gear: Configuration

The initial setup for drive involves getting a token from Google drive which you need to do in your browser. rclone config walks you through it.

!!! note

    The remote is called `remote` in this example and so all relevant commands must use the name `remote`.

!!! code "How to make a remote called remote"

    ```shell
    rclone config
    ```

!!! code "This will guide you through an interactive setup process"

    ```shell
    No remotes found, make a new one?
    n) New remote
    r) Rename remote
    c) Copy remote
    s) Set configuration password
    q) Quit config
    n/r/c/s/q> n
    name> remote
    Type of storage to configure.
    Choose a number from below, or type in your own value
    [snip]
    XX / Google Drive
       \ "drive"
    [snip]
    Storage> drive
    Google Application Client Id - leave blank normally.
    client_id>
    Google Application Client Secret - leave blank normally.
    client_secret>
    Scope that rclone should use when requesting access from drive.
    Choose a number from below, or type in your own value
     1 / Full access all files, excluding Application Data Folder.
       \ "drive"
     2 / Read-only access to file metadata and file contents.
       \ "drive.readonly"
       / Access to files created by rclone only.
     3 | These are visible in the drive website.
       | File authorization is revoked when the user deauthorizes the app.
       \ "drive.file"
       / Allows read and write access to the Application Data folder.
     4 | This is not visible in the drive website.
       \ "drive.appfolder"
       / Allows read-only access to file metadata but
     5 | does not allow any access to read or download file content.
       \ "drive.metadata.readonly"
    scope> 1
    Service Account Credentials JSON file path - needed only if you want use SA instead of interactive login.
    service_account_file>
    Remote config
    Use web browser to automatically authenticate rclone with remote?
     * Say Y if the machine running rclone has a web browser you can use
     * Say N if running rclone on a (remote) machine without web browser access
    If not sure try Y. If Y failed, try N.
    y) Yes
    n) No
    y/n> y
    If your browser doesn't open automatically go to the following link: http://127.0.0.1:53682/auth
    Log in and authorize rclone for access
    Waiting for code...
    Got code
    Configure this as a Shared Drive (Team Drive)?
    y) Yes
    n) No
    y/n> n
    Configuration complete.
    Options:
    type: drive
    - client_id:
    - client_secret:
    - scope: drive
    - root_folder_id:
    - service_account_file:
    - token: {"access_token":"XXX","token_type":"Bearer","refresh_token":"XXX","expiry":"2014-03-16T13:57:58.955387075Z"}
    Keep this "remote" remote?
    y) Yes this is OK
    e) Edit this remote
    d) Delete this remote
    y/e/d> y
    ```

See the remote setup docs for how to set it up on a machine with no Internet browser available.

Note that rclone runs a webserver on your local machine to collect the token as returned from Google if using web browser to automatically authenticate. This only runs from the moment it opens your browser to the moment you get back the verification code. This is on http://127.0.0.1:53682/ and it may require you to unblock it temporarily if you are running a host firewall, or use manual mode.

You can then use it like this,

!!! code "List directories in top level of your drive"

    ```shell
    rclone lsd remote:
    ```

!!! code "List all the files in your drive"

    ```shell
    rclone ls remote:
    ```

!!! code "To copy a local directory to a drive directory called backup"

    ```shell
    rclone copy /home/source remote:backup
    ```

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
