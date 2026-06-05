#!/bin/bash
set -e
DIR="${LED_DIR:-/home/xilinx/max7219_led}"
SUDO_PASS="${SUDO_PASS:-xilinx}"

sudo_cmd() {
    if sudo -n true 2>/dev/null; then sudo "$@"
    else echo "$SUDO_PASS" | sudo -S "$@"; fi
}

cd "$DIR"
sed -i 's/\r$//' "$0" start.sh install_boot_service.sh 2>/dev/null || true
chmod +x start.sh install_boot_service.sh display.py

[ -f max7219_led.bin ] || { echo "[HATA] max7219_led.bin yok"; exit 1; }

echo "[1/2] Bitstream..."
sudo_cmd cp max7219_led.bin /lib/firmware/max7219_led.bin
echo max7219_led.bin | sudo_cmd tee /sys/class/fpga_manager/fpga0/firmware >/dev/null
sleep 2
echo "      FPGA: $(cat /sys/class/fpga_manager/fpga0/state)"

echo "[2/2] Servis..."
bash install_boot_service.sh
