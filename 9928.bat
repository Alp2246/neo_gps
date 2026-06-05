@echo off
REM ============================================================
REM  KOD 9928 — PYNQ-Z2 GPS deploy (SD kart guncellemeden)
REM  Dosyalari karta yukler + acilista otomatik baslatmayi kurar
REM  Tarayici: http://192.168.2.99:8080
REM ============================================================
title PYNQ GPS [9928]
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy_gps.ps1" %*
if errorlevel 1 (
    echo.
    echo [HATA] Deploy basarisiz. Kart acik mi? PuTTY plink kurulu mu?
    pause
)
