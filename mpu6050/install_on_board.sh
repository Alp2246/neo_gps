#!/bin/bash
set -e
DIR="${MPU_DIR:-/home/xilinx/mpu6050}"
SUDO_PASS="${SUDO_PASS:-xilinx}"

sudo_cmd() {
    if sudo -n true 2>/dev/null; then sudo "$@"
    else echo "$SUDO_PASS" | sudo -S "$@"; fi
}

cd "$DIR"
sed -i 's/\r$//' "$0" start.sh 2>/dev/null || true
chmod +x start.sh *.py 2>/dev/null || true

echo "[1/2] i2c_gpio bitstream..."
sudo_cmd cp i2c_gpio.bin /lib/firmware/i2c_gpio.bin
echo i2c_gpio.bin | sudo_cmd tee /sys/class/fpga_manager/fpga0/firmware >/dev/null
sleep 2
echo "      FPGA: $(cat /sys/class/fpga_manager/fpga0/state)"

echo "[2/2] I2C tarama..."
sudo_cmd python3 mpu6050.py --axi-gpio --scan || true
echo "Hazir: bash $DIR/start.sh"
