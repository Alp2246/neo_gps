#!/bin/bash
# Sensor Panel — tek calistirma (GPS web ile ayni anda CALISMAZ)
set -e
cd "$(dirname "$0")"

# GPS web servisi UART'i kullanir — durdur
if systemctl is-active neo-gps.service >/dev/null 2>&1; then
    echo "[INFO] neo-gps.service durduruluyor..."
    echo xilinx | sudo -S systemctl stop neo-gps.service 2>/dev/null || sudo systemctl stop neo-gps.service
fi
sudo pkill -f 'gps_web.py' 2>/dev/null || true
sudo pkill -f 'neo_gps_pynq.py' 2>/dev/null || true
sleep 1
sudo rm -f /tmp/neo_gps_uart.lock

[ -f gps_i2c.bin ] || { echo "[HATA] gps_i2c.bin yok. PC'den 9930.bat calistir."; exit 1; }

echo "Sensor Panel — OLED + BMP280 + MAX7219 + GPS"
echo "Ctrl+C ile cik"
exec sudo python3 panel.py
