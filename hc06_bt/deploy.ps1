#Requires -Version 5.1
param(
    [string]$BoardIp = '192.168.2.99',
    [string]$User = 'xilinx',
    [string]$Pass = 'xilinx',
    [int]$Retries = 20,
    [switch]$Web
)

$ErrorActionPreference = 'Stop'
$HostKey = ''  # PuTTY onbellek — SD yenilenince plink ile bir kez baglan

function Invoke-Plink([string]$Cmd) {
    if ($HostKey) {
        & plink -batch -ssh -hostkey $HostKey "${User}@${BoardIp}" -pw $Pass $Cmd
    } else {
        & plink -batch -ssh "${User}@${BoardIp}" -pw $Pass $Cmd
    }
}

function Invoke-Pscp([string]$Local, [string]$Remote) {
    if ($HostKey) {
        & pscp -batch -scp -hostkey $HostKey -pw $Pass $Local "${User}@${BoardIp}:$Remote"
    } else {
        & pscp -batch -scp -pw $Pass $Local "${User}@${BoardIp}:$Remote"
    }
}
$Repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$Parent = Split-Path -Parent $Repo
$Remote = '/home/xilinx/hc06_bt'

function Send-Text($local, $remote) {
    $plinkArgs = @('-batch', '-ssh', "${User}@${BoardIp}", '-pw', $Pass, "cat > $remote")
    if ($HostKey) { $plinkArgs = @('-batch', '-ssh', '-hostkey', $HostKey) + $plinkArgs[2..($plinkArgs.Length-1)] }
    [IO.File]::ReadAllText($local).Replace("`r`n", "`n") | & plink @plinkArgs
    if ($LASTEXITCODE -ne 0) { throw "Yukleme: $remote" }
}

Write-Host '=== 9960 HC-06 Bluetooth deploy ===' -ForegroundColor Cyan

$bin = Join-Path $Parent 'output/gps_uart.bin'
if (-not (Test-Path $bin)) { throw "gps_uart.bin yok: $bin" }

$ok = $false
for ($i = 1; $i -le $Retries; $i++) {
    $out = Invoke-Plink "echo OK" 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0 -and $out -match 'OK') { $ok = $true; break }
    Start-Sleep -Seconds 2
}
if (-not $ok) { throw "Kart erisilemiyor: $BoardIp" }

Invoke-Plink "mkdir -p $Remote"
foreach ($f in @('bt_bridge.py', 'bt_web.py', 'quick_test.py', 'install_on_board.sh', 'start.sh', 'README.md')) {
    Write-Host "  -> $f"
    Send-Text (Join-Path $Repo $f) "$Remote/$f"
}
Write-Host '  -> neo_gps_pynq.py (UART surucu)'
Send-Text (Join-Path $Parent 'neo_gps_pynq.py') "$Remote/../neo_gps_pynq.py"
Send-Text (Join-Path $Parent 'neo_gps_pynq.py') "$Remote/neo_gps_pynq.py"

Write-Host '  -> gps_uart.bin'
Invoke-Pscp $bin "$Remote/gps_uart.bin"

$cmd = "sed -i 's/\r`$//' $Remote/*.sh $Remote/*.py 2>/dev/null; echo '$Pass' | sudo -S systemctl stop neo-gps.service max7219-led.service 2>/dev/null || true; chmod +x $Remote/*.sh $Remote/*.py; SUDO_PASS=$Pass bash $Remote/install_on_board.sh"
Invoke-Plink $cmd

if ($Web) {
    Invoke-Plink "echo $Pass | sudo -S fuser -k 8082/tcp 2>/dev/null; cd $Remote && nohup sudo python3 bt_web.py --skip-overlay --port 8082 > bt_web.log 2>&1 &"
    Write-Host "Web: http://${BoardIp}:8082" -ForegroundColor Green
}

Write-Host '=== HC-06 hazir (9960) ===' -ForegroundColor Green
