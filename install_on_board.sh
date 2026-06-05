#!/bin/bash
# PYNQ kartinda kurulum — PC'den SCP veya wget
# PC: 9928.bat veya deploy_gps.bat (SD kart guncellemeden)
set -e

DIR="${GPS_DIR:-/home/xilinx/neo_gps}"
PC="${1:-}"
INSTALL_BOOT="${INSTALL_BOOT:-1}"
SUDO_PASS="${SUDO_PASS:-xilinx}"

sudo_cmd() {
    if sudo -n true 2>/dev/null; then
        sudo "$@"
    else
        echo "$SUDO_PASS" | sudo -S "$@"
    fi
}

mkdir -p "$DIR"
cd "$DIR"

if [ -n "$PC" ]; then
    PC="${PC%/}"
    echo "[1/5] PC'den indiriliyor ($PC)..."
    wget -q "$PC/gps_web.py" -O gps_web.py
    wget -q "$PC/neo_gps_pynq.py" -O neo_gps_pynq.py
    wget -q "$PC/start_web.sh" -O start_web.sh
    wget -q "$PC/neo-gps.service" -O neo-gps.service
    wget -q "$PC/install_boot_service.sh" -O install_boot_service.sh
    wget -q "$PC/output/gps_uart.bin" -O gps_uart.bin
    wget -q "$PC/output/gps_uart.hwh" -O gps_uart.hwh 2>/dev/null || true
else
    echo "[1/5] Yerel dosyalar..."
    if [ -f output/gps_uart.bin ] && [ ! -f gps_uart.bin ]; then
        cp output/gps_uart.bin gps_uart.bin
    fi
    for f in gps_web.py neo_gps_pynq.py start_web.sh neo-gps.service install_boot_service.sh; do
        [ -f "$f" ] || { echo "[HATA] $f yok. PC'den 9928.bat calistirin."; exit 1; }
    done
fi

echo "[2/5] CRLF duzelt..."
for f in "$0" start_web.sh install_boot_service.sh neo-gps.service install_on_board.sh; do
    sed -i 's/\r$//' "$f" 2>/dev/null || true
done
chmod +x start_web.sh install_boot_service.sh

echo "[3/5] FPGA bitstream..."
sudo_cmd cp gps_uart.bin /lib/firmware/gps_uart.bin
echo gps_uart.bin | sudo_cmd tee /sys/class/fpga_manager/fpga0/firmware > /dev/null
sleep 2
STATE=$(cat /sys/class/fpga_manager/fpga0/state)
echo "      FPGA state: $STATE"
[ "$STATE" = "operating" ] || { echo "[HATA] FPGA operating degil"; exit 1; }

if [ "$INSTALL_BOOT" = "1" ]; then
    echo "[4/5] systemd — kart acilinca otomatik baslat..."
    bash install_boot_service.sh
    echo "[5/5] Servis hazir."
else
    echo "[4/5] Web panosu (tek seferlik)..."
    sudo_cmd pkill -f 'gps_web.py' 2>/dev/null || true
    sudo_cmd pkill -f 'neo_gps_pynq.py' 2>/dev/null || true
    sleep 1
    sudo_cmd rm -f /tmp/neo_gps_uart.lock
    BACKGROUND=1 bash start_web.sh
    echo "[5/5] Arka planda calisiyor."
fi

IP=$(hostname -I 2>/dev/null | awk '{print $1}')
echo ""
echo "============================================"
echo " Kurulum tamam."
echo "  http://${IP:-192.168.2.99}:8080"
echo "  Log: $DIR/gps_web.log"
if [ "$INSTALL_BOOT" = "1" ]; then
    echo "  Acilista otomatik: systemctl status neo-gps"
fi
echo "  PC guncelleme: 9928.bat (SD kart dokunma)"
echo "============================================"
