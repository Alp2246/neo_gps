# PYNQ-Z2 + NEO-6M GPS — Türkçe Rehber

## Canlı konum (2026-06-05)

| Alan | Değer |
|------|-------|
| Fix | ✅ Var (SPS) |
| Enlem / Boylam | **36.767085° N, 34.542030° E** |
| Konum | Mersin |
| Rakım | 65.2 m |
| Uydu | 8 |
| UTC | 15:47:29 |

[Haritada aç](https://www.openstreetmap.org/?mlat=36.767085&mlon=34.542030#map=17/36.767085/34.542030)

---

## Kurulum

1. NEO-6M kablolama: VCC→Pin1, GND→Pin6, GPS TX→Pin10, GPS RX→Pin8
2. SSH: `xilinx@192.168.2.99` / `xilinx`
3. Bitstream yükle ve web'i başlat:

```bash
cd ~/neo_gps
echo gps_uart.bin | sudo tee /sys/class/fpga_manager/fpga0/firmware
bash start_web.sh
```

4. Tarayıcı: **http://192.168.2.99:8080**

---

## NMEA sekmesi

Dashboard'da **NMEA** sekmesinden GGA, RMC, GSA, GSV, VTG, GLL mesajlarını tek tek seçebilirsin. Her alanın ne anlama geldiği Türkçe açıklamalı.

Canlı örnek cümleler: [nmea_messages.json](nmea_messages.json)

---

## Sorun giderme

| Sorun | Çözüm |
|-------|-------|
| **Bus error** | Aynı anda `gps_web.py` ve `neo_gps_pynq.py` çalıştırma |
| Fix yok | Anteni açık gökyüzüne çevir, 1–2 dk bekle |
| FPGA `operating` değil | `gps_uart.bin` yükle |
| Port meşgul | `bash start_web.sh` (eski süreçleri öldürür) |

---

## Dosyalar

- `gps_web.py` — web panosu + NMEA çözücü
- `neo_gps_pynq.py` — terminal okuyucu
- `output/gps_uart.bin` — FPGA overlay
