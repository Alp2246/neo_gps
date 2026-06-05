#!/bin/bash
# systemd servisi kur — kart acilinca GPS web otomatik baslar
set -e
DIR="${GPS_DIR:-/home/xilinx/neo_gps}"
SVC=/etc/systemd/system/neo-gps.service
SUDO_PASS="${SUDO_PASS:-xilinx}"

sudo_cmd() {
    if sudo -n true 2>/dev/null; then
        sudo "$@"
    else
        echo "$SUDO_PASS" | sudo -S "$@"
    fi
}

[ -f "$DIR/neo-gps.service" ] || { echo "[HATA] $DIR/neo-gps.service yok"; exit 1; }

echo "[boot] systemd neo-gps kuruluyor..."
sudo_cmd cp "$DIR/neo-gps.service" "$SVC"
sudo_cmd systemctl daemon-reload
sudo_cmd systemctl enable neo-gps.service
sudo_cmd systemctl stop neo-gps.service 2>/dev/null || true
sleep 1
sudo_cmd systemctl start neo-gps.service
sleep 3
echo "[boot] Durum:"
sudo_cmd systemctl is-active neo-gps.service
sudo_cmd systemctl is-enabled neo-gps.service
