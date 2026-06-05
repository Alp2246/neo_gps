@echo off
REM PC'den PYNQ-Z2'ye tek tikla yukle + calistir
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy_gps.ps1" %*
if errorlevel 1 pause
