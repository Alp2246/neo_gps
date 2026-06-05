@echo off
REM KOD 9940 — Sadece MAX7219 8x8 LED (ayri proje)
title MAX7219 LED [9940]
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1" %*
if errorlevel 1 pause
