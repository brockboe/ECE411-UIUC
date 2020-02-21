import cache_internal_itf::*;
import rv32i_types::*;

module cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
      input clk,
      input rst,

      // connection to CPU
      output mem_resp,
      input logic mem_read,
      input logic mem_write,
      input logic [3:0] mem_byte_enable,
      input rv32i_word mem_address,
      output rv32i_word mem_rdata,
      input rv32i_word mem_wdata,

      // connection to cacheline adaptor
      output logic [255:0] pmem_wdata,
      input logic [255:0] pmem_rdata,
      output logic [31:0] pmem_address,
      output pmem_read,
      output pmem_write,
      input logic pmem_resp
);

cache_internal_itf::dpath_out dpath_connector;
cache_internal_itf::ctrl_sig ctrl_connector;

logic [255:0] bus_wdata;
logic [255:0] bus_rdata;
logic [31:0] mem_byte_enable256;

logic [255:0] cacheline_out;
assign pmem_wdata = cacheline_out;
assign bus_rdata = cacheline_out;

cache_control control
(
      .clk(clk),
      .rst(rst),
      .cpu_write(mem_write),
      .cpu_read(mem_read),
      .mem_resp(pmem_resp),
      .cache_resp(mem_resp),
      .mem_read(pmem_read),
      .mem_write(pmem_write),
      .ctrl_out(ctrl_connector),
      .dpath_in(dpath_connector),
      .address(mem_address)
);

cache_datapath datapath
(
      .clk(clk),
      .rst(rst),
      .ctrl_in(ctrl_connector),
      .dpath(dpath_connector),
      .address(mem_address),
      .cacheline_in(pmem_rdata),
      .bus_adaptor_line_in(bus_wdata),
      .bus_adaptor_write_en(mem_byte_enable256),
      .cacheline_out(cacheline_out),
      .mem_addr(pmem_address)
);

bus_adapter bus_adapter
(
      .mem_wdata256(bus_wdata),
      .mem_rdata256(bus_rdata),
      .mem_wdata(mem_wdata),
      .mem_rdata(mem_rdata),
      .mem_byte_enable(mem_byte_enable),
      .mem_byte_enable256(mem_byte_enable256),
      .address(mem_address)
);

endmodule : cache
