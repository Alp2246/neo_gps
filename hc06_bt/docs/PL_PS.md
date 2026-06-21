# PL vs PS — Katman Rehberi

> HC-06 projesinde **FPGA (PL)** ve **Linux (PS)** nasıl birlikte çalışır?

[← Ana README](../README.md)

![Veri akışı](pl_ps_akis.png)

---

## Tek cümlede

| Katman | Kim? | Ne yapar? |
|--------|------|-----------|
| **PL** | FPGA çipi | UART donanımı, pin 8/10, 9600 baud |
| **PS** | ARM + Linux | Python, web sunucu, internet tüneli |

**Köprü:** `neo_gps_pynq.py` → `/dev/mem` → `0x42C00000`

---

## PL — Programmable Logic

![PL tarafı](pl_tarafi.png)

### Görev listesi

- [x] `gps_uart.bin` bitstream yükle
- [x] AXI UART Lite IP çalıştır
- [x] Pin 8 (TX) ve Pin 10 (RX) sür
- [x] HC-06 ile seri haberleşme (9600)

### Yükleme

```bash
sudo cp gps_uart.bin /lib/firmware/
echo gps_uart.bin | sudo tee /sys/class/fpga_manager/fpga0/firmware
cat /sys/class/fpga_manager/fpga0/state   # → operating
```

### PL yoksa

```text
RuntimeError: FPGA bitstream yuklu degil
Unhandled fault: external abort (0x818) at 0xb6f4800c
```

### Pin haritası

| PL sinyali | RPi header | HC-06 |
|------------|------------|-------|
| UART TX | Pin **8** | RXD |
| UART RX | Pin **10** | TXD |

[wiring.svg](wiring.svg) · [wiring.png](wiring.png)

---

## PS — Processing System

![PS tarafı](ps_tarafi.png)

### Görev listesi

- [x] Linux boot (PYNQ image)
- [x] MMIO UART sürücü (`neo_gps_pynq.py`)
- [x] Web sohbet (`bt_web.py` :8082)
- [x] Echo / beacon (`bt_bridge.py`)
- [x] PC deploy (`deploy.ps1`, `9960.bat`)
- [x] İnternet tüneli (`internet.bat`)

### MMIO köprüsü

```python
UART_BASE_ADDR = 0x42C00000   # PL'deki UART IP
BAUD_RATE = 9600

class MmioUart:
    def write_byte(b): ...    # PS → PL → HC-06
    def read_byte(): ...      # HC-06 → PL → PS
```

### PS komutları

```bash
cd ~/hc06_bt
sudo python3 bt_web.py --skip-overlay --port 8082
sudo python3 bt_bridge.py --skip-overlay
```

### PC komutları

```bat
9960.bat          :: deploy + web
sohbet_ac.bat     :: tek tık başlat
internet.bat      :: trycloudflare.com linki
```

---

## Uçtan uca akış

```
┌──────────────── PL (FPGA) ────────────────┐  ┌──── PS (Linux) ────┐
│  axi_uartlite @ 0x42C00000                │  │ neo_gps_pynq.py    │
│  Pin 8 TX  ·  Pin 10 RX                   │◄─┤ bt_web.py :8082    │
└──────────────────┬────────────────────────┘  └─────────┬──────────┘
                   │ UART 9600                            │ HTTP / HTTPS
                   ▼                                      ▼
              ┌─────────┐                           ┌─────────────┐
              │ HC-06   │◄──── Bluetooth SPP ────►│ Telefon     │
              └─────────┘                           │ + Tarayıcı  │
                                                  └─────────────┘
```

### Mesaj rotaları

| Gönderen | Rota |
|----------|------|
| Web kullanıcısı | Tarayıcı → PS → PL → HC-06 → BT → telefon |
| Telefon | BT → HC-06 → PL → PS → tarayıcı |
| İnternet | `trycloudflare.com` → PC → PS → (aynı zincir) |

---

## Tek overlay kuralı

PL'de **aynı anda tek bitstream**:

| Proje | Bitstream | Pinler |
|-------|-----------|--------|
| GPS / HC-06 | `gps_uart.bin` | 8, 10 |
| MAX7219 | `max7219_led.bin` | 11, 13, 15 |
| MPU6050 | `i2c_gpio.bin` | 3, 5 |

---

## Hata ayıklama

| Belirti | Katman | Aksiyon |
|---------|--------|---------|
| `state` ≠ operating | **PL** | Bitstream yükle |
| Bus error `0x818` | **PL** | Overlay eksik |
| 0 byte RX | **Kablo** | Pin 8↔10, TXD kullan |
| Web 200, mesaj yok | **PS** | `pkill bt_bridge` |
| Link ölü | **PC** | `internet.bat` açık tut |
| BT eşleşti, veri yok | **Telefon** | Uygulamada Connect |

---

## Kaynaklar

- [README.md](../README.md) — ana proje
- [terminal_cikti.txt](terminal_cikti.txt) — loglar
- [sample_web_data.json](sample_web_data.json) — API örneği
