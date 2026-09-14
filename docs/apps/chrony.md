# :stopwatch: Chrony Service Configuration

This document covers the software configuration for the Stratum 1 NTP server detailed in `../nodes/pi-zero-ntp.md`. It utilizes `chrony` and `gpsd` to process the hardware signals, applies thermal drift compensation, and distributes time across the homelab.

## :thermometer: Thermal Compensation Setup

The Pi Zero W's quartz oscillator drifts based on CPU temperature. To maintain microsecond accuracy during a GPS lock loss, `chrony` needs a real-time feed of the SoC temperature.

Create the temperature wrapper script at `/usr/local/bin/get_cpu_temp.sh`:

!!! code

    ```bash
    #!/bin/bash
    # Outputs the Pi's SoC temperature in standard Celsius

    raw_temp=$(cat /sys/class/thermal/thermal_zone0/temp)
    awk "BEGIN {print $raw_temp/1000}"
    ```

Make it executable:

```bash
chmod +x /usr/local/bin/get_cpu_temp.sh
```

:snake: Tempcomp Coefficient Calculator

To generate the quadratic curve coefficients (k0, k1, k2) required by chrony, use this Python script. It parses a drift log and outputs the exact tempcomp directive, while generating a visual graph using the Catppuccin Mocha palette.
Save as calc_tempcomp.py:

```python
#!/usr/bin/env python3
import csv
import sys
import numpy as np

try:
  import matplotlib.pyplot as plt
  HAS_MATPLOTLIB = True
except ImportError:
  HAS_MATPLOTLIB = False

def main():
  if len(sys.argv) < 2:
    print("Usage: calc_tempcomp.py <log_file>")
    sys.exit(1)

  log_file = sys.argv[1]
  temps = []
  skews = []

  with open(log_file, 'r') as f:
    reader = csv.reader(f)
    for row in reader:
      try:
        temps.append(float(row[1]))
        skews.append(float(row[2]))
      except (ValueError, IndexError):
        continue

  if not temps:
    print("Error: No valid data found.")
    sys.exit(1)

  t_array = np.array(temps)
  skew_array = np.array(skews)
  t0 = np.round(np.mean(t_array), 2)
  delta_t = t_array - t0

  coeffs = np.polyfit(delta_t, skew_array, 2)
  k2, k1, k0 = coeffs

  print("--- Chrony Tempcomp Calculator ---")
  print(f"Data points analyzed: {len(t_array)}")
  print(f"Reference Temp (T0):  {t0}°C")
  print(f"k0 (Constant):        {k0:.6f}")
  print(f"k1 (Linear):          {k1:.6f}")
  print(f"k2 (Squared):         {k2:.6f}\n")
  print("Add this line to your chrony.conf:")
  print(f"tempcomp /usr/local/bin/get_cpu_temp.sh 1 {t0} {k0:.6f} {k1:.6f} {k2:.6f}")

  if HAS_MATPLOTLIB:
    # Catppuccin Mocha styling
    crust = "#11111b"
    text = "#cdd6f4"
    blue = "#89b4fa"
    flamingo = "#f2cdcd"

    plt.figure(facecolor=crust)
    ax = plt.axes()
    ax.set_facecolor(crust)
    
    for spine in ['bottom', 'top', 'right', 'left']:
      ax.spines[spine].set_color(text)
      
    ax.tick_params(axis='x', colors=text)
    ax.tick_params(axis='y', colors=text)
    ax.yaxis.label.set_color(text)
    ax.xaxis.label.set_color(text)
    ax.title.set_color(text)

    plt.scatter(t_array, skew_array, color=blue, alpha=0.5, label="Raw Skew Data")
    t_line = np.linspace(min(t_array), max(t_array), 100)
    skew_line = k2 * ((t_line - t0)**2) + k1 * (t_line - t0) + k0
    plt.plot(t_line, skew_line, color=flamingo, linewidth=2, label="Quadratic Fit")
    
    plt.xlabel("Temperature (°C)")
    plt.ylabel("Frequency Skew (ppm)")
    plt.title("Pi Zero W Quartz Thermal Drift")
    plt.legend(facecolor=crust, edgecolor=text, labelcolor=text)
    plt.show()

if __name__ == "__main__":
  main()
```

:page_facing_up: `chrony.conf`

This configuration prioritizes the PPS hardware interrupt, uses SHM to interface with gpsd for NMEA data, and enables leap smearing to protect infrastructure databases from sudden time jumps.

```ini
# /etc/chrony/chrony.conf

# 1. Primary Time Sources
# The physical PPS interrupt (Stratum 0) - Highly precise
refclock PPS /dev/pps0 refid PPS lock NMEA

# The NMEA serial data stream (via gpsd SHM)
refclock SHM 0 offset 0.135 delay 0.2 refid NMEA

# 2. Network Fallbacks (Stratum 2)
pool 2.debian.pool.ntp.org iburst

# 3. Time Adjustments & Leap Seconds
# Smear leap seconds over 24 hours to prevent sudden jumps
leapsecmode slew
maxslewrate 1000
makestep 1 3

# 4. Thermal Compensation
# (Replace coefficients after running calc_tempcomp.py)
tempcomp /usr/local/bin/get_cpu_temp.sh 1 45.0 0.0 0.25 0.005

# 5. Access Control
allow 10.0.0.0/8
allow 192.168.0.0/16

# 6. Logging & Directories
driftfile /var/lib/chrony/chrony.drift
logdir /var/log/chrony
log measurements statistics tracking
```

:mag: Verification & Monitoring
Restart the daemon to apply the configuration:
sudo systemctl restart chrony

!!! code "Check PPS source selection"

    ```bash
    chronyc sources -v
    ```

Ensure the `*` symbol appears next to the PPS reference, indicating it is the actively selected master source.


!!! code "Monitor hardware offset and drift"

    ```bash
    chronyc tracking
    ```

The System time value dictates the current microsecond error margin.