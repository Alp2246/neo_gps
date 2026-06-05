#Requires -Version 5.1
param(
    [string]$BoardIp = '192.168.2.99',
    [string]$User = 'xilinx',
    [string]$Pass = 'xilinx'
)

$ErrorActionPreference = 'Stop'
$HostKey = 'ssh-ed25519 255 SHA256:6O+RCEzdICMQSbQzLhOpCPfVWtqyK2Z2jPA4GF0NyaY'
$Repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$Remote = '/home/xilinx/max7219_led'

function Assert-Ok($c, $msg) { if ($c -ne 0) { Write-Error $msg } }

function Send-Text($local, $remote) {
    [IO.File]::ReadAllText($local).Replace("`r`n", "`n") |
        & plink -batch -ssh -hostkey $HostKey "${User}@${BoardIp}" -pw $Pass "cat > $remote"
    Assert-Ok $LASTEXITCODE "Yukleme: $remote"
}

Write-Host '=== MAX7219 LED deploy (9940) ===' -ForegroundColor Cyan
$bin = Join-Path $Repo 'output/max7219_led.bin'
if (-not (Test-Path $bin)) { $bin = Join-Path $Repo 'max7219_led.bin' }
if (-not (Test-Path $bin)) {
    Write-Error "max7219_led.bin yok. Once: max7219_led\vivado\run_build.bat"
}

for ($i = 1; $i -le 30; $i++) {
    if ((Test-NetConnection $BoardIp -Port 22 -WarningAction SilentlyContinue).TcpTestSucceeded) { break }
    Start-Sleep -Seconds 2
    if ($i -eq 30) { Write-Error "Kart yanit vermiyor" }
}

& plink -batch -ssh -hostkey $HostKey "${User}@${BoardIp}" -pw $Pass "mkdir -p $Remote"
foreach ($f in @('display.py', 'max7219.py', 'overlay.py', 'start.sh', 'install_on_board.sh', 'install_boot_service.sh', 'max7219-led.service')) {
    Write-Host "  -> $f"
    Send-Text (Join-Path $Repo $f) "$Remote/$f"
}
Write-Host '  -> max7219_led.bin'
& pscp -batch -scp -hostkey $HostKey -pw $Pass $bin "${User}@${BoardIp}:$Remote/max7219_led.bin"
Assert-Ok $LASTEXITCODE 'bin yukleme'

& plink -batch -ssh -hostkey $HostKey "${User}@${BoardIp}" -pw $Pass "chmod +x $Remote/*.sh $Remote/display.py && SUDO_PASS=$Pass bash $Remote/install_on_board.sh"
Assert-Ok $LASTEXITCODE 'kurulum'

Write-Host 'Hazir — LED demo calisiyor (9940)' -ForegroundColor Green
