#Requires -Version 5.1
<#
.SYNOPSIS
  PC'den PYNQ-Z2'ye GPS dosyalarini yukler, bitstream yukler, web panosunu baslatir.

.EXAMPLE
  .\deploy_gps.ps1
  .\deploy_gps.ps1 -BoardIp 192.168.2.99
  .\deploy_gps.ps1 -Foreground   # web on planda kalir (Ctrl+C)
#>
param(
    [string]$BoardIp = '192.168.2.99',
    [string]$User = 'xilinx',
    [string]$Pass = 'xilinx',
    [int]$HttpPort = 8000,
    [string]$PcIp = '',
    [switch]$Foreground,
    [switch]$SkipBrowser
)

$ErrorActionPreference = 'Stop'
$HostKey = 'ssh-ed25519 255 SHA256:6O+RCEzdICMQSbQzLhOpCPfVWtqyK2Z2jPA4GF0NyaY'
$Repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$RemoteDir = '/home/xilinx/neo_gps'

if (-not (Get-Command plink -ErrorAction SilentlyContinue)) {
    Write-Error @"
plink bulunamadi. PuTTY kurun ve PATH'e ekleyin:
  https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
"@
}

function Invoke-Board([string]$Command) {
    & plink -batch -ssh -hostkey $HostKey "${User}@${BoardIp}" -pw $Pass $Command
}

function Send-TextFile([string]$LocalPath, [string]$RemotePath) {
    $text = [IO.File]::ReadAllText($LocalPath).Replace("`r`n", "`n")
    $text | & plink -batch -ssh -hostkey $HostKey "${User}@${BoardIp}" -pw $Pass "cat > $RemotePath"
}

function Send-BinaryFile([string]$LocalPath, [string]$RemotePath) {
    $pscp = Get-Command pscp -ErrorAction SilentlyContinue
    if ($pscp) {
        & pscp -batch -scp -hostkey $HostKey -pw $Pass $LocalPath "${User}@${BoardIp}:$RemotePath"
        return
    }
    Write-Host 'pscp yok — base64 ile gonderiliyor (yavas)...' -ForegroundColor Yellow
    $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($LocalPath))
    Invoke-Board "python3 -c `"import base64,sys; open('$RemotePath','wb').write(base64.b64decode(sys.stdin.read()))`" <<'EOF64'
$b64
EOF64"
}

function Get-LocalIp {
    if ($PcIp) { return $PcIp }
    $subnet = ($BoardIp -split '\.')[0..1] -join '.'
    $match = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -like "$subnet.*" -and $_.PrefixOrigin -ne 'WellKnown' } |
        Select-Object -First 1
    if ($match) { return $match.IPAddress }
    $any = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -notlike '127.*' -and $_.PrefixOrigin -ne 'WellKnown' } |
        Select-Object -First 1
    if ($any) { return $any.IPAddress }
    return '192.168.2.10'
}

function Install-ViaHttp([string]$BaseUrl) {
    Send-TextFile (Join-Path $Repo 'install_on_board.sh') "$RemoteDir/install_on_board.sh"
    Invoke-Board "chmod +x $RemoteDir/install_on_board.sh && bash $RemoteDir/install_on_board.sh '$BaseUrl'"
}

function Install-ViaScp {
    Invoke-Board "mkdir -p $RemoteDir"
    foreach ($name in @('gps_web.py', 'neo_gps_pynq.py', 'start_web.sh', 'install_on_board.sh', 'install_boot_service.sh', 'neo-gps.service')) {
        Write-Host "  -> $name"
        Send-TextFile (Join-Path $Repo $name) "$RemoteDir/$name"
    }
    Write-Host '  -> gps_uart.bin (~4 MB)'
    Send-BinaryFile (Join-Path $Repo 'output/gps_uart.bin') "$RemoteDir/gps_uart.bin"
    Invoke-Board "chmod +x $RemoteDir/install_on_board.sh $RemoteDir/install_boot_service.sh $RemoteDir/start_web.sh && SUDO_PASS=$Pass INSTALL_BOOT=1 bash $RemoteDir/install_on_board.sh"
}

Write-Host '=== PYNQ GPS deploy ===' -ForegroundColor Cyan
Write-Host "Repo : $Repo"
Write-Host "Kart : ${User}@${BoardIp}"

foreach ($f in @('gps_web.py', 'neo_gps_pynq.py', 'start_web.sh', 'install_on_board.sh', 'install_boot_service.sh', 'neo-gps.service', 'output/gps_uart.bin')) {
    if (-not (Test-Path (Join-Path $Repo $f))) {
        Write-Error "Eksik dosya: $f"
    }
}

Write-Host 'SSH bekleniyor...'
for ($i = 1; $i -le 30; $i++) {
    if ((Test-NetConnection $BoardIp -Port 22 -WarningAction SilentlyContinue).TcpTestSucceeded) { break }
    Start-Sleep -Seconds 2
    if ($i -eq 30) { Write-Error "Kart yanit vermiyor ($BoardIp:22)" }
}

$httpJob = $null
try {
    Write-Host 'Dosyalar karta yukleniyor (SCP/SSH)...'
    Install-ViaScp
}
catch {
    Write-Host "SCP basarisiz, HTTP fallback deneniyor: $_" -ForegroundColor Yellow
    $localIp = Get-LocalIp
    $baseUrl = "http://${localIp}:${HttpPort}"
    $httpJob = Start-Job -ScriptBlock {
        param($Root, $Port)
        Set-Location $Root
        python -m http.server $Port 2>$null
    } -ArgumentList $Repo, $HttpPort
    Start-Sleep -Seconds 2
    Install-ViaHttp $baseUrl
}

try {
    Write-Host 'Canli veri kontrolu...'
    $probe = Invoke-Board "curl -s --connect-timeout 5 http://127.0.0.1:8080/data 2>/dev/null | head -c 280"
    $svc = Invoke-Board "echo $Pass | sudo -S systemctl is-active neo-gps 2>/dev/null || echo inactive"
    Write-Host $probe
    Write-Host "neo-gps.service: $svc"

    $url = "http://${BoardIp}:8080"
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host " Hazir: $url" -ForegroundColor Green
    Write-Host " Acilista otomatik baslar (neo-gps.service)" -ForegroundColor Green
    Write-Host " PC guncelleme: 9928.bat" -ForegroundColor Green
    Write-Host " Pano + NMEA: $url" -ForegroundColor Green
    Write-Host " API JSON  : $url/data" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green

    if (-not $SkipBrowser) {
        Start-Process $url
    }

    if ($Foreground) {
        Write-Host 'Web on planda — Ctrl+C ile cikis...'
        Invoke-Board "cd $RemoteDir && sudo pkill -f gps_web.py 2>/dev/null; sleep 1; exec sudo python3 gps_web.py"
    }
}
finally {
    if ($httpJob) {
        Stop-Job $httpJob -ErrorAction SilentlyContinue | Out-Null
        Remove-Job $httpJob -Force -ErrorAction SilentlyContinue | Out-Null
    }
}
