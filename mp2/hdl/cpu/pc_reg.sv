module pc_register #(parameter width = 32)
(
    input clk,
    input load,
    input [width-1:0] in,
    output logic [width-1:0] out
);

/*
* PC needs to start at 0x60
 */
logic [width-1:0] data = 32'h00000060;

always_ff @(posedge clk)
begin
    if (load)
    begin
        data = in;
    end
end

always_comb
begin
    out = data;
end

endmodule : pc_register
