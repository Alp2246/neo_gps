@echo off
REM ============================================================
REM  KOD 9930 — Sensor Panel (OLED + BMP280 + MAX7219 + GPS)
REM  Ayri proje — GPS web (9928) ile ayni anda CALISMAZ
REM ============================================================
title Sensor Panel [9930]
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy_panel.ps1" %*
if errorlevel 1 pause
