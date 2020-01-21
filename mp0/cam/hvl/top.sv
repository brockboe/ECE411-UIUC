`include "hvl/testbench.sv"
`include "include/cam_interface.sv"
`include "include/cam_itf.sv"

module top;

cam_itf itf();

testbench tb(.*);

grader gdr(.*);

endmodule : top
