import mult_types::*;

`include "include/multiplier_itf.sv"
`include "hvl/testbench.sv"


module top;
    multiplier_itf itf();
    grader grd (.*);
    testbench tb (.*);
endmodule : top
