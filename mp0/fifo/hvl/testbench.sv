`ifndef testbench
`define testbench

import fifo_types::*;

module testbench(fifo_itf itf);

fifo_synch_1r1w dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),

    // valid-ready enqueue protocol
    .data_i    ( itf.data_i  ),
    .valid_i   ( itf.valid_i ),
    .ready_o   ( itf.rdy     ),

    // valid-yumi deqeueue protocol
    .valid_o   ( itf.valid_o ),
    .data_o    ( itf.data_o  ),
    .yumi_i    ( itf.yumi    )
);

// Clock Synchronizer for Student Use
default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    ##(10);
    itf.reset_n <= 1'b1;
    ##(1);
endtask : reset

function automatic void report_error(error_e err);
    itf.tb_report_dut_error(err);
endfunction : report_error

// DO NOT MODIFY CODE ABOVE THIS LINE


// enqueue numbers 0 through 255 onto the
// queue
task enqueue();
      @(tb_clk);
      itf.valid_i <= 1'b1;
      itf.data_i <= 8'd0;
      for(int i = 0; i < 256; ++i) begin
            //$display("enqueing %d", itf.data_i);
            @(tb_clk);
            itf.data_i <= itf.data_i + 8'd1;
      end
      itf.valid_i <= 1'b0;
endtask : enqueue


task test_reset();
      @(tb_clk);
      itf.valid_i <= 1'b1;
      itf.data_i <= 8'd0;
      itf.yumi <= 1'b0;

      ##(10);

      @(tb_clk);
      itf.reset_n <= 1'b0;
      @(posedge itf.clk);
      assert(itf.rdy == 1'b1)
      else begin
            $error("%0d: %0t: RESET_DOES_NOT_CAUSE_READY_O error detected", `__LINE__, $time);
            report_error(RESET_DOES_NOT_CAUSE_READY_O);
      end
      itf.valid_i <= 1'b0;
endtask : test_reset

// dequeue all the numbers on the FIFO queue
// and also test that the output is correct.
// This assumes that the enqueue function
// above has been called first
logic [7:0] old_val;
task dequeue();
      @(tb_clk);
      itf.yumi <= 1'b1;

      for(int i = 0; i < 256; ++i) begin
            if (i > 0) begin
                  // ensure that the data coming out of the
                  // queue is increasing linearly by one
                  // for each element
                  assert(itf.data_o == (old_val + 8'd1))
                  else begin
                        $error("%0d: %0t: INCORRECT_DATA_O_ON_YUMI_I error detected", `__LINE__, $time);
                        report_error(INCORRECT_DATA_O_ON_YUMI_I);
                  end
            end else begin
                  // check the very first element of the fifo queue
                  assert(itf.data_o == 8'd0)
                  else begin
                        $error("%0d: %0t: INCORRECT_DATA_O_ON_YUMI_I error detected", `__LINE__, $time);
                        report_error(INCORRECT_DATA_O_ON_YUMI_I);
                  end
            end

            old_val <= itf.data_o;
            //$display("dequeue output: %d", itf.data_o);
            @(tb_clk);
      end
endtask : dequeue


// dequeue and enqueue at the same time, as the final
// coverage requirement
task simultaneous();

      for(int i = 0; i < 256; ++i) begin
            @(tb_clk);
            itf.valid_i <= 1'b1;
            itf.yumi <= 1'b0;
            //$display("simultaneous data_o: %d", itf.data_o);
            itf.data_i <= itf.data_i + 8'd1;

            @(tb_clk);
            itf.yumi <= 1'b1;
            itf.data_i <= itf.data_i + 8'd1;
      end

      @(tb_clk);
      itf.yumi <= 1'b0;
      itf.valid_i <= 1'b0;
endtask : simultaneous



initial begin
      itf.valid_i       <= 1'b0;
      itf.yumi        <= 1'b0;
      itf.reset_n       <= 1'b1;
      itf.data_i        <= 8'b0;

      reset();
      /************************ Your Code Here ***********************/
      // Feel free to make helper tasks / functions, initial / always blocks, etc.

      // enqueue all the elements
      enqueue();
      //$display(" ");
      // dequeue all the elements
      dequeue();

      simultaneous();

      test_reset();

      /***************************************************************/
      // Make sure your test bench exits by calling itf.finish();
      itf.finish();
      $error("TB: Illegal Exit ocurred");
end

endmodule : testbench
`endif
