# PYNQ-Z2 + NEO-6M GPS — NMEA Web Dashboard

[![Release v1.0.0](https://img.shields.io/github/v/release/Alp2246/pynq-z2-gps-nmea?label=release)](https://github.com/Alp2246/pynq-z2-gps-nmea/releases/tag/v1.0.0)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-PYNQ--Z2-red)](https://www.tul.com.tw)

**Canlı GPS** on **TUL PYNQ-Z2** (Zynq-7020): custom Vivado overlay, **AXI UART Lite** @ `0x42C00000`, Python **MMIO** (`/dev/mem`), browser dashboard with **OpenStreetMap**, satellite SNR chart, and **NMEA 0183 decoder** (GGA · RMC · GSA · GSV · VTG · GLL) with Turkish field explanations.

![PYNQ-Z2 with NEO-6M GPS module](docs/gps_hardware_setup.png)

---

## Live position (verified 2026-06-05)

| | |
|---|---|
| **Fix** | ✅ GPS fix (SPS) |
| **Coordinates** | **36.767085° N, 34.542030° E** |
| **Location** | Mersin, Turkey |
| **Altitude** | 65.2 m |
| **Satellites used** | 8 |
| **UTC time** | 15:47:29 |

📍 [Open in OpenStreetMap](https://www.openstreetmap.org/?mlat=36.767085&mlon=34.542030#map=17/36.767085/34.542030) · [Full API JSON](docs/sample_live_output.json) · [NMEA decode JSON](docs/nmea_messages.json)

---

## Web dashboard

**Pano** — live map, fix badge, lat/lon/alt, UTC clock, SNR bars per satellite.

![Live GPS map dashboard](docs/dashboard.png)

**NMEA tab** — one message type at a time; raw sentence + numbered fields with Turkish hints.

![NMEA GGA decoder — field-by-field](docs/nmea_gga_dashboard.png)

Supported sentences from the NEO-6M:

| Type | NMEA | Purpose |
|------|------|---------|
| **GGA** | `$GPGGA` | Fix quality, lat/lon, altitude, satellites used, HDOP |
| **RMC** | `$GPRMC` | Minimum navigation: position, speed, course, date |
| **GSA** | `$GPGSA` | Active satellites + PDOP/HDOP/VDOP |
| **GSV** | `$GPGSV` | Satellites in view (PRN, elevation, azimuth, SNR) |
| **VTG** | `$GPVTG` | Track and ground speed (knot + km/h) |
| **GLL** | `$GPGLL` | Geographic lat/lon + fix validity |

### Live NMEA samples (from board)

```
$GPGGA,154729.00,3646.02509,N,03432.52182,E,1,08,1.34,65.2,M,27.6,M,,*6F
$GPRMC,154729.00,A,3646.02509,N,03432.52182,E,0.385,,050626,,,A*76
$GPGSA,A,3,01,04,03,31,09,16,26,07,,,,,2.77,1.34,2.42*0B
$GPGSV,3,3,11,19,03,269,18,26,20,068,24,31,18,042,18*4C
$GPVTG,,T,,M,0.385,N,0.713,K,A*28
$GPGLL,3646.02509,N,03432.52182,E,154729.00,A,A*66
```

---

## Hardware

![Wiring diagram](docs/wiring_diagram.svg)

![NEO-6M module (u-blox GY-NEO6MV2)](docs/neo6m_module.png)

| NEO-6M | PYNQ-Z2 RPi header | FPGA pin |
|--------|-------------------|----------|
| **VCC** | Pin **1** (3.3 V) | — |
| **GND** | Pin **6** | — |
| **TX** → FPGA RX | Pin **10** | Y6 |
| **RX** ← FPGA TX | Pin **8** | V6 |

9600 baud NMEA 0183 · ceramic patch antenna with clear sky view.

---

## Quick start

SSH: `xilinx@192.168.2.99` (password `xilinx`)

```bash
cd ~/neo_gps
echo gps_uart.bin | sudo tee /sys/class/fpga_manager/fpga0/firmware
cat /sys/class/fpga_manager/fpga0/state    # operating
bash start_web.sh
```

Browser: **http://192.168.2.99:8080**

> Run **only one** GPS process (`gps_web.py` *or* `neo_gps_pynq.py`). Two clients on the same UART → **bus error**.

Terminal probe:

```bash
sudo python3 neo_gps_pynq.py --probe
```

---

## Architecture

![Data flow: NEO-6M → FPGA UART → Python → browser](docs/architecture.svg)

```
NEO-6M  ──UART 9600──►  axi_uartlite_0  ◄──MMIO──  gps_web.py  ◄──HTTP──  Browser
                         0x42C00000              :8080
```

---

## Repository layout

```
├── gps_web.py              # Web dashboard + NMEA decoder UI
├── neo_gps_pynq.py         # MMIO UART reader / probe
├── start_web.sh            # Start dashboard on the board
├── output/gps_uart.{bin,bit,hwh}
└── docs/
    ├── gps_hardware_setup.png
    ├── neo6m_module.png
    ├── dashboard.png
    ├── nmea_gga_dashboard.png
    ├── wiring_diagram.svg
    ├── architecture.svg
    ├── sample_live_output.json
    ├── sample_live_summary.json
    └── nmea_messages.json
```

---

## Rebuild bitstream (Vivado 2022.2)

```bat
cd vivado
run_build.bat    REM → output/gps_uart.*
```

---

## Requirements

- TUL PYNQ-Z2 + PYNQ image (Linux 5.4+)
- u-blox NEO-6M @ 9600 baud
- PC browser (map tiles from OpenStreetMap)

---

## License

MIT — see [LICENSE](LICENSE).

---

🇹🇷 [Türkçe kurulum rehberi](docs/README_TR.md)
