---
tags:
  - arduino
  - cli
  - iot
---
# :robot: arduino-cli

[arduino-cli][1] is a command-line tool that provides all the features of the Arduino IDE, allowing you to manage boards, libraries, and sketches from the terminal.

## :hammer_and_wrench: Installation

Instructions on how to install the application or tool.

!!! code "arduino-cli"

    === "brew"
    
        ```shell
        brew install arduino-cli
        ```
    
!!! code "esp32 tools"

    ```shell
    arduino-cli core install esp32:esp32
    ```

## :gear: Config

`arduino-cli` can be configured with a `arduino-cli.yaml` file.

!!! abstract "arduino-cli.yaml"

    ```yaml
    board_manager:
      additional_urls: []
    daemon:
      port: "50051"
    directories:
      data: /home/user/.arduino15
      downloads: /home/user/.arduino15/staging
      user: /home/user/Arduino
    library:
      enable_unsafe_install: false
    logging:
      file: ""
      format: text
      level: info
    metrics:
      addr: :9090
      enabled: true
    output:
      no_color: false
    sketch:
      always_export_binaries: false
    updater:
      enable_notification: true
    ```

## :pencil: Usage

Here are some common `arduino-cli` commands.

### Core Commands

- `arduino-cli core search`: Search for a core.
- `arduino-cli core install`: Install a core.
- `arduino-cli core list`: List installed cores.

### Library Management

- `arduino-cli lib search`: Search for a library.
- `arduino-cli lib install`: Install a library.
- `arduino-cli lib list`: List installed libraries.

### Sketch Management

- `arduino-cli sketch new`: Create a new sketch.
- `arduino-cli compile`: Compile a sketch.
- `arduino-cli upload`: Upload a sketch to a board.

## :link: References

- <https://arduino.github.io/arduino-cli/>

[1]: <https://arduino.github.io/arduino-cli/>
