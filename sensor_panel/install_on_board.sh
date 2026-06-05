#!/bin/bash
# Sensor panel kurulum — PC'den 9930.bat ile cagrilir
set -e
DIR="${PANEL_DIR:-/home/xilinx/sensor_panel}"
SUDO_PASS="${SUDO_PASS:-xilinx}"

sudo_cmd() {
    if sudo -n true 2>/dev/null; then sudo "$@"
    else echo "$SUDO_PASS" | sudo -S "$@"; fi
}

cd "$DIR"
for f in "$0" start.sh install_boot_service.sh; do
    sed -i 's/\r$//' "$f" 2>/dev/null || true
done
chmod +x start.sh install_boot_service.sh panel.py 2>/dev/null || true

[ -f gps_i2c.bin ] || { echo "[HATA] gps_i2c.bin yok"; exit 1; }

echo "[1/3] GPS web durduruluyor (UART cakismasi)..."
sudo_cmd systemctl stop neo-gps.service 2>/dev/null || true
sudo_cmd pkill -f gps_web.py 2>/dev/null || true
sleep 1

echo "[2/3] Combo bitstream..."
sudo_cmd cp gps_i2c.bin /lib/firmware/gps_i2c.bin
echo gps_i2c.bin | sudo_cmd tee /sys/class/fpga_manager/fpga0/firmware >/dev/null
sleep 2
echo "      FPGA: $(cat /sys/class/fpga_manager/fpga0/state)"

echo "[3/3] Sensor panel servisi..."
bash install_boot_service.sh

echo ""
echo "============================================"
echo " Sensor Panel hazir."
echo "  Tek calistirma: bash start.sh"
echo "  Otomatik acilis: systemctl status neo-sensor-panel"
echo "  GPS web icin: 9928.bat (bu servisi durdurur)"
echo "============================================"
