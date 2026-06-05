# MAX7219 8x8 LED — PYNQ-Z2 AXI GPIO (3-bit output)
#
#   bit0 DIN -> RPi Pin 11 (U7)
#   bit1 CLK -> RPi Pin 13 (W9)
#   bit2 CS  -> RPi Pin 15 (Y9)
#
# VCC -> 3.3V Pin 1, GND -> Pin 6

set_property -dict {PACKAGE_PIN U7  IOSTANDARD LVCMOS33} [get_ports {gpio_rtl_io[0]}]
set_property -dict {PACKAGE_PIN W9  IOSTANDARD LVCMOS33} [get_ports {gpio_rtl_io[1]}]
set_property -dict {PACKAGE_PIN Y9  IOSTANDARD LVCMOS33} [get_ports {gpio_rtl_io[2]}]
