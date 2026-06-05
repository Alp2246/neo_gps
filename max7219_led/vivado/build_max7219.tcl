# PYNQ-Z2 MAX7219 8x8 LED — AXI GPIO 3-bit output overlay

set origin_dir [file normalize [file dirname [info script]]]
set proj_root  [file normalize [file join $origin_dir ..]]
set repo_root  [file normalize [file join $origin_dir .. ..]]
set proj_name  max7219_led
set proj_dir   [file join $origin_dir build $proj_name]
set out_dir    [file join $proj_root output]
set preset_tcl [file join $repo_root "pynq-z2_v1.0.xdc" "PYNQ-Z2 v1.0.tcl"]
set xdc_file   [file join $origin_dir rpi_max7219.xdc]
set board_repo [file join $repo_root pynq-z2]

file mkdir $out_dir
file mkdir [file join $origin_dir build]

create_project $proj_name $proj_dir -part xc7z020clg400-1 -force
set_property target_language Verilog [current_project]

if {[file exists [file join $board_repo pynq-z2 A.0 board.xml]]} {
  set_param board.repoPaths [list $board_repo]
  catch { set_property board_part tul.com.tw:pynq-z2:part0:1.0 [current_project] }
}

set design_name design_1
create_bd_design $design_name
current_bd_design $design_name

set ps7 [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0]

if {[get_property board_part [current_project]] ne ""} {
  apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" apply_board_preset "1"} $ps7
} elseif {[file exists $preset_tcl]} {
  source $preset_tcl
  set_property -dict [apply_preset $ps7] $ps7
  apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR"} $ps7
} else {
  error "Zynq preset bulunamadi"
}

set_property -dict [list CONFIG.PCW_USE_M_AXI_GP0 {1} CONFIG.PCW_EN_CLK0_PORT {1} \
  CONFIG.PCW_EN_RST0_PORT {1} CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100}] $ps7

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0
set_property -dict [list CONFIG.C_GPIO_WIDTH {3} CONFIG.C_IS_DUAL {0} CONFIG.C_ALL_OUTPUTS {1}] [get_bd_cells axi_gpio_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property CONFIG.NUM_MI 1 [get_bd_cells axi_interconnect_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0

connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins axi_gpio_0/S_AXI]

connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
  [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins axi_interconnect_0/ACLK] \
  [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] \
  [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]

connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
  [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] \
  [get_bd_pins axi_gpio_0/s_axi_aresetn]

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 gpio_rtl
connect_bd_intf_net [get_bd_intf_ports gpio_rtl] [get_bd_intf_pins axi_gpio_0/GPIO]

assign_bd_address
set seg [get_bd_addr_segs -of_objects [get_bd_addr_spaces processing_system7_0/Data]]
catch {set_property offset 0x41200000 $seg}

regenerate_bd_layout
save_bd_design
validate_bd_design

make_wrapper -files [get_files ${design_name}.bd] -top -import
set_property top ${design_name}_wrapper [current_fileset]
add_files -fileset constrs_1 -norecurse $xdc_file

launch_runs synth_1 -jobs 4
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
open_run impl_1

set bit_dst [file join $out_dir max7219_led.bit]
file copy -force [file join $proj_dir max7219_led.runs impl_1 design_1_wrapper.bit] $bit_dst

set bif [file join $out_dir max7219_led.bif]
set bin [file join $out_dir max7219_led.bin]
set fp [open $bif w]
puts $fp "all:\n\{\n\t$bit_dst\n\}"
close $fp
catch {exec bootgen -image $bif -arch zynq -process_bitstream bin -o $bin -w}

set hwh [file join $proj_dir max7219_led.gen sources_1 bd design_1 hw_handoff design_1.hwh]
if {[file exists $hwh]} { file copy -force $hwh [file join $out_dir max7219_led.hwh] }

puts "OK -> $bin"
close_project
