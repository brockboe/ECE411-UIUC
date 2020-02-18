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
int i;
int ready;

enum int unsigned {
      state_idle = 0,
      state_read = 1,
      state_write = 2
} state;

always @ (posedge clk) begin
      if (~reset_n) begin
            resp_o <= 1'b0;
            read_o <= 1'b0;
            write_o <= 1'b0;
            counter <= 5'd0;
            state <= state_idle;
            ready <= 0;
            i <= 0;
      end else begin
            if(read_i || (state == state_read)) begin
                  read_o <= 1'b1;
                  write_o <= 1'b0;
                  state <= state_read;

                  if(i < 4) begin
                        //$display("%x, %d, %d", burst_i, resp_i, i);
                        int_buffer[64*i +: 64] <= burst_i;
                        if (resp_i)
                              i <= i + 1;
                        else
                              i <= i;
                  end

                  if(i == 4) begin
                        //$display("Here2");
                        line_o <= int_buffer;
                        resp_o <= 1'b1;
                        ready <= 1;
                        i <= 5;
                  end

                  if(ready) begin
                        //$display("here");
                        resp_o <= 1'b0;
                        read_o <= 1'b0;
                        write_o <= 1'b0;
                        ready <= 0;
                        state <= state_idle;
                  end

            end else if (write_i || (state == state_write)) begin

                  state <= state_write;
                  write_o <= 1'b1;
                  read_o <= 1'b0;

                  //$display("%x", line_i);
                  if(i < 4) begin
                        if (resp_i)
                              i = i + 1;
                        else
                              i = i;
                        //$display("%x, %d", burst_o, i);
                        burst_o = line_i[64*i +: 64];
                        resp_o = 1'b1;

                  end

                  if(i == 4) begin
                        ready <= 1;
                        i <= 5;
                  end

                  if(ready) begin
                        resp_o <= 1'b0;
                        write_o <= 1'b0;
                        read_o <= 1'b0;
                        ready <= 0;
                        i <= 0;
                  end

            end else begin
                  resp_o <= 1'b0;
                  write_o <= 1'b0;
                  read_o <= 1'b0;
                  counter <= 5'd0;
                  i <= 0;
                  ready <= 0;
                  state <= state_idle;
            end
      end
end

endmodule : cacheline_adaptor
