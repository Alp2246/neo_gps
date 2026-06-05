#!/bin/bash
# PYNQ kartinda kurulum — PC'den wget veya git clone
# Ornek (PC'de once: python -m http.server 8000):
#   bash install_on_board.sh http://192.168.2.10:8000
# Ornek (internetsiz, git clone sonrasi):
#   bash install_on_board.sh
set -e

DIR="${GPS_DIR:-/home/xilinx/neo_gps}"
PC="${1:-}"

mkdir -p "$DIR"
cd "$DIR"

if [ -n "$PC" ]; then
    PC="${PC%/}"
    echo "[1/4] PC'den indiriliyor ($PC)..."
    wget -q "$PC/gps_web.py" -O gps_web.py
    wget -q "$PC/neo_gps_pynq.py" -O neo_gps_pynq.py
    wget -q "$PC/start_web.sh" -O start_web.sh
    wget -q "$PC/output/gps_uart.bin" -O gps_uart.bin
    wget -q "$PC/output/gps_uart.hwh" -O gps_uart.hwh 2>/dev/null || true
else
    echo "[1/4] Yerel dosyalar (git clone)..."
    if [ -f output/gps_uart.bin ] && [ ! -f gps_uart.bin ]; then
        cp output/gps_uart.bin gps_uart.bin
    fi
    for f in gps_web.py neo_gps_pynq.py start_web.sh; do
        [ -f "$f" ] || { echo "[HATA] $f yok. Once repoyu klonlayin veya PC URL verin."; exit 1; }
    done
fi

echo "[2/4] Satir sonlari (CRLF) duzeltiliyor..."
sed -i 's/\r$//' start_web.sh 2>/dev/null || true
chmod +x start_web.sh

echo "[3/4] FPGA bitstream yukleniyor..."
sudo cp gps_uart.bin /lib/firmware/gps_uart.bin
echo gps_uart.bin | sudo tee /sys/class/fpga_manager/fpga0/firmware > /dev/null
sleep 2
STATE=$(cat /sys/class/fpga_manager/fpga0/state)
echo "      FPGA state: $STATE"
[ "$STATE" = "operating" ] || { echo "[HATA] FPGA operating degil"; exit 1; }

echo "[4/4] Web panosu baslatiliyor..."
sudo pkill -f 'gps_web.py' 2>/dev/null || true
sudo pkill -f 'neo_gps_pynq.py' 2>/dev/null || true
sleep 1
sudo rm -f /tmp/neo_gps_uart.lock
BACKGROUND=1 bash start_web.sh

IP=$(hostname -I 2>/dev/null | awk '{print $1}')
echo ""
echo "============================================"
echo " Kurulum tamam."
echo "  http://${IP:-192.168.2.99}:8080"
echo "  Log: $DIR/gps_web.log"
echo "  Durdurmak: sudo pkill -f gps_web.py"
echo "============================================"
