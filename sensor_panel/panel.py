#!/usr/bin/env python3
"""
PYNQ-Z2 Sensor Panel — TEK CALISTIRMA

GPS (NEO-6M) + OLED (SSD1306) + BMP280 + MAX7219 LED matris
Combo bitstream: gps_i2c.bin (UART + I2C)

Kartta:
  sudo python3 panel.py
  veya: bash start.sh

NOT: GPS web (9928 / neo-gps.service) ile AYNI ANDA calismaz — ayni UART.
"""

import argparse
import mmap
import os
import struct
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "drivers"))

from axi_gpio_i2c import AxiGpioI2C  # noqa: E402
from bmp280 import BMP280  # noqa: E402
from max7219 import MAX7219  # noqa: E402
from ssd1306 import SSD1306  # noqa: E402

from overlay import load_overlay  # noqa: E402

UART_BASE = 0x42C00000
GPIO_BASE = 0x41200000
MAP_SIZE = 0x1000


class MmioUart:
    RX, TX, SR, CR = 0x00, 0x04, 0x08, 0x0C
    SR_RX_VALID = 0x01

    def __init__(self, base=UART_BASE):
        self._fd = os.open("/dev/mem", os.O_RDWR | os.O_SYNC)
        self._map = mmap.mmap(
            self._fd, MAP_SIZE, mmap.MAP_SHARED,
            mmap.PROT_READ | mmap.PROT_WRITE, offset=base,
        )

    def read_byte(self):
        self._map.seek(self.SR)
        if struct.unpack("<I", self._map.read(4))[0] & self.SR_RX_VALID:
            self._map.seek(self.RX)
            return struct.unpack("<I", self._map.read(4))[0] & 0xFF
        return None

    def close(self):
        self._map.close()
        os.close(self._fd)


def _checksum_ok(s):
    if "*" not in s:
        return True
    body, _, cs = s[1:].partition("*")
    try:
        calc = 0
        for ch in body:
            calc ^= ord(ch)
        return calc == int(cs[:2], 16)
    except ValueError:
        return False


def _dm_to_dec(value, direction, deg_digits):
    if not value or not direction:
        return None
    try:
        deg = float(value[:deg_digits])
        minutes = float(value[deg_digits:])
        dec = deg + minutes / 60.0
        if direction in ("S", "W"):
            dec = -dec
        return dec
    except ValueError:
        return None


class GpsState:
    def __init__(self):
        self.fix = False
        self.lat = None
        self.lon = None
        self.sats = 0
        self.utc = ""
        self.quality = 0

    def feed(self, line):
        if not line.startswith("$") or not _checksum_ok(line):
            return
        p = line.strip().split("*")[0].split(",")
        head = p[0]
        talker = head[3:] if len(head) >= 6 else head
        if talker == "GGA" and len(p) >= 10:
            self.utc = p[1]
            self.quality = int(p[6]) if p[6].isdigit() else 0
            self.sats = int(p[7]) if p[7].isdigit() else 0
            lat = _dm_to_dec(p[2], p[3], 2)
            lon = _dm_to_dec(p[4], p[5], 3)
            if lat is not None and lon is not None:
                self.lat, self.lon = lat, lon
            self.fix = self.quality > 0
        elif talker == "RMC" and len(p) >= 7 and p[2] == "A":
            self.utc = p[1]
            lat = _dm_to_dec(p[3], p[4], 2)
            lon = _dm_to_dec(p[5], p[6], 3)
            if lat is not None and lon is not None:
                self.lat, self.lon = lat, lon
                self.fix = True


def fmt_utc(utc):
    if len(utc) >= 6:
        return f"{utc[0:2]}:{utc[2:4]}:{utc[4:6]}"
    return "--:--:--"


def render_oled(oled, gps, env):
    oled.clear()
    oled.text("SENSOR PANEL", 0, 0)
    st = "FIX" if gps.fix else "NO FIX"
    oled.text(st, 88, 0)
    oled.hline(0, 9, 128)
    if gps.lat is not None:
        oled.text("Lat %.5f" % gps.lat, 0, 13)
    else:
        oled.text("Lat  ---", 0, 13)
    if gps.lon is not None:
        oled.text("Lon %.5f" % gps.lon, 0, 23)
    else:
        oled.text("Lon  ---", 0, 23)
    oled.text("Sats %2d" % gps.sats, 0, 35)
    oled.text("UTC " + fmt_utc(gps.utc), 64, 35)
    if env:
        oled.text("%.1f C" % env["temp_c"], 0, 47)
        oled.text("%.0f hPa" % env["press_hpa"], 50, 47)
        oled.text("Baro %dm" % env["alt_baro_m"], 0, 57)
    else:
        oled.text("BMP280 yok", 0, 47)
    oled.show()


def main():
    ap = argparse.ArgumentParser(description="PYNQ sensor panel (tek calistirma)")
    ap.add_argument("--skip-overlay", action="store_true")
    ap.add_argument("--no-led", action="store_true")
    ap.add_argument("--no-bmp", action="store_true")
    ap.add_argument("--no-oled", action="store_true")
    args = ap.parse_args()

    bin_path = ROOT / "gps_i2c.bin"
    if not args.skip_overlay:
        print("[1] Combo bitstream yukleniyor...")
        load_overlay(bin_path, fw_name="gps_i2c.bin", force=True)
    else:
        print("[1] Bitstream atlandi (--skip-overlay)")

    print("[2] Cihazlar aciliyor...")
    i2c = AxiGpioI2C(base=GPIO_BASE)
    found = i2c.scan()
    print("    I2C:", [hex(a) for a in found])

    oled = None
    if not args.no_oled:
        try:
            addr = 0x3C if 0x3C in found else (0x3D if 0x3D in found else None)
            if addr is None:
                raise RuntimeError("OLED bulunamadi")
            oled = SSD1306(i2c, addr=addr)
            oled.clear()
            oled.text("Sensor Panel", 0, 0)
            oled.text("Basliyor...", 0, 20)
            oled.show()
            print(f"    OLED @ 0x{addr:02X}")
        except Exception as e:
            print(f"    [UYARI] OLED: {e}")
            oled = None

    bmp = None
    if not args.no_bmp:
        try:
            bmp = BMP280(i2c)
            print(f"    BMP280 @ 0x{bmp.addr:02X}")
        except Exception as e:
            print(f"    [UYARI] BMP280: {e}")

    led = None
    if not args.no_led:
        try:
            led = MAX7219()
            led.clear()
            print("    MAX7219 OK")
        except Exception as e:
            print(f"    [UYARI] MAX7219: {e}")

    uart = MmioUart()
    gps = GpsState()
    buf = bytearray()
    last_draw = 0.0
    env = None

    print("[OK] Panel calisiyor. Ctrl+C ile cik.")
    try:
        while True:
            b = uart.read_byte()
            if b is None:
                time.sleep(0.002)
            else:
                if b == 0x0A:
                    line = buf.decode("ascii", errors="ignore").strip()
                    buf.clear()
                    if line:
                        gps.feed(line)
                elif b != 0x0D:
                    buf.append(b)
                    if len(buf) > 200:
                        buf.clear()

            now = time.monotonic()
            if now - last_draw >= 1.0:
                if bmp:
                    try:
                        env = bmp.read()
                    except OSError:
                        pass
                if oled:
                    render_oled(oled, gps, env)
                if led:
                    led.show_sats(gps.sats, gps.fix)
                last_draw = now
    except KeyboardInterrupt:
        print("\n[INFO] Durduruldu.")
    finally:
        uart.close()
        i2c.close()
        if led:
            led.clear()


if __name__ == "__main__":
    main()
