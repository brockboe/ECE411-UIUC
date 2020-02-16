/**
 * Interface used by testbenches to communicate with memory and
 * the DUT.
**/
interface tb_itf;

timeunit 1ns;
timeprecision 1ns;

bit clk;
bit mon_rst;
logic mem_resp;
logic mem_read;
logic mem_write;
logic [3:0] mem_byte_enable;
logic [15:0] errcode;
logic [31:0] mem_address;
logic [255:0] mem_rdata;
logic [255:0] mem_wdata;
logic halt;
logic [31:0] write_data;
logic [31:0] registers [32];
logic sm_error;
logic pm_error;

// The monitor has a reset signal, which it needs, but
// you use initial blocks in your DUT, so we generate two clocks
initial begin
    mon_rst = '1;
    clk = '0;
    #40;
    mon_rst = '0;
end

always #5 clk = ~clk; 


endinterface : tb_itf
