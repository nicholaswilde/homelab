---
tags:
  - tools
---
# ![rclone](https://cdn.jsdelivr.net/gh/selfhst/icons/png/rclone.png){ width="32" } rclone

[rclone][1] is used to sync files between online services and my homelab.

## :joystick: [Remote Setup][4]

Because I mainly work on headless servers, I need to perform this remote setup when verifying the account.

### :gear: Configuring using rclone authorize

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

    Rclone can only download photos from albums that were *created by rclone itself*. It cannot download from albums created directly in Google Photos or by other applications.

!!! code "How to make a remote called remote"

    ```shell
    rclone config
    ```

!!! code "This will guide you through an interactive setup process"

    ```shell
    No remotes found, make a new one?
    n) New remote
    s) Set configuration password
    q) Quit config
    n/s/q> n
    name> remote
    Type of storage to configure.
    Enter a string value. Press Enter for the default ("").
    Choose a number from below, or type in your own value
    [snip]
    XX / Google Photos
       \ "google photos"
    [snip]
    Storage> google photos
    ** See help for google photos backend at: https://rclone.org/googlephotos/ **

    Google Application Client Id
    Leave blank normally.
    Enter a string value. Press Enter for the default ("").
    client_id> 
    Google Application Client Secret
    Leave blank normally.
    Enter a string value. Press Enter for the default ("").
    client_secret> 
    Set to make the Google Photos backend read only.

    If you choose read only then rclone will only request read only access
    to your photos, otherwise rclone will request full access.
    Enter a boolean value (true or false). Press Enter for the default ("false").
    read_only> 
    Edit advanced config? (y/n)
    y) Yes
    n) No
    y/n> n
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

    *** IMPORTANT: All media items uploaded to Google Photos with rclone
    *** are stored in full resolution at original quality.  These uploads
    *** will count towards storage in your Google Account.

    Configuration complete.
    Options:
    - type: google photos
    - token: {"access_token":"XXX","token_type":"Bearer","refresh_token":"XXX","expiry":"2019-06-28T17:38:04.644930156+01:00"}
    Keep this "remote" remote?
    y) Yes this is OK
    e) Edit this remote
    d) Delete this remote
    y/e/d> y
    ```

## Making your own client_id

When you use rclone with Google photos in its default configuration you are using rclone's client_id. This is shared between all the rclone users. There is a global rate limit on the number of queries per second that each client_id can do set by Google.

If there is a problem with this client_id (eg quota too low or the client_id stops working) then you can make your own.

Please follow the steps in the google drive docs. You will need these scopes instead of the drive ones detailed:

```bash
https://www.googleapis.com/auth/photoslibrary.appendonly
https://www.googleapis.com/auth/photoslibrary.readonly.appcreateddata
https://www.googleapis.com/auth/photoslibrary.edit.appcreateddata
```

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
