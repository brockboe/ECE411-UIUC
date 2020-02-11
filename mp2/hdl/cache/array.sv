module array #(
	parameter s_index = 3,
	parameter width = 1
)
(
    input clk,
	input read,
    input load,
    input [s_index-1:0] index,
    input [width-1:0] datain,
    output logic [width-1:0] dataout
);
localparam num_sets = 2**s_index;

logic [width-1:0] data [num_sets-1:0] /* synthesis ramstyle = "logic" */ = '{default: '0};
logic [width-1:0] _dataout;
assign dataout = _dataout;

always_ff @(posedge clk)
begin
	 if (read)
        _dataout <= data[index];

    if(load)
        data[index] <= datain;
end

endmodule : array
