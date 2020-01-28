module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

logic [255:0] int_buffer;
logic [4:0] counter;
assign address_o = address_i;

always @ (posedge clk) begin
      if (~reset_n) begin
            resp_o <= 1'b0;
            read_o <= 1'b0;
            write_o <= 1'b0;
            counter <= 5'd0;
      end else begin
            if(read_i) begin
                  read_o <= 1'b1;
                  write_o <= 1'b0;

                  for(int i = 0; i < 4; ++i) begin
                        @(posedge clk iff resp_i);
                        int_buffer[64*i +: 64] <= burst_i;
                        //$display("Filling buffer: %d / 4", i+1);
                  end
                  //$display(" ");

                  @(posedge clk);
                  line_o <= int_buffer;
                  resp_o <= 1'b1;

                  @(posedge clk);
                  resp_o <= 1'b0;
                  read_o <= 1'b0;
                  write_o <= 1'b0;

            end else if (write_i) begin

                  write_o <= 1'b1;
                  read_o <= 1'b0;

                  for(int i = 0; i < 4; i++) begin
                        burst_o <= line_i[64*i +: 64];
                        resp_o <= 1'b1;
                        @(posedge clk iff resp_i);
                  end

                  @(posedge clk);
                  resp_o <= 1'b0;
                  write_o <= 1'b0;
                  read_o <= 1'b0;

            end else begin
                  resp_o <= 1'b0;
                  write_o <= 1'b0;
                  read_o <= 1'b0;
                  counter <= 5'd0;
            end
      end
end

endmodule : cacheline_adaptor
