---
tags:
  - rpi
  - bare-metal
---
# :simple-raspberrypi: Raspberry Pi Zero W

DietPi is selected for this device due to its lightweight footprint, which is ideal for the limited resources (single-core CPU, 512MB RAM) of the Zero W.

## :gear: Config

!!! example ""

    OS: [DietPi](../os/dietpi.md)

    Hostname: `pi00`

    IP: `192.168.2.190`

    MAC: `b8:27:eb:1c:98:df`

## :satellite: Pi Zero W NTP Node

This document details the physical build, bill of materials, and hardware-level kernel configurations for the Stratum 1 NTP server node. For the software configuration (including `chrony` and thermal compensation), see `../services/chrony.md`.

### :package: Bill of Materials (BOM)

* **SBC:** Raspberry Pi Zero W (v1)
* **Network:** USB-to-Ethernet Adapter (Micro-USB OTG)
* **Time Receiver:** Waveshare MAX-M8Q GNSS HAT
* **Antenna:** Active GPS Antenna with SMA connector
* **Storage:** High-endurance microSD card (for constant log writes)
* **Power:** 5V 2.5A Micro-USB Power Supply

### :hammer_and_wrench: Assembly & Layout

Because the Pi Zero W lacks an onboard ethernet port, the USB-to-Ethernet adapter is required to eliminate Wi-Fi jitter, bringing network delivery accuracy down to the 50–200 µs range. 

The active GPS antenna requires a clear view of the sky. Route the SMA cable from the MAX-M8Q HAT to a window sill. Avoid placing the antenna near heavy electromagnetic interference (e.g., directly on top of the UniFi Cloud Gateway or Proxmox nodes).

### : electric_plug: GPIO Pinout Mapping

The MAX-M8Q HAT interfaces with the Pi Zero W via the 40-pin GPIO header using two distinct communication channels:

| Signal | Pi GPIO Pin | Purpose |
| :--- | :--- | :--- |
| **TXD** | GPIO 14 (Pin 8) | NMEA serial data (UART transmit) |
| **RXD** | GPIO 15 (Pin 10) | NMEA serial data (UART receive) |
| **PPS** | GPIO 4 (Pin 7) | Pulse Per Second hardware interrupt |
| **3V3/5V** | Pins 1, 2, 4 | Power delivery to the HAT |
| **GND** | Pins 6, 9, 14 | Ground |

### :gear: Base OS & Kernel Prep

Before `chrony` can read the hardware signals, the base OS must be configured to expose the UART serial interface and register the PPS GPIO pin.

#### :zap: 1. Enable Hardware Interfaces

Edit `/boot/config.txt` to enable the serial port, disable Bluetooth (which shares the primary UART on Pi Zero W), and load the PPS device tree overlay.

```ini
# /boot/config.txt

# Disable Bluetooth to free up the primary UART for the GPS HAT
dtoverlay=disable-bt

# Enable the primary serial port
enable_uart=1

# Register GPIO 4 for the PPS hardware interrupt
dtoverlay=pps-gpio,gpiopin=4
```

#### :mute: 2. Disable Serial Console

By default, the Pi tries to spawn a login console on the serial port. This conflicts with the NMEA data stream.
Edit /boot/cmdline.txt and carefully remove the console=serial0,115200 parameter. Leave the rest of the line intact.

#### :white_check_mark: 3. Verify Hardware Detection
After rebooting the node, verify that the kernel recognizes the PPS device and the serial port is receiving data.

```bash
# Verify PPS device creation
ls -l /dev/pps0
```

```bash
# Test for the raw electrical pulse (Press Ctrl+C to stop)
sudo ppstest /dev/pps0
```

```bash
# Verify NMEA serial data stream
cat /dev/serial0
```

If ppstest outputs an assert timestamp exactly once per second, the hardware is successfully locked and ready for the chrony service configuration.

## :link: References

[2]: <https://www.raspberrypi.com/software/>
[3]: <https://www.raspberrypi.com/products/raspberry-pi-zero-w/>