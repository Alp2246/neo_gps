# PYNQ-Z2 + HC-06 Bluetooth

### FPGA UART · Web Sohbet · İnternetten Paylaşılabilir Link

[![Kod 9960](https://img.shields.io/badge/Kod-9960-0ea5e9?style=for-the-badge)](9960.bat)
[![PYNQ-Z2](https://img.shields.io/badge/Platform-PYNQ--Z2-e11d48?style=for-the-badge)](https://www.tul.com.tw)
[![FPGA](https://img.shields.io/badge/PL-gps__uart.bin-22c55e?style=for-the-badge)](#pl-vs-ps--zynq-iki-dünyası)
[![Linux](https://img.shields.io/badge/PS-Python_Web-f59e0b?style=for-the-badge)](#pl-vs-ps--zynq-iki-dünyası)
[![9600 baud](https://img.shields.io/badge/UART-9600-8b5cf6?style=for-the-badge)]()

**Zynq-7020** kartında **HC-06** modülü: PL tarafında **AXI UART Lite**, PS tarafında **Python MMIO** + **WhatsApp tarzı web sohbet**. Tek tıkla deploy, telefonla Bluetooth, `internet.bat` ile dünyaya link.

| | |
|---|---|
| **Yerel sohbet** | http://192.168.2.99:8082 |
| **Deploy** | `9960.bat` çift tık |
| **İnternet linki** | `internet.bat` → `trycloudflare.com` |
| **PL / PS rehber** | [docs/PL_PS.md](docs/PL_PS.md) |

---

## 3 adımda başla

```
  1. Kablola          2. Deploy et           3. Sohbet et
  ─────────          ──────────             ───────────
  HC-06 → Pin 1/6    9960.bat               Tarayıcı :8082
  TXD → 10           veya sohbet_ac.bat     veya internet.bat
  RXD → 8                                   → linki paylaş
```

```bat
cd hc06_bt
sohbet_ac.bat      :: kart + web
internet.bat       :: dünyaya link (pencere açık kalsın)
```

---

## Görseller

<table>
<tr>
<td width="50%">

**Veri akışı — PL ↔ PS ↔ HC-06**

![PL ↔ PS veri akışı](docs/pl_ps_akis.png)

</td>
<td width="50%">

**Web sohbet arayüzü**

![Web sohbet](docs/chat_web.png)

</td>
</tr>
<tr>
<td>

**Kablolama**

![HC-06 kablolama](docs/wiring.png)

</td>
<td>

**Katmanlar**

| | PL (FPGA) | PS (Linux) |
|---|-----------|------------|
| Dosya | `gps_uart.bin` | `bt_web.py` |
| Adres | `0x42C00000` | `:8082` |
| İş | UART pinleri | Web + köprü |

</td>
</tr>
</table>

---

## PL vs PS — Zynq iki dünyası

PYNQ-Z2 iki parçadan oluşur. Bu proje **ikisini köprüler**.

### PL — Programmable Logic (FPGA, donanım)

![PL tarafı](docs/pl_tarafi.png)

Vivado'da tasarlanan **AXI UART Lite** IP → `gps_uart.bin` yüklenir → `operating` → **Pin 8/10** üzerinden HC-06 ile **9600 baud** UART.

### PS — Processing System (ARM, yazılım)

![PS tarafı](docs/ps_tarafi.png)

Linux + Python: `neo_gps_pynq.py` register okur/yazar, `bt_web.py` HTTP sunar, `internet.bat` Cloudflare tüneli açar.

📖 Derinlemesine: **[docs/PL_PS.md](docs/PL_PS.md)** — akış diyagramı, hata ayıklama, dosya haritası

---

## Ne yapıyor?

| Mod | Komut | Kullanım |
|-----|-------|----------|
| **Web sohbet** | `bt_web.py` | Tarayıcıdan mesaj, API `/data` |
| **Echo** | `bt_bridge.py` | Telefon ↔ terminal köprüsü |
| **Beacon** | `bt_bridge.py --mode beacon` | Periyodik test mesajı |
| **Hızlı test** | `quick_test.py` | 8 sn RX + TX probe |
| **İnternet** | `internet.bat` | Paylaşılabilir HTTPS link |

---

## Canlı çıktılar

<details>
<summary><b>FPGA — bitstream yüklü</b></summary>

```bash
$ cat /sys/class/fpga_manager/fpga0/state
operating
```

</details>

<details>
<summary><b>UART testi — HC-06 çalışıyor</b></summary>

```text
[OK] FPGA state: operating
[TX] PYNQ TEST -> HC-06
[RX] 8 sn dinleniyor (telefondan mesaj gonder)...
  byte 1: 116 't'
  byte 2: 101 'e'
  byte 3: 115 's'
  byte 4: 116 't'
[SONUC] 4 byte alindi
  -> HC-06 CALISIYOR
```

</details>

<details>
<summary><b>Web API — GET /data</b></summary>

```json
{
  "messages": [
    {"who": "Ayse", "text": "selam", "src": "web", "ts": 1718995200},
    {"who": "Telefon", "text": "merhaba", "src": "bt", "ts": 1718995205}
  ],
  "tx_count": 3,
  "rx_count": 1
}
```

</details>

Log arşivi: [terminal_cikti.txt](docs/terminal_cikti.txt) · [sample_web_data.json](docs/sample_web_data.json)

---

## Donanım

![Kablolama şeması](docs/wiring.svg)

| HC-06 | PYNQ pin | Açıklama |
|-------|----------|----------|
| VCC | **1** | 3.3 V — LED yanmalı |
| GND | **6** | Toprak |
| TXD | **10** | Modül TX → FPGA RX |
| RXD | **8** | Modül RX ← FPGA TX |

> GPS ile **aynı UART** (`gps_uart.bin`). İkisi birden takma. Çalışmazsa **Pin 8 ↔ 10** değiştir.

### Sık hatalar

| Belirti | Çözüm |
|---------|--------|
| LED sönük | VCC / GND |
| 0 byte RX | Kablo + uygulamada **Connect** |
| Web yok | `sudo pkill -f bt_bridge.py` |

---

## Telefon

1. Bluetooth → **HC-06** / **linvor** → PIN **1234**
2. **Serial Bluetooth Terminal** kur
3. Uygulama içinde **Connect** → mesaj gönder

> Ayarlarda eşleştirmek yetmez — uygulamada bağlanmak şart.

---

## İnternetten paylaş

```
  Tarayıcı  ──HTTPS──►  trycloudflare.com  ──►  PC  ──►  PYNQ :8082
                                                          └──► HC-06 ──BT──► Telefon
```

```bat
internet.bat
```

Çıkan `https://xxxx.trycloudflare.com` linkini paylaş. **Pencere açık kalmalı.**

---

## Kartta manuel

```bash
cd ~/hc06_bt
echo gps_uart.bin | sudo tee /sys/class/fpga_manager/fpga0/firmware
sudo python3 bt_web.py --skip-overlay --port 8082
sudo python3 bt_bridge.py --skip-overlay
sudo python3 quick_test.py
```

---

## Dosya yapısı

```
hc06_bt/
├── 9960.bat              # Deploy (Windows)
├── sohbet_ac.bat         # Deploy + web
├── internet.bat          # Cloudflare tüneli
├── bt_web.py             # Web sohbet sunucusu
├── bt_bridge.py          # Echo / beacon
├── quick_test.py         # UART test
├── deploy.ps1            # SSH yükleme
└── docs/
    ├── PL_PS.md          # PL vs PS rehberi
    ├── pl_tarafi.png     # FPGA katmanı
    ├── ps_tarafi.png     # Linux katmanı
    └── pl_ps_akis.png    # Veri akışı
```

---

## neo_gps proje ailesi

| Kod | Proje | Deploy |
|-----|-------|--------|
| 9928 | GPS NMEA | `9928.bat` |
| 9940 | MAX7219 LED | `9940.bat` |
| 9950 | MPU6050 | `9950.bat` |
| 9930 | Sensor panel | `9930.bat` |
| **9960** | **HC-06 BT** | **`9960.bat`** |

Menü: `YUKLE.bat` → **6**

---

## Gereksinimler

- TUL PYNQ-Z2 · HC-06 @ 9600 baud
- Windows + PuTTY (`plink`, `pscp`)
- Kart: `xilinx` / `xilinx` @ `192.168.2.99`

---

MIT · [Ana repo](../README.md) · [Galeri](../docs/gallery/) · [PL/PS rehberi](docs/PL_PS.md)
