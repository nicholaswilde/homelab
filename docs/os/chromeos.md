---
tags:
  - os
---
# :fontawesome-brands-chrome: Chrome OS

## :key: Set Penguin Crostini Password

Needed to install `brew`.

```shell
sudo passwd $USER
```

## :nerd: [SSH Nerd Fonts][4]

Change the font in the SSH terminal to render emoji correctly for [LazyVim](https://www.lazyvim.org/).

=== "Penguin"

    ```bash
    chrome-untrusted://terminal/html/nassh_preferences_editor.html
    ```

=== "Secure Shell extension"

    ```bash
    chrome-extension://iodihamcpbpeioajjeobimgagajmlibd/html/nassh_preferences_editor.html
    ```

```css title="Custom CSS (inline text)"
@font-face {
    font-family: "Caskaydia Cove NFM";
    src: url("https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v3.1.1/patched-fonts/CascadiaCode/Regular/CaskaydiaCoveNerdFontMono-Regular.ttf");
    font-weight: normal;
    font-style: normal;
}

x-row {
    text-rendering: optimizeLegibility;
    font-variant-ligatures: normal;
}
```

```bash title="Text font family"
'Caskaydia Cove NFM', 'Fira Code', 'Noto Sans Mono'
```

## :cat: Secure Shell Catpucchin Theme

I use the [Secure Shell Chrome extensions](https://chromewebstore.google.com/detail/secure-shell/iodihamcpbpeioajjeobimgagajmlibd) for my SSH session.

Open the [Options](chrome-extension://iodihamcpbpeioajjeobimgagajmlibd/html/nassh_preferences_editor.html) window.

Background color:

- R: `30`
- G: `30`
- B: `46`

```json title="Initial color palette"
[
  "#45475a",
  "#f38ba8",
  "#a6e3a1",
  "#f9e2af",
  "#89b4fa",
  "#f5c2e7",
  "#94e2d5",
  "#bac2de",
  "#585b70",
  "#f38ba8",
  "#a6e3a1",
  "#f9e2af",
  "#89b4fa",
  "#f5c2e7",
  "#94e2d5",
  "#a6adc8"
]
```

## :material-console: [Pin Secure Shell Profile][3]

When running a profile and directly pinning the window to the taskbar, the Secure Shell options window
will show instead of the profile window.

To pin the actual profile window:

1. Type `ssh` + `tab` in the url bar.
2. Type the name of the of the profile so that the profile opens up in a regular tab with the URL bar shown.
3. Three dots -> More tools -> Create shortcut
4. Check `Open as new window` and click `OK`.
5. Pin the newly created shortcut window.

## :printer: [Brother HL-2270DW Printer][2]

```ini
Address: <IP>:9100
Protocol: AppSocket(TCP/IP)
Queue: ipp/print
```

## :clipboard: Clipboard

=== "root Mods Gist"

    ```shell
    (
      curl "https://gist.githubusercontent.com/nicholaswilde/28f1d91df80ab3723ed7697460349ac8/raw/280fa16599e64745cc7f4e71df265ae1aafbf331/term-notify.sh" | tee /usr/local/bin/notify && chmod +x /usr/local/bin/notify
      curl "https://chromium.googlesource.com/apps/libapps/+/HEAD/hterm/etc/hterm-show-file.sh?format=TEXT" | base64 --decode | tee /usr/local/bin/show-file && chmod +x /usr/local/bin/show-file
      curl "https://gist.githubusercontent.com/nicholaswilde/28f1d91df80ab3723ed7697460349ac8/raw/280fa16599e64745cc7f4e71df265ae1aafbf331/osc52.sh" | tee /usr/local/bin/copy && chmod +x /usr/local/bin/copy
    )
    ```

=== "sudo Mods Gist"

    ```shell
    (
      curl "https://gist.githubusercontent.com/nicholaswilde/28f1d91df80ab3723ed7697460349ac8/raw/280fa16599e64745cc7f4e71df265ae1aafbf331/term-notify.sh" | sudo tee /usr/local/bin/notify && sudo chmod +x /usr/local/bin/notify
      curl "https://chromium.googlesource.com/apps/libapps/+/HEAD/hterm/etc/hterm-show-file.sh?format=TEXT" | base64 --decode | sudo tee /usr/local/bin/show-file && sudo chmod +x /usr/local/bin/show-file
      curl "https://gist.githubusercontent.com/nicholaswilde/28f1d91df80ab3723ed7697460349ac8/raw/280fa16599e64745cc7f4e71df265ae1aafbf331/osc52.sh" | sudo tee /usr/local/bin/copy && sudo chmod +x /usr/local/bin/copy
    )
    ```

=== "Originals"

    ```shell
    (
      curl "https://chromium.googlesource.com/apps/libapps/+/HEAD/hterm/etc/hterm-notify.sh?format=TEXT" | base64 --decode | sudo tee /usr/local/bin/notify && sudo chmod +x /usr/local/bin/notify
      curl "https://chromium.googlesource.com/apps/libapps/+/HEAD/hterm/etc/hterm-show-file.sh?format=TEXT" | base64 --decode | sudo tee /usr/local/bin/show-file && sudo chmod +x /usr/local/bin/show-file
      curl "https://chromium.googlesource.com/apps/libapps/+/HEAD/hterm/etc/osc52.sh?format=TEXT" | base64 --decode | sudo tee /usr/local/bin/copy && sudo chmod +x /usr/local/bin/copy
    )
    ```

### [`notify` tmux fix](https://github.com/tmux/tmux/issues/2136#issuecomment-605307331)

```bash
# Send a DCS sequence through tmux.
# Usage: <sequence>
tmux_dcs() {
  printf '\033Pt\033%s\033\\' "$1" > $( tmux display-message -p "#{client_tty}" )
}

```

### `copy` tmux fix

See my [gist](https://gist.github.com/nicholaswilde/28f1d91df80ab3723ed7697460349ac8) for the modified versions.

Comment out `tmux` case. Normal `printf` yworks for some reason.

```bash
...
# Send an escape sequence to hterm.
# Usage: <sequence>
print_seq() {
  local seq="$1"

  case ${TERM-} in
  screen*)
    # Since tmux defaults to setting TERM=screen (ugh), we need to detect
    # it here specially.
    if [ -n "${TMUX-}" ]; then
      tmux_dcs "${seq}"
    else
      screen_dcs "${seq}"
    fi
    ;;
  # tmux*)
  #   tmux_dcs "${seq}"
  #   ;;
  *)
    printf '%s' "${seq}"
    ;;
  esac
}
...
```

```bash title="~/.config/tmux/tmux.conf"
set -g set-clipboard on          # use system clipboard
```

## Stop Penguin Terminal

Open Crosh

```shell
Ctrl + Alt + T
```

Stop Penguin terminal

```shell
vmc stop termina
```

```shell
vmc start termina
```

## Add Remote

```shell
lxc remote add canonical https://images.lxd.canonical.com --protocol simplestreams --auth-type tls
```

Start NixOS

```shell
lxc launch canonical:nixos/24.05 nixos
```

From `crosh`

```shell
vmc container termina nixos
```

## :link: References

- <https://www.youtube.com/watch?v=sIU5qOyBO-Q>

[1]: <https://adamtheautomator.com/ssh-chrome-extension/#Connecting_to_a_Remote_Host_using_the_Search_Bar>
[2]: <https://www.reddit.com/r/chromeos/comments/7n3jc1/setting_up_brother_hl2270dw_printer_on_chromebook/>
[3]: <https://chromium.googlesource.com/apps/libapps/+/HEAD/nassh/docs/FAQ.md#can-i-create-bookmarks-to-specific-sites>
[4]: <https://ricma.co/posts/tech/tutorials/chrome-os-nerd-fonts/>