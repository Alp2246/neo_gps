@echo off
title MPU6050 Deploy [9950]
cd /d "%~dp0"
echo.
echo  Kart: 192.168.2.99  (Jupyter acik olmali)
echo  Bitstream: ..\output\i2c_gpio.bin
echo  Kablolama: VCC=1 GND=6 SDA=3 SCL=5
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1" %*
if errorlevel 1 pause
exit /b %errorlevel%
