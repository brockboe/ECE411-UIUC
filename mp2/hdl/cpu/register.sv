module register #(parameter width = 32)
(
    input clk,
    input load,
    input [width-1:0] in,
    output logic [width-1:0] out
);

logic [width-1:0] data = 1'b0;

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

endmodule : register
