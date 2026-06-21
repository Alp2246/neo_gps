#Requires -Version 5.1
param(
    [string]$BoardIp = '192.168.2.99',
    [string]$User = 'xilinx',
    [string]$Pass = 'xilinx',
    [int]$Retries = 30,
    [switch]$Web
)

$ErrorActionPreference = 'Stop'
$HostKey = 'ssh-ed25519 255 SHA256:TB0FfGjfMzgZUv/reJgTpeq/AM68sMCpGC5xm6Pit7o'
$Repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$Parent = Split-Path -Parent $Repo
$Remote = '/home/xilinx/mpu6050'
$Sensors = Join-Path $Parent 'sensors'

function Send-Text($local, $remote) {
    [IO.File]::ReadAllText($local).Replace("`r`n", "`n") |
        & plink -batch -ssh -hostkey $HostKey "${User}@${BoardIp}" -pw $Pass "cat > $remote"
    if ($LASTEXITCODE -ne 0) { throw "Yukleme hatasi: $remote" }
}

Write-Host '=== 9950 MPU6050 deploy ===' -ForegroundColor Cyan

$bin = Join-Path $Parent 'output/i2c_gpio.bin'
if (-not (Test-Path $bin)) { throw "Bitstream yok: $bin" }

$connected = $false
for ($i = 1; $i -le $Retries; $i++) {
    Write-Host "SSH $i/$Retries..."
    try {
        $out = & plink -batch -ssh -hostkey $HostKey "${User}@${BoardIp}" -pw $Pass "echo OK" 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0 -and ($out -match 'OK')) { $connected = $true; break }
    } catch { }
    Start-Sleep -Seconds 2
}
if (-not $connected) { throw "Kart erisilemiyor: $BoardIp — Jupyter acik mi? ping 192.168.2.99" }

& plink -batch -ssh -hostkey $HostKey "${User}@${BoardIp}" -pw $Pass "mkdir -p $Remote"
foreach ($f in @('install_on_board.sh', 'start.sh', 'mpu6050.ipynb')) {
    if (Test-Path (Join-Path $Repo $f)) {
        Write-Host "  -> $f"
        Send-Text (Join-Path $Repo $f) "$Remote/$f"
    }
}
foreach ($f in @('mpu6050.py', 'axi_gpio_i2c.py', 'mpu_web.py')) {
    Write-Host "  -> $f"
    Send-Text (Join-Path $Sensors $f) "$Remote/$f"
}

Write-Host '  -> i2c_gpio.bin'
& pscp -batch -scp -hostkey $HostKey -pw $Pass $bin "${User}@${BoardIp}:$Remote/i2c_gpio.bin"
if ($LASTEXITCODE -ne 0) { throw 'Bitstream yukleme basarisiz' }

$cmd = @"
sed -i 's/\r`$//' $Remote/*.sh $Remote/*.py 2>/dev/null || true
echo '$Pass' | sudo -S systemctl stop neo-gps.service max7219-led.service neo-sensor-panel.service 2>/dev/null || true
chmod +x $Remote/*.sh $Remote/*.py 2>/dev/null || true
SUDO_PASS=$Pass bash $Remote/install_on_board.sh
"@
& plink -batch -ssh -hostkey $HostKey "${User}@${BoardIp}" -pw $Pass $cmd
if ($LASTEXITCODE -ne 0) { throw 'Kurulum basarisiz' }

if ($Web) {
    Write-Host 'Web panosu baslatiliyor (8081)...' -ForegroundColor Yellow
    & plink -batch -ssh -hostkey $HostKey "${User}@${BoardIp}" -pw $Pass "cd $Remote && echo $Pass | sudo -S fuser -k 8081/tcp 2>/dev/null; nohup sudo python3 mpu_web.py --port 8081 > mpu_web.log 2>&1 &"
    Write-Host "http://${BoardIp}:8081"
}

Write-Host '=== MPU6050 hazir (9950) ===' -ForegroundColor Green
Write-Host "Test: ssh $User@$BoardIp -> cd $Remote && sudo python3 mpu6050.py --axi-gpio"
