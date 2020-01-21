transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work  {./include/cam_types.sv}
vlog -sv -work work  {./include/cam_interface.sv}
vlog -sv -work work  {./include/cam_itf.sv}
vlog -sv -work work  {./grader/grader.sv}
vlog -sv -work work  {./hdl/cam_datapath.sv}
vlog -sv -work work  {./hdl/cam_controller.sv}
vlog -sv -work work  {./hdl/cam.sv}
vlog -sv -work work  {./hvl/top.sv}
vlog -sv -work work  {./hvl/testbench.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixiv_hssi_ver -L stratixiv_pcie_hip_ver -L stratixiv_ver -L rtl_work -L work -voptargs="+acc"  top

run -all
