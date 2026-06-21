@echo off
title HC-06 Bluetooth Deploy [9960]
cd /d "%~dp0"
echo.
echo  HC-06 kablolama:
echo    VCC=Pin1  GND=Pin6  TXD->Pin10  RXD->Pin8
echo  Telefon PIN: 1234
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1" -Web %*
pause
