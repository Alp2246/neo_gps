@echo off
chcp 65001 >nul
title PYNQ Sohbet - Internet Linki
setlocal
set "DIR=%~dp0"
set "CF=%DIR%cloudflared.exe"
set "BOARD=http://192.168.2.99:8082"

echo.
echo  ========================================
echo   PYNQ Sohbet - Internet linki olustur
echo  ========================================
echo.

if not exist "%CF%" (
    echo cloudflared indiriliyor...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe' -OutFile '%CF%'"
    if errorlevel 1 (
        echo HATA: cloudflared indirilemedi.
        pause
        exit /b 1
    )
)

echo Kart web: %BOARD%
echo.
echo  ONEMLI: Once 9960.bat -Web ile sohbet sayfasini acin
echo  veya kartta: sudo python3 bt_web.py --skip-overlay --port 8082
echo.
echo  Asagida https://....trycloudflare.com linki cikacak.
echo  Bu linki kiz arkadasinla paylas — dunyadan erisebilir.
echo.
echo  Pencereyi KAPATMA — link calisirken acik kalsin.
echo  ========================================
echo.

echo Link dosyaya yazilacak: %DIR%link.txt
echo.
"%CF%" tunnel --url %BOARD% 2>&1 | powershell -NoProfile -Command "$input | ForEach-Object { $_; if ($_ -match 'https://[a-z0-9-]+\.trycloudflare\.com') { $matches[0] | Set-Content -Path '%DIR%link.txt' -Encoding UTF8; Write-Host ''; Write-Host '>>> LINK KOPYALA:' $matches[0] -ForegroundColor Green; Write-Host '' } }"

pause
