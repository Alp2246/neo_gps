#!/bin/bash
set -e
DIR="${LED_DIR:-/home/xilinx/max7219_led}"
SVC=/etc/systemd/system/max7219-led.service
SUDO_PASS="${SUDO_PASS:-xilinx}"

sudo_cmd() {
    if sudo -n true 2>/dev/null; then sudo "$@"
    else echo "$SUDO_PASS" | sudo -S "$@"; fi
}

sudo_cmd cp "$DIR/max7219-led.service" "$SVC"
sudo_cmd systemctl daemon-reload
sudo_cmd systemctl enable max7219-led.service
sudo_cmd systemctl restart max7219-led.service
sleep 2
sudo_cmd systemctl is-active max7219-led.service
