# [pass](https://www.passwordstore.org/)

## Installation

```shell
# Ubuntu
brew install pass
```

Remove gpg-agent error

```shell
sudo apt remove gpg-agent
gpgconf --kill gpg-agent
```

## Usage

### [Import File](https://lists.zx2c4.com/pipermail/password-store/2014-August/001105.html)

```shell
pass insert -fm gpg/revoke < file.txt
```

### Git

```shell
# Push your local pass history
pass git push -u --all
```

## Reconnecting Existing Repo

```shell
git clone git@github.com:nicholaswilde/pass.git ~/.password-store
```

## [pass-import](https://github.com/roddhjav/pass-import)

=== "sudo"

    ```shell
    curl -fsSL https://pkg.pujol.io/debian/gpgkey | sudo tee /etc/apt/keyrings/pass-extension-import.gpg
    echo 'deb [arch=amd64] https://pkg.pujol.io/debian/repo all main' | sudo tee /etc/apt/sources.list.d/pkg.pujol.io.list
    sudo apt update
    sudo apt install pass-extension-import -y
    ```
=== "root"

    ```shell
    curl -fsSL https://pkg.pujol.io/debian/gpgkey | tee /etc/apt/keyrings/pass-extension-import.gpg
    echo 'deb [arch=amd64] https://pkg.pujol.io/debian/repo all main' | tee /etc/apt/sources.list.d/pkg.pujol.io.list
    apt update
    apt install pass-extension-import -y
    ```

## Encrypt Files

```shell
pass insert -m sensitive/secret_answers < secret_answers.txt
# Or
cat secret_answers.txt | pass insert -m sensitive/secret_answers
```

## Update encryption key

```shell
pass init <new-gpg-key-id>
```

## Check Git Origin

```shell
pass git remote -v
```

## Copy password using `osc52.sh`

Ensure that `xclip` is uninstalled

```shell
sudo apt remove xclip
```

### Step 1: Create the xclip Wrapper

`pass` tries to run xclip with specific flags. We need a dummy xclip that ignores those flags and pipes the password to your copy command.

Create the file:

```shell
nano ~/.local/bin/xclip
```

!!! note

    Ensure `~/.local/bin` is in your `$PATH`. If you use a different bin folder, put it there

Paste the following content:

```shell
#!/bin/bash

# 1. 'pass' attempts to restore the clipboard using 'xclip -o'.
#    We cannot read the client clipboard via OSC52, so we ignore this or exit.
if [[ "$*" == *"-o"* ]]; then
  exit 0
fi

# 2. 'pass' sends the password via Stdin.
#    We pipe that Stdin directly to your 'copy' script.
#    Your 'copy' script (osc52.sh) handles the base64 encoding and escape codes.
cat | copy
```

Make it executable:

```shell
chmod +x ~/.local/bin/xclip
```

Check that it exists in `$PATH`

!!! success

    ```shell
    which xclip
    ```

### Step 2: Bypass the Display Check (Crucial for SSH)

If you are running this over SSH (which is likely, given you are using hterm), pass will abort saying "Error: No X11 window system found" because the `$DISPLAY` variable is empty.

You must set a fake display variable to trick pass into running our wrapper.

Run this in your terminal (or add it to your `~/.bashrc`):

=== ".bashrc"

    ```shell
    export DISPLAY=:0
    ```

=== "Manual"

    ```shell
    export DISPLAY=:0
    ```

### Step 3: Test It

Run the standard copy command:

```shell
pass -c social/reddit
```

## References

- <https://wiki.archlinux.org/index.php/Pass>
- <https://vitalyparnas.com/guides/pass/#files>
