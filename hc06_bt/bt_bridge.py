#!/usr/bin/env python3
"""
PYNQ-Z2 + HC-06 Bluetooth (SPP seri kopru).

Kablolama (GPS ile ayni UART pinleri — GPS takili degilken):
  HC-06 VCC -> Pin 1 (3.3V)
  HC-06 GND -> Pin 6
  HC-06 TXD -> Pin 10  (modul TX -> FPGA RX)
  HC-06 RXD -> Pin 8   (modul RX <- FPGA TX)

Telefon: Bluetooth Serial Terminal uygulamasi, HC-06 eslestir (PIN 1234).
"""
import argparse
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent))
sys.path.insert(0, str(ROOT))

from neo_gps_pynq import MmioUart, ensure_fpga_operating, load_overlay_sysfs


def send_line(uart: MmioUart, text: str) -> None:
    for ch in text:
        uart.write_byte(ord(ch))
    uart.write_byte(0x0D)
    uart.write_byte(0x0A)


def echo_loop(uart: MmioUart) -> None:
    print("[HC-06] Echo modu — telefondan gelen her satir geri gider. Ctrl+C cik.")
    buf = bytearray()
    while True:
        b = uart.read_byte()
        if b is None:
            time.sleep(0.005)
            continue
        if b in (0x0A, 0x0D):
            if buf:
                line = buf.decode("utf-8", errors="replace")
                print(f"< {line}")
                send_line(uart, f"ECHO: {line}")
                buf.clear()
        elif 32 <= b < 127 or b >= 128:
            buf.append(b)
        if len(buf) > 200:
            buf.clear()


def beacon_loop(uart: MmioUart, interval: float) -> None:
    print(f"[HC-06] Beacon modu — her {interval}s PYNQ mesaji. Ctrl+C cik.")
    n = 0
    while True:
        msg = f"PYNQ-Z2 HC-06 #{n}"
        send_line(uart, msg)
        print(f"> {msg}")
        n += 1
        time.sleep(interval)


def main():
    ap = argparse.ArgumentParser(description="HC-06 Bluetooth bridge")
    ap.add_argument("--skip-overlay", action="store_true")
    ap.add_argument("--mode", choices=("echo", "beacon"), default="echo")
    ap.add_argument("--interval", type=float, default=2.0)
    args = ap.parse_args()

    bin_path = ROOT / "gps_uart.bin"
    if not args.skip_overlay and bin_path.is_file():
        load_overlay_sysfs(bin_path)
    ensure_fpga_operating()

    uart = MmioUart()
    send_line(uart, "PYNQ HC-06 hazir")
    try:
        if args.mode == "beacon":
            beacon_loop(uart, args.interval)
        else:
            echo_loop(uart)
    except KeyboardInterrupt:
        print("\n[INFO] Durduruldu.")
    finally:
        uart.close()


if __name__ == "__main__":
    main()
