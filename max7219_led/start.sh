#!/bin/bash
set -e
cd "$(dirname "$0")"
[ -f max7219_led.bin ] || { echo "[HATA] max7219_led.bin yok — once vivado/run_build.bat"; exit 1; }
exec sudo python3 display.py "$@"
