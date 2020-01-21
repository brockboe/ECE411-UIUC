`include "include/fifo_itf.sv"
`include "grader/grader.sv"
import fifo_types::*;

module top;

fifo_itf itf();

grader grd (.*);
testbench tb(.*);

endmodule : top

