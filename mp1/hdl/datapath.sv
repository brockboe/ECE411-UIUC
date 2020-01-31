`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;
import datapath_types::*;

module datapath
(
    input clk,
    input rst,
    input control_sig ctrl_in,

    input rv32i_word mem_rdata,
    output rv32i_word mem_wdata, // signal used by RVFI Monitor
    output rv32i_word mem_address,
    output datapath_sig dpath_out
);

/******************* Signals Needed for RVFI Monitor *************************/
logic load_pc;
rv32i_word pc_out;
rv32i_word pcmux_out;
rv32i_word rs1_out;
rv32i_word rs2_out;
rv32i_word rd;
rv32i_word regfilemux_out;
rv32i_word mdrreg_out;

glue_sig glue;
assign glue.control = ctrl_in;
assign dpath_out = glue.dpath;

assign load_pc = glue.control.load_pc;
assign pc_out = glue.dpath.pc_out;
assign pcmux_out = glue.dpath.pcmux_out;
assign rs1_out = glue.dpath.rs1_out;
assign rs2_out = glue.dpath.rs2_out;
assign rd = glue.dpath.rd;
assign regfilemux_out = glue.dpath.regfilemux_out;
assign mdrreg_out = glue.dpath.mdrreg_out;

/*****************************************************************************/


/***************************** Registers *************************************/
// Keep Instruction register named `IR` for RVFI Monitor
ir IR(
      .clk(clk),
      .rst(rst),
      .load(glue.control.load_ir),
      .in(glue.dpath.mdrreg_out),
      .funct3(glue.dpath.funct3),
      .funct7(glue.dpath.funct7),
      .opcode(glue.dpath.opcode),
      .i_imm(glue.dpath.i_imm),
      .s_imm(glue.dpath.s_imm),
      .b_imm(glue.dpath.b_imm),
      .u_imm(glue.dpath.u_imm),
      .j_imm(glue.dpath.j_imm),
      .rs1(glue.dpath.rs1),
      .rs2(glue.dpath.rs2),
      .rd(glue.dpath.rd)
);

pc_register PC(
      .clk(clk),
      .rst(rst),
      .load(glue.control.load_pc),
      .in(glue.dpath.pcmux_out),
      .out(glue.dpath.pc_out)
);

regfile regfile(
      .clk(clk),
      .rst(rst),
      .load(glue.control.load_regfile),
      .in(glue.dpath.regfilemux_out),
      .src_a(glue.dpath.rs1),
      .src_b(glue.dpath.rs2),
      .dest(glue.dpath.rd),
      .reg_a(glue.dpath.rs1_out),
      .reg_b(glue.dpath.rs2_out)
);

register MDR(
    .clk  (clk),
    .rst (rst),
    .load (load_mdr),
    .in   (mem_rdata),
    .out  (mdrreg_out)
);

register MAR(
      .clk(clk),
      .rst(rst),
      .load(glue.control.load_mar),
      .in(glue.dpath.marmux_out),
      .out(mem_address)
);

register mem_data_out(
      .clk(clk),
      .rst(rst),
      .load(1'b1),
      .in(glue.dpath.rs2_out),
      .out(mem_wdata)
);

/*****************************************************************************/

/******************************* ALU and CMP *********************************/
alu alu_inst(
      .aluop(glue.control.aluop),
      .a(glue.dpath.alumux1_out),
      .b(glue.dpath.alumux2_out),
      .f(glue.dpath.alu_out)
);

cmp_module cmp(
      .op(glue.control.cmpop),
      .a(glue.dpath.rs1_out),
      .b(glue.dpath.cmp_mux_out),
      .out(glue.dpath.br_en)
);
/*****************************************************************************/

/******************************** Muxes **************************************/
always_comb begin : MUXES
    // We provide one (incomplete) example of a mux instantiated using
    // a case statement.  Using enumerated types rather than bit vectors
    // provides compile time type safety.  Defensive programming is extremely
    // useful in SystemVerilog.  In this case, we actually use
    // Offensive programming --- making simulation halt with a fatal message
    // warning when an unexpected mux select value occurs
    unique case (glue.control.pcmux_sel)
        pcmux::pc_plus4: glue.dpath.pcmux_out = glue.dpath.pc_out + 4;
        pcmux::alu_out:  glue.dpath.pcmux_out = glue.dpath.alu_out;
        pcmux::alu_mod2:  glue.dpath.pcmux_out = {31'd0, glue.dpath.alu_out[0]};
        default: `BAD_MUX_SEL;
    endcase

    unique case (glue.control.regfilemux_sel)
      regfilemux::alu_out: glue.dpath.regfilemux_out = glue.dpath.alu_out;
      regfilemux::br_en: glue.dpath.regfilemux_out =  glue.dpath.br_en;
      regfilemux::u_imm: glue.dpath.regfilemux_out = glue.dpath.u_imm;
      regfilemux::lw: glue.dpath.regfilemux_out = glue.dpath.mdrreg_out;
      regfilemux::pc_plus4: glue.dpath.regfilemux_out = glue.dpath.pc_out + 4;
      //regfilemux::lb:
      //regfilemux::lbu:
      //regfilemux::lh:
      //regfilemux::lhu:
      default: `BAD_MUX_SEL;
    endcase

    unique case (glue.control.marmux_sel)
      marmux::pc_out: glue.dpath.marmux_out = glue.dpath.pc_out;
      marmux::alu_out: glue.dpath.marmux_out = glue.dpath.alu_out;
      default: `BAD_MUX_SEL;
    endcase

    unique case (glue.control.cmpmux_sel)
      cmpmux::rs2_out: glue.dpath.cmp_mux_out = glue.dpath.rs1_out;
      cmpmux::i_imm: glue.dpath.cmp_mux_out = glue.dpath.i_imm;
      default: `BAD_MUX_SEL;
    endcase

    unique case (glue.control.alumux1_sel)
      alumux::rs1_out: glue.dpath.alumux1_out = glue.dpath.rs1_out;
      alumux::pc_out: glue.dpath.alumux1_out = glue.dpath.pc_out;
      default: `BAD_MUX_SEL;
    endcase

    unique case (glue.control.alumux2_sel)
      alumux::i_imm: glue.dpath.alumux2_out = glue.dpath.i_imm;
      alumux::u_imm: glue.dpath.alumux2_out = glue.dpath.u_imm;
      alumux::b_imm: glue.dpath.alumux2_out = glue.dpath.b_imm;
      alumux::s_imm: glue.dpath.alumux2_out = glue.dpath.s_imm;
      alumux::j_imm: glue.dpath.alumux2_out = glue.dpath.j_imm;
      alumux::rs2_out: glue.dpath.alumux2_out = glue.dpath.rs2_out;
      default: `BAD_MUX_SEL;
    endcase

end
/*****************************************************************************/
endmodule : datapath
