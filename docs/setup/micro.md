---
tags:
  - setup
---
# :simple-microeditor: Micro

```shell
# Ctrl + e
set colorscheme twilight
set tabsize 2
set tabtospaces "true"
```

```shell
(
  [ -d ~/.config/micro ] || mkdir -p ~/.config/micro
  wget https://github.com/nicholaswilde/dotfiles2/raw/refs/heads/main/.config/micro/settings.json -O ~/.config/micro/settings.json
)
```
