#Requires -Version 5.1
param(
    [string]$BoardIp = '192.168.2.99',
    [string]$User = 'xilinx',
    [string]$Pass = 'xilinx',
    [switch]$Foreground,
    [switch]$SkipBrowser,
    [switch]$NoBootService
)

$ErrorActionPreference = 'Stop'
$HostKey = 'ssh-ed25519 255 SHA256:6O+RCEzdICMQSbQzLhOpCPfVWtqyK2Z2jPA4GF0NyaY'
$Repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$Parent = Split-Path -Parent $Repo
$RemoteDir = '/home/xilinx/sensor_panel'

if (-not (Get-Command plink -ErrorAction SilentlyContinue)) {
    Write-Error 'plink bulunamadi (PuTTY kur).'
}

function Invoke-Board([string]$Command) {
    & plink -batch -ssh -hostkey $HostKey "${User}@${BoardIp}" -pw $Pass $Command
}

function Send-TextFile([string]$LocalPath, [string]$RemotePath) {
    [IO.File]::ReadAllText($LocalPath).Replace("`r`n", "`n") |
        & plink -batch -ssh -hostkey $HostKey "${User}@${BoardIp}" -pw $Pass "cat > $RemotePath"
}

function Send-BinaryFile([string]$LocalPath, [string]$RemotePath) {
    if (Get-Command pscp -ErrorAction SilentlyContinue) {
        & pscp -batch -scp -hostkey $HostKey -pw $Pass $LocalPath "${User}@${BoardIp}:$RemotePath"
    } else {
        Write-Error 'pscp gerekli (PuTTY ile gelir).'
    }
}

Write-Host '=== Sensor Panel deploy (9930) ===' -ForegroundColor Cyan
Write-Host "Kart: ${User}@${BoardIp}"

$bin = Join-Path $Parent 'output/gps_i2c.bin'
if (-not (Test-Path $bin)) { Write-Error "gps_i2c.bin yok: $bin" }

Invoke-Board "mkdir -p $RemoteDir/drivers"

$textFiles = @(
    'panel.py', 'overlay.py', 'start.sh',
    'install_on_board.sh', 'install_boot_service.sh', 'neo-sensor-panel.service'
)
foreach ($name in $textFiles) {
    Write-Host "  -> $name"
    Send-TextFile (Join-Path $Repo $name) "$RemoteDir/$name"
}
foreach ($name in @('axi_gpio_i2c.py', 'ssd1306.py', 'bmp280.py', 'max7219.py')) {
    Write-Host "  -> drivers/$name"
    Send-TextFile (Join-Path $Repo "drivers/$name") "$RemoteDir/drivers/$name"
}

Write-Host '  -> gps_i2c.bin (~4 MB)'
Send-BinaryFile $bin "$RemoteDir/gps_i2c.bin"

if ($NoBootService) {
    Invoke-Board "chmod +x $RemoteDir/start.sh && SUDO_PASS=$Pass bash -c 'cd $RemoteDir && bash start.sh'"
} else {
    Invoke-Board "chmod +x $RemoteDir/start.sh $RemoteDir/install_on_board.sh $RemoteDir/install_boot_service.sh && SUDO_PASS=$Pass bash $RemoteDir/install_on_board.sh"
}

Write-Host ''
Write-Host '============================================' -ForegroundColor Green
Write-Host ' Sensor Panel yuklendi.' -ForegroundColor Green
Write-Host ' Kartta: bash ~/sensor_panel/start.sh' -ForegroundColor Green
Write-Host ' NOT: GPS web (9928) ile ayni anda calismaz' -ForegroundColor Yellow
Write-Host '============================================' -ForegroundColor Green
