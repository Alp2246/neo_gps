#!/bin/bash
# Web panosu — on planda veya arka planda (BACKGROUND=1)
cd "$(dirname "$0")"
sudo pkill -f 'gps_web.py' 2>/dev/null
sudo pkill -f 'neo_gps_pynq.py' 2>/dev/null
sleep 1
sudo rm -f /tmp/neo_gps_uart.lock

IP=$(hostname -I 2>/dev/null | awk '{print $1}')
echo "Tarayici: http://${IP:-192.168.2.99}:8080"

if [ -n "$BACKGROUND" ]; then
    nohup sudo python3 gps_web.py > gps_web.log 2>&1 &
    echo "Arka planda basladi (PID $!, log: gps_web.log)"
    exit 0
fi

echo "Durdurmak: Ctrl+C"
exec sudo python3 gps_web.py