#!/usr/bin/env python3
"""HC-06 hizli test — 8 sn dinle + test mesaji gonder."""
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from neo_gps_pynq import MmioUart, ensure_fpga_operating

ensure_fpga_operating()
uart = MmioUart()
print("[TX] PYNQ TEST -> HC-06")
for b in b"PYNQ TEST\r\n":
    uart.write_byte(b)

n = 0
t0 = time.time()
print("[RX] 8 sn dinleniyor (telefondan mesaj gonder)...")
while time.time() - t0 < 8:
    b = uart.read_byte()
    if b is not None:
        n += 1
        ch = chr(b) if 32 <= b < 127 else "."
        print(f"  byte {n}: {b:3d} '{ch}'")
    time.sleep(0.002)

uart.close()
print(f"[SONUC] {n} byte alindi")
if n == 0:
    print("  -> Kablo TX/RX capraz mi? Telefon eslesti mi? HC-06 LED yanıyor mu?")
else:
    print("  -> HC-06 CALISIYOR")
