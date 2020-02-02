import rv32i_types::*;
import datapath_types::*;

module mp1
(
    input clk,
    input rst,
    input mem_resp,
    input rv32i_word mem_rdata,
    output logic mem_read,
    output logic mem_write,
    output logic [3:0] mem_byte_enable,
    output rv32i_word mem_address,
    output rv32i_word mem_wdata
);

/******************* Signals Needed for RVFI Monitor *************************/
logic load_pc;
logic load_regfile;
/*****************************************************************************/

/**************************** Control Signals ********************************/
pcmux::pcmux_sel_t pcmux_sel;
alumux::alumux1_sel_t alumux1_sel;
alumux::alumux2_sel_t alumux2_sel;
regfilemux::regfilemux_sel_t regfilemux_sel;
marmux::marmux_sel_t marmux_sel;
cmpmux::cmpmux_sel_t cmpmux_sel;
/*****************************************************************************/

/* Instantiate MP 1 top level blocks here */

datapath_sig dpath_connector;
control_sig ctrl_connector;

// Keep control named `control` for RVFI Monitor
control control(
      .clk(clk),
      .rst(rst),
      .dpath_status(dpath_connector),
      .mem_resp(mem_resp),
      .mem_read(mem_read),
      .mem_write(mem_write),
      .ctrl_out(ctrl_connector)
);

// Keep datapath named `datapath` for RVFI Monitor
datapath datapath(
      .clk(clk),
      .rst(rst),
      .ctrl_in(ctrl_connector),

      .mem_rdata(mem_rdata),
      .mem_wdata(mem_wdata),
      .mem_address(mem_address),
      .dpath_out(dpath_connector)
);

endmodule : mp1