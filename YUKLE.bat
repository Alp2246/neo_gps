@echo off
title PYNQ-Z2 Proje Yukleyici
cd /d "%~dp0"
echo.
echo  ============================================
echo   PYNQ-Z2 PROJE SEC
echo  ============================================
echo   1 = MAX7219 LED      (9940.bat)
echo   2 = MPU6050          (9950.bat)
echo   3 = MPU6050 + Web    (9950 -Web)
echo   4 = GPS              (9928.bat)
echo   5 = Sensor Panel     (9930.bat)
echo   6 = HC-06 Bluetooth  (9960.bat)
echo.
set /p CHOICE=Secim [1-6]: 
if "%CHOICE%"=="1" (cd max7219_led && call 9940.bat & goto end)
if "%CHOICE%"=="2" (cd mpu6050 && call 9950.bat & goto end)
if "%CHOICE%"=="3" (cd mpu6050 && powershell -File deploy.ps1 -Web & goto end)
if "%CHOICE%"=="4" (call 9928.bat & goto end)
if "%CHOICE%"=="5" (cd sensor_panel && call 9930.bat & goto end)
if "%CHOICE%"=="6" (cd hc06_bt && call 9960.bat & goto end)
echo Gecersiz secim.
:end
pause
