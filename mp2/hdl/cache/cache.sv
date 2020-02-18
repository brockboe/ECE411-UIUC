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
      output mem_rdata,
      input logic mem_read,
      input logic mem_write,
      input logic [3:0] mem_byte_enable,
      input rv32i_word mem_address,
      input rv32i_word mem_wdata,

      // connection to cacheline adaptor
      output logic [255:0] line_i,
      input logic [255:0] line_o,
      output logic [31:0] address_i,
      output read_i,
      output write_i,
      input logic resp_o
);

cache_control control
(
);

cache_datapath datapath
(
);

bus_adapter bus_adapter
(
);

endmodule : cache
