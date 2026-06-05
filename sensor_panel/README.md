# PYNQ-Z2 Sensor Panel

**Ayrı proje** — GPS web dashboard (`9928`) ile karışmaz.

Tek çalıştırma: **GPS + OLED + BMP280 + MAX7219 LED** aynı döngüde güncellenir.

| Proje | Kod | Ne yapar |
|-------|-----|----------|
| GPS Web | `9928.bat` | Tarayıcı harita + NMEA |
| **Sensor Panel** | **`9930.bat`** | Fiziksel ekranlar |

> **UART paylaşımı:** İkisi aynı anda çalışmaz. 9930, `neo-gps.service`'i otomatik durdurur.

---

## Modüller

| Modül | Arayüz | Pinler |
|-------|--------|--------|
| NEO-6M GPS | UART (FPGA) | TX→Pin **10**, RX→Pin **8** |
| SSD1306 OLED | I2C | SDA Pin **3**, SCL Pin **5** |
| BMP280 | I2C (aynı hat) | SDA **3**, SCL **5** |
| MAX7219 8×8 | GPIO | DIN Pin **11**, CLK **13**, CS **15** |
| Güç | — | VCC Pin **1**, GND Pin **6** |

Bitstream: **`gps_i2c.bin`** (UART + I2C combo)

---

## PC'den yükle (SD kart yok)

```bat
cd C:\Users\oalpe\Desktop\neo_gps\sensor_panel
9930.bat
```

Kartta tek seferlik:

```bash
cd ~/sensor_panel && bash start.sh
```

Açılışta otomatik: `neo-sensor-panel.service` (9930 kurar)

---

## Ekranda ne görürsün?

**OLED:** Fix, lat/lon, uydu, UTC, sıcaklık, basınç, baro rakım

**MAX7219:** Fix yok → X ikonu · Fix var → uydu sayısı (0–9)

---

## GPS web'e dönmek

```bat
9928.bat
```

Bu, sensor panel servisini durdurup web panosunu kurar.

---

## Dosyalar

```
sensor_panel/
├── 9930.bat              ← PC deploy
├── panel.py              ← TEK program
├── start.sh              ← kartta tek calistirma
├── gps_i2c.bin           ← deploy ile yuklenir
└── drivers/
    ├── bmp280.py
    ├── max7219.py
    ├── ssd1306.py
    └── axi_gpio_i2c.py
```
