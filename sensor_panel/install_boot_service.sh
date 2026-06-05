#!/bin/bash
set -e
DIR="${PANEL_DIR:-/home/xilinx/sensor_panel}"
SVC=/etc/systemd/system/neo-sensor-panel.service
SUDO_PASS="${SUDO_PASS:-xilinx}"

sudo_cmd() {
    if sudo -n true 2>/dev/null; then sudo "$@"
    else echo "$SUDO_PASS" | sudo -S "$@"; fi
}

sudo_cmd cp "$DIR/neo-sensor-panel.service" "$SVC"
sudo_cmd systemctl daemon-reload
sudo_cmd systemctl enable neo-sensor-panel.service
sudo_cmd systemctl stop neo-sensor-panel.service 2>/dev/null || true
sudo_cmd systemctl start neo-sensor-panel.service
sleep 3
sudo_cmd systemctl is-active neo-sensor-panel.service
sudo_cmd systemctl is-enabled neo-sensor-panel.service
