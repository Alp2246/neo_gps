# Changelog

## [1.0.0] — 2026-06-05

First public release: live GPS + NMEA web dashboard on PYNQ-Z2.

### Features

- **gps_web.py** — live map, fix badge, satellite SNR, NMEA tab (GGA/RMC/GSA/GSV/VTG/GLL)
- **neo_gps_pynq.py** — MMIO UART reader with process lock
- Pre-built **gps_uart.bin** (AXI UART Lite @ `0x42C00000`, 9600 baud)
- Hardware photos, wiring/architecture SVG, NMEA dashboard screenshot
- Live API + decoded NMEA JSON in `docs/`

### Verified live

- **36.767085° N, 34.542030° E** (Mersin, Turkey)
- 8 satellites, 65.2 m altitude, GPS fix
- Dashboard: http://192.168.2.99:8080
