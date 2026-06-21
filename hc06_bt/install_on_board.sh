#!/bin/bash
set -e
DIR="${BT_DIR:-/home/xilinx/hc06_bt}"
SUDO_PASS="${SUDO_PASS:-xilinx}"

sudo_cmd() {
    if sudo -n true 2>/dev/null; then sudo "$@"
    else echo "$SUDO_PASS" | sudo -S "$@"; fi
}

cd "$DIR"
sed -i 's/\r$//' "$0" start.sh 2>/dev/null || true
chmod +x *.py start.sh 2>/dev/null || true

echo "[1/2] gps_uart bitstream (HC-06 UART)..."
sudo_cmd cp gps_uart.bin /lib/firmware/gps_uart.bin
echo gps_uart.bin | sudo_cmd tee /sys/class/fpga_manager/fpga0/firmware >/dev/null
sleep 2
echo "      FPGA: $(cat /sys/class/fpga_manager/fpga0/state)"

echo "[2/2] Hazir."
echo "  Terminal: sudo python3 bt_bridge.py"
echo "  Web:      sudo python3 bt_web.py --port 8082"
