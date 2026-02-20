# restic

Fast, secure, efficient backup program.

## :hammer_and_wrench: Install
    
=== "installer"

    === "root"
    
        ```shell
        curl -fsSL https://installer.l.nicholaswilde.io/restic/restic! | bash
        ```
    === "sudo"
    
        ```shell
        curl -fsSL https://installer.l.nicholaswilde.io/restic/restic! | sudo bash
        ```

=== "brew"

    ```shell
    brew install restic
    ```

## :gear: Config

```shell
export RESTIC_REPOSITORY=/srv/restic-repo
export RESTIC_PASSWORD=some-strong-password
```

!!! tip

    Great to add to your `.bashrc` files.

## :pencil: Usage

Initialize the repository (first time only):

```shell
restic init
```

Create your first backup:

```shell
restic backup ~/work
```

You can list all the snapshots you created with:

```shell
restic snapshots
```

You can restore a backup by noting the snapshot ID you want and running:


```shell
restic restore --target /tmp/restore-work your-snapshot-ID
```

It is a good idea to periodically check your repository’s metadata:


```shell
restic check
# or full data:
restic check --read-data
```

## :rocket: Upgrade

```shell
restic self-update
```

## :link: References

- <https://github.com/restic/restic>

[1]: <https://github.com/restic/restic>