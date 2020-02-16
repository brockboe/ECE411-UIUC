/**
 * `memory` loads a binary into memory, and uses this to drive
 * the DUT.
**/
module source_tb(
    tb_itf.tb itf,
    tb_itf.mem mem_itf
);

logic [31:0] write_data;
logic [31:0] write_address;
logic write;

always @(posedge itf.clk)
begin
    if (itf.mem_write & itf.mem_resp) begin
        write_address = itf.mem_address;
        write_data = itf.mem_wdata;
        write = 1;
    end else begin
        write_address = 32'hx;
        write_data = 32'hx;
        write = 0;
    end
end

memory memory(
    .clk     (itf.clk),
    .read    (itf.mem_read),
    .write   (itf.mem_write),
    .wmask   (itf.mem_byte_enable),
    .address (itf.mem_address),
    .wdata   (itf.mem_wdata),
    .resp    (itf.mem_resp),
    .rdata   (itf.mem_rdata)
);

endmodule : source_tb
