#!/usr/bin/env python3
"""
PYNQ-Z2 + MAX7219 8x8 LED — ayri proje, tek calistirma.
Sadece LED. GPS / sicaklik / OLED yok.
"""

import argparse
import time
from pathlib import Path

from max7219 import HEART, SMILE, Max7219
from overlay import load


def demo_cycle(led: Max7219):
    for n in range(10):
        led.show_digit(n)
        time.sleep(0.35)
    led.show_rows(HEART)
    time.sleep(0.8)
    led.show_rows(SMILE)
    time.sleep(0.8)
    led.clear()
    time.sleep(0.2)


def main():
    ap = argparse.ArgumentParser(description="MAX7219 LED — tek proje")
    ap.add_argument("--skip-overlay", action="store_true")
    ap.add_argument("--mode", choices=("demo", "digit"), default="demo")
    ap.add_argument("--digit", type=int, default=8)
    args = ap.parse_args()

    root = Path(__file__).resolve().parent
    if not args.skip_overlay:
        print("[1] max7219_led bitstream...")
        load(root / "max7219_led.bin")

    print("[2] MAX7219...")
    led = Max7219()
    print("[OK] Ctrl+C ile cik")
    try:
        if args.mode == "digit":
            while True:
                led.show_digit(args.digit % 10)
                time.sleep(1.0)
        else:
            while True:
                demo_cycle(led)
    except KeyboardInterrupt:
        print("\n[INFO] Durduruldu.")
    finally:
        led.clear()
        led.close()


if __name__ == "__main__":
    main()
