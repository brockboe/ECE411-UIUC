import cam_types::*;

module testbench(cam_itf itf);

cam dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),
    .rw_n_i    ( itf.rw_n    ),
    .valid_i   ( itf.valid_i ),
    .key_i     ( itf.key     ),
    .val_i     ( itf.val_i   ),
    .val_o     ( itf.val_o   ),
    .valid_o   ( itf.valid_o )
);

default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    repeat (5) @(tb_clk);
    itf.reset_n <= 1'b1;
    repeat (5) @(tb_clk);
endtask

// DO NOT MODIFY CODE ABOVE THIS LINE
key_t [7:0] key_array;
val_t [7:0] val_array;


task test_evict();
      @(tb_clk);
      itf.key = 16'h1111;
      itf.val_i = 16'h2222;
      itf.rw_n = 1'b0;
      itf.valid_i = 1'b1;

      for(int i = 0; i < 8; ++i) begin
            //$display("writing %d : %d to cam", itf.key, itf.val_i);
            @(tb_clk);
            itf.key = key_array[i];
            itf.val_i = val_array[i];
      end

      //$display("writing %d : %d to cam", itf.key, itf.val_i);
      @(tb_clk);
      itf.valid_i = 1'b0;
endtask : test_evict


task read_hit_test();
      test_evict();
      @(tb_clk);
      itf.valid_i = 1'b1;
      itf.rw_n = 1'b1;

      for(int i = 0; i < 8; ++i) begin
            itf.val_i = val_array[i];
            itf.key = key_array[i];
            @(tb_clk);
            //$display("Checking key=%d", key_array[i]);
            //$display("cam out=%d", itf.val_o);
            //$display("correct out=%d", val_array[i]);
            //$display(" ");
            assert(itf.val_o == val_array[i])
            else begin
                  itf.tb_report_dut_error(READ_ERROR);
                  $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, val_array[i - 1]);
            end
      end

      @(tb_clk);
      itf.valid_i = 1'b0;
endtask: read_hit_test

task test_consecutive_write();
      @(tb_clk);
      itf.rw_n = 1'b0;
      itf.valid_i = 1'b1;
      itf.val_i = 16'h000A;
      itf.key = 16'h000F;

      @(tb_clk);
      itf.rw_n = 1'b0;
      itf.valid_i = 1'b1;
      itf.val_i = 16'h000B;
      itf.key = 16'h000F;

      @(tb_clk);
      itf.rw_n = 1'b1;
      itf.key = 16'h000F;
      itf.valid_i = 1'b1;

      @(tb_clk);
      assert(itf.val_o == 16'h000B)
      else begin
            itf.tb_report_dut_error(READ_ERROR);
            $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, 16'h000B);
      end
      itf.valid_i = 1'b0;
      //$display("Test consecutive W results:");
      //$display("expected output: %d", 16'h000B);
      //$display("actual output: %d", itf.val_o);
      //$display(" ");
endtask : test_consecutive_write


task test_consecutive_rw();
      @(tb_clk);
      itf.rw_n = 1'b0;
      itf.valid_i = 1'b1;
      itf.val_i = val_array[1];
      itf.key = key_array[0];

      @(tb_clk);
      itf.rw_n = 1'b1;
      itf.valid_i = 1'b1;
      itf.key = key_array[0];

      @(tb_clk);
      assert(itf.val_o == val_array[1])
      else begin
            itf.tb_report_dut_error(READ_ERROR);
            $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, val_array[1]);
      end
      itf.valid_i = 1'b0;
      //$display("Consecutive RW test results:");
      //$display("expected output: %d", val_array[1]);
      //$display("actual output: %d", itf.val_o);
      //$display(" ");
endtask : test_consecutive_rw


task write(input key_t key, input val_t val);
endtask

task read(input key_t key, output val_t val);
endtask

initial begin
    $display("Starting CAM Tests");

    for(int i = 0; i < 8; ++i) begin
          key_array[i] = i;
          val_array[i] = i * 3 + 10;
    end

    reset();
    /************************** Your Code Here ****************************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    // Consider using the task skeltons above
    // To report errors, call itf.tb_report_dut_error in cam/include/cam_itf.sv

    //$display("Key Array 7: %d", key_array[7]);
    //$display("Val Array 7: %d", val_array[7]);
    test_evict();
    read_hit_test();
    test_consecutive_write();
    test_consecutive_rw();

    /**********************************************************************/

    itf.finish();
end

endmodule : testbench
