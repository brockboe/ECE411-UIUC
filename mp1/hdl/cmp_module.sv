import rv32i_types::*;
import datapath_types::*;

`define BAD_MUX_SEL_CMP $fatal("%0t %s %0d: Illegal cmpop select", $time, `__FILE__, `__LINE__)

module cmp_module(
      input branch_funct3_t op,
      input rv32i_word a,
      input rv32i_word b,
      output logic result
);

always_comb begin
      unique case (op)
            rv32i_types::beq: result = (a == b);
            rv32i_types::bne: result = (a != b);
            rv32i_types::blt: result = ($signed(a) < $signed(b));
            rv32i_types::bge: result = ($signed(a) >= $signed(b));
            rv32i_types::bltu: result = (a < b);
            rv32i_types::bgeu: result = (a >= b);
            default: `BAD_MUX_SEL_CMP;
      endcase
end

endmodule
