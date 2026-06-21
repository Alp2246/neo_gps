#!/bin/bash
cd "$(dirname "$0")"
exec sudo python3 mpu6050.py --axi-gpio
