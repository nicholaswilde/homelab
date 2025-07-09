---
tags:
  - travel
---
# :airplane: Travel

My network setup when traveling.

## :toolbox: Equipment

- [Fire TV Stick Lite][3] to stream content on the stock TV.
- [TP-Link AC750 Wireless Portable Nano Travel Router][1] to provide my own network where my phone, computer, and Fire TV Stick is preconfigured to connect to.
- [CableGeeker Ethernet Splitter 1 to 2 High Speed 1000Mbps][2] to keep the existing networking devices on the network, such as a VOIP phone or streaming device.
- [Anker 511 USB C Charger 30W][5] to charge phones.
- [Anker Dual Port 12W USB A Charger Block with Foldable Plug][6] to power the splitter and router.
- [eufy Security, SpaceView Pro Video Baby Monitor E210][7]

## :bar_chart: Diagrams

The purpose of these diagrams and tables are for me to visualize and count the number of items I need to pack.

### :globe_with_meridians: Ethernet

``` mermaid
graph TD
    Charger["Anker Dual Port 12W USB A Charger Block"]
    Splitter["CableGeeker Splitter"]
    Router["TP-Link AC750 Router"]
    Phone["VOIP Phone/Router"]

    Wall -- Ethernet Cable --> Splitter
    Splitter -- Ethernet Cable --> Router
    Splitter -- Ethernet Cable --> Phone:::critical
    Charger -- "USB A to C Cable" --> Splitter
    Charger -- "USB A to Micro Cable" --> Router

    classDef critical stroke:#000,stroke-width:2px
```

### :zap: Power Connections

``` mermaid
graph TD
    Phone1["Android Phone 1"]
    Phone2["Android Phone 2"]
    Power1["Anker 511 USB C Charger 30W"]
    Power2["Anker B2692 USB C Charger 45W"]
    Power3["USB A Charger"]
    Power4["USB A Charger"]
    FireTV["Fire TV Stick Lite"]
    Monitor["Baby Monitor/Camera"]

    Power1 -- "USB C to C Cable" --> Phone1
    Power2 -- "USB C to C Cable" --> Phone2
    Power3 -- "USB A to Micro Cable" --> FireTV
    Power4 -- "USB C to Micro Cable" --> Monitor
```

## :electric_plug: Cables & Power Adapters

| Type      | Side A  | Side B | Qty | Notes                 |
|:---------:|:-------:|:------:|:---:|-----------------------|
| USB       | C       | C      | 2   | Phones                |
| USB       | A       | C      | 1   | Splitter              |
| USB       | A       | Micro  | 3   | Router & Baby Monitor |
| USB       | C       | -      | 1   | Watch                 |
| Ethernet  | RJ45    | RJ45   | 3   | Router                |
| Charger   | A       | -      | 2   | -                     |

## :rocket: Future

### :file_cabinet: Storage

I'd like to store my setup in a larger Maxpedition case, such as the [Maxpedition Fatty Pocket Organizer][4].

## :link: References

[1]: <https://a.co/d/4sFXb9O>
[2]: <https://a.co/d/h5E08TW>
[3]: <https://a.co/d/iRXi3Ef>
[4]: <https://www.amazon.com/dp/B005257ZDS/>
[5]: <https://www.amazon.com/dp/B0B2MP8XWK>
[6]: <https://www.amazon.com/dp/B07DFWKBF7>
[7]: <https://www.amazon.com/dp/B08G8MBWZ8>
