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
    
!!! code "Install esp32 core"

    ```shell
    arduino-cli core install esp32:esp32
    ```

!!! success "Verify installed core properly"

    ```shell
    arduino-cli core list
    ```
    
    ```shell title="Output"
    ID          Installed Latest Name
    esp32:esp32 3.2.1     3.2.1  esp32
    ```

!!! abstract ".arduino15/arduino-cli.yaml"

    ```yaml
    library:
      enable_unsafe_install: true
    ```

!!! code "Dependencies"

    ```shell
    (
      arduino-cli lib install --git-url https://github.com/mathertel/OneButton.git
      arduino-cli lib install --git-url https://github.com/FastLED/FastLED
    )
    ```

!!! code "Compile"

    ```shell
    arduino-cli compile --fqbn esp32:esp32:esp32s3 USB-MSC.ino
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

!!! code ""

    ```shell
    arduino-cli upload --port /dev/ttyACM0 --fqbn esp32:esp32:esp32s3 USB-MSC.ino
    ```

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

## :stethoscope: Troubleshooting

### [Error during install: context deadline exceeded][2]

!!! warning ""

    ```shell
    $ arduino-cli core install esp32:esp32
    Downloading packages...
    arduino:dfu-util@0.11.0-arduino5 arduino:dfu-util@0.11.0-arduino5 already downloaded
    esp32:esp-rv32@2411 context deadline exceeded (Client.Timeout or context cancellation while reading body)                                                                       
    Error during install: context deadline exceeded (Client.Timeout or context cancellation while reading body)
    ```

!!! success ""

    ```shell
    arduino-cli config set network.connection_timeout 600s
    ```

## :link: References

- <https://arduino.github.io/arduino-cli/>

[1]: <https://arduino.github.io/arduino-cli/>
[2]: <https://forum.arduino.cc/t/error-during-install-context-deadline-exceeded/1384509/2>
