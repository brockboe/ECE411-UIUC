import rv32i_types::*;
import pcmux::*;
import marmux::*;
import cmpmux::*;
import alumux::*;
import regfilemux::*;

package datapath_types;

typedef struct packed
{
      logic load_pc;
      logic load_ir;
      logic load_regfile;
      logic load_mar;
      logic load_mdr;
      logic load_data_out;
      pcmux::pcmux_sel_t pcmux_sel;
      alumux::alumux1_sel_t alumux1_sel;
      alumux::alumux2_sel_t alumux2_sel;
      regfilemux::regfilemux_sel_t regfilemux_sel;
      marmux::marmux_sel_t marmux_sel;
      cmpmux::cmpmux_sel_t cmpmux_sel;
      rv32i_types::alu_ops aluop;
      rv32i_types::branch_funct3_t cmpop;
} control_sig;

typedef struct packed
{
      rv32i_types::rv32i_reg rs1;
      rv32i_types::rv32i_reg rs2;
      rv32i_types::rv32i_reg rd;
      rv32i_types::rv32i_word rs1_out;
      rv32i_types::rv32i_word rs2_out;
      rv32i_types::rv32i_word i_imm;
      rv32i_types::rv32i_word u_imm;
      rv32i_types::rv32i_word b_imm;
      rv32i_types::rv32i_word s_imm;
      rv32i_types::rv32i_word j_imm;
      rv32i_types::rv32i_word pcmux_out;
      rv32i_types::rv32i_word alumux1_out;
      rv32i_types::rv32i_word alumux2_out;
      rv32i_types::rv32i_word regfilemux_out;
      rv32i_types::rv32i_word marmux_out;
      rv32i_types::rv32i_word cmp_mux_out;
      rv32i_types::rv32i_word alu_out;
      rv32i_types::rv32i_word pc_out;
      rv32i_types::rv32i_word pc_plus4_out;
      rv32i_types::rv32i_word mdrreg_out;
      rv32i_types::rv32i_word mem_address;
      rv32i_types::rv32i_word mem_wdata;
      rv32i_types::rv32i_word mem_rdata;
      rv32i_types::rv32i_opcode opcode;
      logic [2:0] funct3;
      logic [6:0] funct7;
      logic br_en;

      logic [3:0] mem_byte_enable;
} datapath_sig;

typedef struct packed
{
      control_sig control;
      datapath_sig dpath;
} glue_sig;

endpackage : datapath_types
