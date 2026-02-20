---
tags:
  - hardware
  - lilygo
  - t-dongle-s3
---
# :material-chip: LilyGo T-Dongle S3

The [LilyGo T-Dongle S3][1] is a compact and versatile development board based on the Espressif ESP32-S3. It is designed for a wide range of IoT applications and projects that require wireless connectivity and low power consumption.

## :hammer_and_wrench: Installation

To use the T-Dongle S3, you will need to set up your development environment with support for the ESP32-S3. The most common ways to do this are with the Arduino IDE or PlatformIO.

### Arduino IDE

1.  **Install the Arduino IDE**: If you don't have it already, download and install the [Arduino IDE][2].
2.  **Add ESP32 Board Support**:
    - Open the Arduino IDE and go to `File > Preferences`.
    - In the "Additional Board Manager URLs" field, add the following URL:
      ```
      https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
      ```
    - Go to `Tools > Board > Boards Manager...`, search for "esp32", and install the "esp32" by Espressif Systems.
3.  **Select the Board**:
    - Go to `Tools > Board` and under the "ESP32 Arduino" section, select "ESP32S3 Dev Module".

### PlatformIO

1.  **Install Visual Studio Code and PlatformIO**: If you don't have it, install [Visual Studio Code][3] and the [PlatformIO IDE extension][4].
2.  **Create a new project**:
    - Open PlatformIO and create a new project.
    - For the board, search for "ESP32-S3-DevKitC-1" or a similar generic ESP32-S3 board.
3.  **Configure `platformio.ini`**:
    - Your `platformio.ini` file should look something like this:

    ```ini
    [env:esp32s3_dongle]
    platform = espressif32
    board = esp32-s3-devkitc-1
    framework = arduino
    ```

## :gear: Config

The T-Dongle S3 does not require much specific configuration. The main thing is to select the correct board and settings in your development environment.

Here are some common settings for the ESP32-S3 in the Arduino IDE under `Tools`:

-   **Board**: "ESP32S3 Dev Module"
-   **USB CDC On Boot**: "Enabled" (for serial communication over USB)
-   **Flash Mode**: "QIO"
-   **Flash Size**: "4MB"
-   **Partition Scheme**: "Default"

## :pencil: Usage

You can use the T-Dongle S3 like any other ESP32 development board. You can write code in C++ (Arduino) or MicroPython to control the GPIO pins, use the Wi-Fi and Bluetooth capabilities, and interact with sensors and other peripherals.

Here is a simple "Blink" example for the Arduino IDE to get you started. The T-Dongle S3 has a built-in RGB LED that you can control.

!!! abstract "examples/Blink/Blink.ino"

    ```cpp
    #define LED_PIN 38 // The built-in RGB LED is on GPIO 38

    void setup() {
      pinMode(LED_PIN, OUTPUT);
    }

    void loop() {
      digitalWrite(LED_PIN, HIGH);
      delay(1000);
      digitalWrite(LED_PIN, LOW);
      delay(1000);
    }
    ```

## :rocket: Upgrade

To upgrade the firmware on your T-Dongle S3, you simply need to upload a new sketch from the Arduino IDE or PlatformIO. The board will automatically go into bootloader mode when you try to upload new code.

If you need to manually put the board into bootloader mode:

1.  Hold down the "BOOT" button (the one on the side of the USB connector).
2.  Press and release the "RESET" button (the one next to the BOOT button).
3.  Release the "BOOT" button.

## :link: References

- <https://github.com/Xinyuan-LilyGO/T-Dongle-S3>
- <https://www.arduino.cc/en/software>
- <https://code.visualstudio.com/>
- <https://platformio.org/platformio-ide>

[1]: https://github.com/Xinyuan-LilyGO/T-Dongle-S3
[2]: https://www.arduino.cc/en/software
[3]: https://code.visualstudio.com/
[4]: https://platformio.org/platformio-ide