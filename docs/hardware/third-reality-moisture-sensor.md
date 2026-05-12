---
tags:
  - hardware
  - zigbee
  - iot
---
# :potted_plant: Third Reality Moisture Sensor

The [Third Reality Soil Moisture Sensor (3RSM0147Z)][1] is a Zigbee-based smart
sensor designed for real-time monitoring of soil conditions, specifically
moisture and temperature.

## :gear: Config

| Name | IEEE Address |
| :--- | :--- |
| Moisture Sensor 1 | |

## :hammer_and_wrench: Installation

### :material-zigbee: Pairing

1. **Prepare Hub**: Set your Zigbee hub (e.g., Home Assistant, Zigbee2MQTT) to
   pairing mode.
2. **Power On**: Remove the insulation tab from the battery compartment
   (1x AA battery).
3. **Enter Pairing Mode**: Press and hold the **Reset Button** (inside the
   battery compartment) for **5 seconds** until the LED turns red. Release the
   button; the LED will start blinking blue.
4. **Complete Setup**: The hub should discover the sensor.

### :material-potted-plant: Placement

* **Depth**: Insert the probe into the soil until the marking line is flush with
  the soil surface.
* **Firmness**: Ensure the soil is packed firmly around the probe for accurate
  readings.

## :recycle: Recalibration

If the sensor readings seem inaccurate, follow these steps to recalibrate.

### Prerequisites

* **Firmware**: Ensure the sensor's firmware is version **1.00.38 or above**.
* **Cleaning**: Clean the probe with water and then deep clean with isopropyl
  alcohol (or dish soap and water) to ensure no residue remains.

### Steps

1. **Enter Calibration Mode**:
   * Dry the sensor and unscrew the cap.
   * Press the **reset button three times**.
   * The blue LED should turn on for three seconds to indicate it has entered
     calibration mode.
2. **Air Calibration**: Leave the probe in the air for **15 seconds**. Do not
   touch the sensing area during this time.
3. **Water Calibration**:
   * Screw the cap back on securely.
   * Place the sensor vertically in a cup of tap water.
   * Adjust the water level so it precisely reaches the **marking line** on
     the probe.
   * Hold the sensor in the water for **15 seconds**.
4. **Completion**: The sensor will automatically record the calibration data
   and exit calibration mode.

!!! note
    When deploying multiple sensors, leave at least **15 cm** between them to
    avoid interference.

## :link: References

* [Third Reality Official Product Page][1]
* [Zigbee2MQTT Documentation][2]
* [Recalibrate the soil moisture sensor - Third Reality Discussion][3]

[1]: <https://www.3reality.com/online-store/Soil-Moisture-Sensor-p567175252>
[2]: <https://www.zigbee2mqtt.io/devices/3RSM0147Z.html>
[3]: <https://discuss.3reality.com/d/166-recalibrate-the-soil-moisture-sensor>
