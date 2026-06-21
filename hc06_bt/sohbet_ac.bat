@echo off
chcp 65001 >nul
title PYNQ Sohbet Baslat
cd /d "%~dp0"
echo.
echo [1/2] Kartta sohbet sunucusu baslatiliyor...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1" -Web
echo.
echo [2/2] Yerel link: http://192.168.2.99:8082
echo.
echo Internet linki icin: internet.bat
echo.
pause
