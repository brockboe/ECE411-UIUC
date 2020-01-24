import mult_types::*;

`ifndef testbench
`define testbench
module testbench(multiplier_itf.testbench itf);

add_shift_multiplier dut (
    .clk_i          ( itf.clk          ),
    .reset_n_i      ( itf.reset_n      ),
    .multiplicand_i ( itf.multiplicand ),
    .multiplier_i   ( itf.multiplier   ),
    .start_i        ( itf.start        ),
    .ready_o        ( itf.rdy          ),
    .product_o      ( itf.product      ),
    .done_o         ( itf.done         )
);

assign itf.mult_op = dut.ms.op;
default clocking tb_clk @(negedge itf.clk); endclocking

// DO NOT MODIFY CODE ABOVE THIS LINE

/* Uncomment to "monitor" changes to adder operational state over time */
//initial $monitor("dut-op: time: %0t op: %s", $time, dut.ms.op.name);


// Resets the multiplier
task reset();
    itf.reset_n <= 1'b0;
    ##5;
    itf.reset_n <= 1'b1;
    ##1;
endtask : reset

logic [16:0] mult_operands;
logic [15:0] mult_result_check;
assign itf.multiplicand  = mult_operands[15:8];
assign itf.multiplier    = mult_operands[7:0];
assign mult_result_check = itf.multiplicand * itf.multiplier;

// iterates through and checks that the output
// from the multiplier is correct.
task check_quotient();
      //set the start signal synchronously
      @(tb_clk);
      itf.start <= 1'b1;

      // wait until multiplier has finished
      // and check the result
      @(posedge itf.done);
      assert (itf.product == mult_result_check)
      else begin
            $error ("%0d: %0t: BAD_PRODUCT error detected", `__LINE__, $time);
            report_error (BAD_PRODUCT);
      end
      assert (itf.rdy == 1'b1)
      else begin
            $error ("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
            report_error (NOT_READY);
      end
      // update the multiplier and multiplicand
      mult_operands <= mult_operands + 16'd1;
      itf.start <= 1'b0;
      //some display blocks for peace-of-mind
      //$display ("Operation: %d x %d", itf.multiplicand, itf.multiplier);
      //$display ("Correct Result: %d", mult_result_check);
      //$display ("Multiplier output: %d", itf.product);
      //$display ("    ");

      //perform a reset, used to check the
      //second test case
      @(tb_clk);
      itf.reset_n <= 1'b0;
      @(tb_clk);
      itf.reset_n <= 1'b1;
endtask : check_quotient


// Check that the reset signal works when performed in the middle
// of a running state
task check_reset();
      @(tb_clk);
      itf.start <= 1'b1;
      @(tb_clk);
      itf.start <= 1'b0;

      repeat (4) begin
            @(tb_clk);
      end

      itf.reset_n <= 1'b0;
      @(tb_clk);
      itf.reset_n <= 1'b1;
endtask : check_reset


// Every time the reset signal is set
// ensure that the ready signal updates
// itself accordingly
always @ (negedge itf.reset_n) begin
      //$display("Reset signal pulled low!");
      @(posedge itf.reset_n);
      assert (itf.rdy == 1'b1)
      else begin
            $error("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
            report_error (NOT_READY);
      end
end


// error_e defined in package mult_types in file ../include/types.sv
// Asynchronously reports error in DUT to grading harness
function void report_error(error_e error);
    itf.tb_report_dut_error(error);
endfunction : report_error


initial itf.reset_n = 1'b0;
initial begin
    reset();
    /********************** Your Code Here *****************************/
    mult_operands = 17'd0;

    // iterate through all possible operands
    while (mult_operands < 17'h10000) begin
      check_quotient();
    end

    check_reset();

    /*******************************************************************/
    itf.finish(); // Use this finish task in order to let grading harness
                  // complete in process and/or scheduled operations
    $error("Improper Simulation Exit");
end


endmodule : testbench
`endif
