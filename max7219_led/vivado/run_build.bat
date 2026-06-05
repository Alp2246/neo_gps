@echo off
set VIVADO=C:\Xilinx\Vivado\2022.2\bin\vivado.bat
if not exist "%VIVADO%" ( echo Vivado yok: %VIVADO% & pause & exit /b 1 )
cd /d "%~dp0"
call "%VIVADO%" -mode batch -source build_max7219.tcl -notrace
pause
