`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import cache_internal_itf::*;

module cache_datapath #(
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

      input cache_internal_itf::ctrl_sig ctrl_in,
      output cache_internal_itf::dpath_out dpath,

      input logic [31:0] address,
      input logic [255:0] cacheline_in,
      input logic [255:0] bus_adaptor_line_in,
      input logic [31:0] bus_adaptor_write_en,

      output logic [31:0] mem_addr,
      output logic [255:0] cacheline_out
);

logic [23:0] old_tag;
assign old_tag = dpath.lru ? dpath.tag1 : dpath.tag2;

array #(.s_index(3), .width(24))
tag_array_1 (
      .clk(clk),
      .rst(rst),
      .read(1'b1),
      .load(ctrl_in.ld_tag_1),
      .rindex(address[7:5]),
      .windex(address[7:5]),
      .datain(address[31:8]),
      .dataout(dpath.tag1)
);

array  #(.s_index(3), .width(24))
tag_array_2 (
      .clk(clk),
      .rst(rst),
      .read(1'b1),
      .load(ctrl_in.ld_tag_2),
      .rindex(address[7:5]),
      .windex(address[7:5]),
      .datain(address[31:8]),
      .dataout(dpath.tag2)
);

array #(.s_index(3), .width(1))
dirty_array_1(
      .clk(clk),
      .rst(rst),
      .read(1'b1),
      .load(ctrl_in.ld_dirty_1),
      .rindex(address[7:5]),
      .windex(address[7:5]),
      .datain(ctrl_in.dirty_in_1),
      .dataout(dpath.dirty1)
);

array #(.s_index(3), .width(1))
dirty_array_2(
      .clk(clk),
      .rst(rst),
      .read(1'b1),
      .load(ctrl_in.ld_dirty_2),
      .rindex(address[7:5]),
      .windex(address[7:5]),
      .datain(ctrl_in.dirty_in_2),
      .dataout(dpath.dirty2)
);

array #(.s_index(3), .width(1))
last_used_array(
      .clk(clk),
      .rst(rst),
      .read(1'b1),
      .load(ctrl_in.ld_lru),
      .rindex(address[7:5]),
      .windex(address[7:5]),
      .datain(ctrl_in.lru_in),
      .dataout(dpath.lru)
);

array #(.s_index(3), .width(2))
valid_array(
      .clk(clk),
      .rst(rst),
      .read(1'b1),
      .load(ctrl_in.ld_valid),
      .rindex(address[7:5]),
      .windex(address[7:5]),
      .datain(ctrl_in.valid_in),
      .dataout(dpath.valid)
);

logic [255:0] data_array_datain_1;
logic [255:0] data_array_dataout_1;
logic [31:0] data_array_wen_1;

logic [255:0] data_array_datain_2;
logic [255:0] data_array_dataout_2;
logic [31:0] data_array_wen_2;

data_array way1
(
      .clk(clk),
      .rst(rst),
      .read(1'b1),
      .write_en(data_array_wen_1),
      .rindex(address[7:5]),
      .windex(address[7:5]),
      .datain(data_array_datain_1),
      .dataout(data_array_dataout_1)
);

data_array way2
(
      .clk(clk),
      .rst(rst),
      .read(1'b1),
      .write_en(data_array_wen_2),
      .rindex(address[7:5]),
      .windex(address[7:5]),
      .datain(data_array_datain_2),
      .dataout(data_array_dataout_2)
);

always_comb begin
      unique case (ctrl_in.write_sel_1)
            cacheline: data_array_datain_1 = cacheline_in;
            bus_adaptor: data_array_datain_1 = bus_adaptor_line_in;
            default: data_array_datain_1 = cacheline_in;
      endcase

      unique case (ctrl_in.write_sel_2)
            cacheline: data_array_datain_2 = cacheline_in;
            bus_adaptor: data_array_datain_2 = bus_adaptor_line_in;
            default: data_array_datain_2 = cacheline_in;
      endcase

      unique case (ctrl_in.write_en_sel1)
            nowrite: data_array_wen_1 = 32'd0;
            writeall: data_array_wen_1 = {{32{1'b1}}};
            cpuwrite: data_array_wen_1 = bus_adaptor_write_en;
            default: data_array_wen_1 = 32'd0;
      endcase

      unique case (ctrl_in.write_en_sel2)
            nowrite: data_array_wen_2 = 32'd0;
            writeall: data_array_wen_2 = {{32{1'b1}}};
            cpuwrite: data_array_wen_2 = bus_adaptor_write_en;
            default: data_array_wen_2 = 32'd0;
      endcase

      unique case (ctrl_in.output_sel)
            data_way1: cacheline_out = data_array_dataout_1;
            data_way2: cacheline_out = data_array_dataout_2;
            default: cacheline_out = data_array_dataout_1;
      endcase

      unique case (ctrl_in.pmem_address)
            cpu: mem_addr = {address[31:5], 5'd0};
            write_dirt: mem_addr = {old_tag, address[7:5], 5'd0};
            default: mem_addr = {address[31:5], 5'd0};
      endcase
end

endmodule : cache_datapath
