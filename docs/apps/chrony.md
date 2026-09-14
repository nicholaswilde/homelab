# :stopwatch: Chrony Service Configuration

This document covers the software configuration for the [Stratum 1 NTP server](https://en.wikipedia.org/wiki/Network_Time_Protocol#Clock_strata?wprov=sfla1) detailed in [Raspberry Pi Zero W 1](../hardware/rpi0.md). It utilizes `chrony` and `gpsd` to process the hardware signals, applies thermal drift compensation, and distributes time across the homelab.

## :thermometer: Thermal Compensation Setup

The Pi Zero W's quartz oscillator drifts based on CPU temperature. To maintain microsecond accuracy during a GPS lock loss, `chrony` needs a real-time feed of the SoC temperature.

Create the temperature wrapper script:

!!! abstract "/usr/local/bin/get_cpu_temp.sh"

    ```bash
    #!/usr/bin/env bash
    # Outputs the Pi's SoC temperature in standard Celsius

    raw_temp=$(cat /sys/class/thermal/thermal_zone0/temp)
    awk "BEGIN {print $raw_temp/1000}"
    ```

!!! code "Make it executable"

    ```bash
    chmod +x /usr/local/bin/get_cpu_temp.sh
    ```

### :snake: Tempcomp Coefficient Calculator

To generate the quadratic curve coefficients (k0, k1, k2) required by chrony, use this Python script. It parses a drift log and outputs the exact tempcomp directive, while generating a visual graph using the Catppuccin Mocha palette.
Save as calc_tempcomp.py:

??? abstract "calc_tempcomp.py"

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

### :page_facing_up: `chrony.conf`

This configuration prioritizes the PPS hardware interrupt, uses SHM to interface with gpsd for NMEA data, and enables leap smearing to protect infrastructure databases from sudden time jumps.

??? abstract "/etc/chrony/chrony.conf"

    ```bash
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

## :mag: Verification & Monitoring

Restart the daemon to apply the configuration:

```bash
sudo systemctl restart chrony
```

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

## :chart_with_upwards_trend: Time Error Testing & Comparison

To evaluate synchronization accuracy and quantify error margins, measure time offsets on both the NTP server and client machines.

### 1. Source Error & Jitter Analysis (Server)

Run `chronyc sourcestats` on `pi00` to inspect error margins and jitter across all registered sources:

!!! code "Inspect source jitter and estimated offset"

    ```bash
    chronyc sourcestats -v
    ```

Key metrics to evaluate:

* **Offset:** Estimated time difference between the local clock and the source. For PPS, this typically stays within ±1 µs.
* **Std Dev:** Standard deviation of the offset estimates (jitter). PPS jitter is typically low microseconds or sub-microsecond.

### 2. Client Offset Testing

From any client machine on the network, query the local NTP server in query-only mode to measure the time offset without altering the client's clock:

!!! code "Query offset using chronyd (one-shot query)"

    ```bash
    chronyd -q 'server 192.168.2.190 iburst'
    ```

Alternatively, test using `sntp`:

!!! code "Query offset using sntp"

    ```bash
    sntp 192.168.2.190
    ```

### 3. Local Stratum 1 vs Public Pool Comparison

Comparing the local GPS/PPS node against public upstream servers highlights the error reduction achieved on a local Stratum 1 server:

| Metric | Local GPS/PPS Node (`pi00`) | Public Upstream Pool (`pool.ntp.org`) |
| :--- | :--- | :--- |
| **Stratum** | **Stratum 1** (Direct hardware reference) | **Stratum 2 / 3** (Hops over WAN) |
| **Network Round-Trip** | **0.1 – 0.5 ms** (LAN) | **15 – 60 ms** (Internet routing) |
| **Network Jitter** | **< 50 µs** | **1 – 10 ms** (WAN bufferbloat / route variance) |
| **Server Offset Error** | **< 1 µs** (SoC locked to PPS interrupt) | **1 – 5 ms** (Subject to asymmetric routing) |
| **Client Synchronization** | **Sub-millisecond (< 100 µs)** | **1 – 10 ms** |
| **Availability** | **Autonomous** (Continues during ISP outages) | **Requires WAN access** |

## :simple-ubiquiti: UniFi Network Configuration

To distribute time from the Raspberry Pi Zero W (`192.168.2.190`) across the homelab, configure UniFi Network to serve both UniFi infrastructure devices and DHCP clients.

### 1. Device NTP (UniFi Infrastructure)

Configure the UniFi Gateway, switches, and access points to synchronize with the local NTP server:

1. Open the **UniFi Network** dashboard.
2. Navigate to **Settings** > **System** > **Advanced**.
3. In the **NTP** section, set the server mode to **Custom**.
4. Add the Pi Zero W IP address: `192.168.2.190`.
5. (Optional) Add a fallback public pool (such as `time.cloudflare.com` or `pool.ntp.org`).
6. Click **Apply Changes**.

### 2. DHCP NTP Distribution (Clients & VLANs)

Advertise the NTP server via DHCP (Option 42) so client devices on local networks automatically use the Stratum 1 node:

1. Navigate to **Settings** > **Networks**.
2. Select a target network or VLAN (e.g., *Default*, *IoT*).
3. Expand **Advanced** (or scroll to **DHCP Service**).
4. Under **NTP**, switch from **Auto** to **Manual**.
5. Set the primary NTP server to `192.168.2.190`.
6. Click **Apply Changes**. Repeat for any additional VLANs.

### 3. Verify Client Activity

Verify on the Pi Zero W that UniFi devices and network clients are actively querying the server:

!!! code "List active NTP clients and query statistics"

    ```bash
    chronyc clients
    ```

## :wrench: Troubleshooting

Use `chronyc` and system diagnostics to identify whether the hardware PPS signal or the GPS serial stream is failing.

### 1. Diagnosing PPS Signal & Hardware Interrupts

Run `chronyc sources -v` to inspect the status of the `PPS` refclock:

* **State Symbol (`S`):**
    * `*` (Best / Current): Normal. PPS is the active master synchronization source.
    * `?` (Unreachable): Chrony is not receiving pulse events from the PPS device.
    * `x` (Falseticker): Chrony rejected PPS because its timestamps disagree with the secondary sources (often caused by an invalid NMEA offset).
* **Reach Value (`Reach`):**
    * `377`: Fully healthy (octal representation of `11111111`, indicating 8 successful consecutive pulses).
    * `0` (or failing to reach `377`): Chrony is missing pulse interrupts.

!!! code "Check detailed source selection diagnostics"

    ```bash
    chronyc selectdata -v
    ```

If the PPS source is marked unreachable (`?`) or has `Reach 0`:

1. **Verify Kernel Registration:**
    ```bash
    dmesg | grep -i pps
    ```
    Ensure a line like `pps pps0: new PPS source pps-gpio.-1` appears. If it registered under `pps1`, update `/etc/chrony/chrony.conf` to use `/dev/pps1`.
2. **Test Raw Hardware Pulses:**
    ```bash
    sudo ppstest /dev/pps0
    ```
    If `ppstest` times out (`connection timed out`), verify the physical connection to GPIO 4 (Pin 7), confirm the HAT is firmly seated, and ensure the GPS antenna has an unobstructed view of the sky (the receiver only emits PPS once satellite lock is acquired).

### 2. Diagnosing GPS / NMEA Data Stream

Chrony relies on the NMEA data stream (via `gpsd` SHM) to identify the correct second for the PPS pulse.

Run `chronyc sources -v` and examine the `NMEA` entry:

* If `NMEA` shows `?` or `Reach 0`, Chrony cannot read the SHM segment from `gpsd`.
* If `NMEA` shows `x`, its offset difference from the network pool or PPS is too large. Adjust the `offset` parameter in `/etc/chrony/chrony.conf`.

Run the following checks to isolate GPS connection issues:

1. **Verify Serial Data Stream:**
    ```bash
    sudo cat /dev/serial0
    ```
    Raw NMEA sentences (e.g., `$GNRMC`, `$GNGGA`) should continuously scroll across the terminal. If blank:
    * Ensure the serial console was disabled in `/boot/cmdline.txt`.
    * Verify `enable_uart=1` and `dtoverlay=disable-bt` are present in `/boot/config.txt`.
2. **Verify `gpsd` Daemon Status:**
    ```bash
    sudo systemctl status gpsd
    ```
3. **Inspect Satellite Fix and Signal Quality:**
    ```bash
    cgps -s
    ```
    Confirm that `Status` indicates **3D FIX** and at least 4 satellites are actively used. If in **NO FIX** or **2D FIX** status, relocate the antenna to a clear window or exterior mounting point.

## :link: References

- [Raspberry Pi Zero W NTP Node](../hardware/rpi0.md)
- [UniFi Network Documentation](../hardware/unifi.md)
- [Chrony Documentation](https://chrony-project.org/doc/4.5/chrony.conf.html)
