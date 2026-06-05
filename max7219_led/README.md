# PYNQ-Z2 + MAX7219 8×8 LED

**Bağımsız proje** — sadece LED matris. GPS, BMP280, OLED, web yok.

| Kod | Proje |
|-----|-------|
| 9928 | GPS web |
| 9930 | Sensor panel (OLED+BMP280+GPS) |
| **9940** | **Sadece MAX7219 LED** |

---

## Donanım

| MAX7219 | PYNQ RPi header |
|---------|-----------------|
| VCC | Pin **1** (3.3 V) |
| GND | Pin **6** |
| DIN | Pin **11** |
| CLK | Pin **13** |
| CS | Pin **15** |

Kendi bitstream: **3-bit AXI GPIO** @ `0x41200000`

---

## 1. Bitstream derle (PC, bir kez)

Vivado 2022.2:

```bat
cd max7219_led\vivado
run_build.bat
```

Çıktı: `max7219_led/output/max7219_led.bin`

---

## 2. Karta yükle

```bat
cd max7219_led
9940.bat
```

Kartta tek komut:

```bash
bash ~/max7219_led/start.sh
```

Sabit rakam göster:

```bash
sudo python3 display.py --mode digit --digit 8
```

---

## Dosyalar

```
max7219_led/
├── display.py          ← tek program
├── max7219.py          ← FPGA GPIO surucu
├── 9940.bat            ← PC deploy
├── vivado/             ← kendi bitstream
└── output/max7219_led.bin
```

---

## Diğer projelerle

Farklı bitstream — GPS veya I2C overlay yüklüyken 9940 deploy yeni overlay yükler. Aynı anda birden fazla overlay olmaz; LED projesine geçince GPS web durur (ve tersi).
