module shadow_memory
(
    input clk,

    input valid,
    input logic [3:0] wmask,
    input logic [3:0] rmask,
    input logic [31:0] addr,
    input logic [31:0] wdata,
    input logic [31:0] rdata,
    input logic [31:0] pc_rdata,
    input logic [31:0] insn,
    output logic error
);

logic [255:0] mem [2**(22)]; //only get fraction of 4GB addressable space due to modelsim limits
logic [21:0] internal_address;
logic [21:0] internal_pc_address;
logic [2:0] internal_offset;
logic [2:0] internal_pc_offset;
logic [31:0] spec_rdata;
logic [31:0] spec_insn;

/* Initialize memory contents from memory.lst file */
initial
begin
    $readmemh("memory.lst", mem);
    error = 0;
end

/* Calculate internal address */
assign internal_address = addr[26:5];
assign internal_offset = addr[4:2];
assign internal_pc_address = pc_rdata[26:5];
assign internal_pc_offset = pc_rdata[4:2];

/* Expected values to be read */
assign spec_rdata = mem[internal_address][(internal_offset*32) +: 32];
assign spec_insn = mem[internal_pc_address][(internal_pc_offset*32) +: 32];

/* Update */
always @(posedge clk)
begin : mem_write
    if (valid) begin
        for (int i = 0; i < 4; i++) begin
            if (wmask[i]) begin
                mem[internal_address][((internal_offset*32) + (i*8)) +: 8] = wdata[(i*8) +: 8];
            end
            if (rmask[i] && (spec_rdata[(i*8) +: 8] != rdata[(i*8) +: 8]))
            begin
                $display("Mismatch in shadow memory rdata!");
                error = 1;
            end
        end
        if (spec_insn != insn)
        begin
            $display("Mismatch in shadow memory instruction!");
            error = 1;
        end
    end
end : mem_write

endmodule : shadow_memory
