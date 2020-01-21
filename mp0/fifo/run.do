transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work  {./include/types.sv}
vlog -sv -work work  {./include/fifo_itf.sv}
vlog -sv -work work  {./grader/grader.sv}
vlog -sv -work work  {./hdl/fifo.sv}
vlog -sv -work work  {./hvl/top.sv}
vlog -sv -work work  {./hvl/testbench.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixv_ver -L rtl_work -L work -voptargs="+acc"  top

view structure
view signals
run -all
