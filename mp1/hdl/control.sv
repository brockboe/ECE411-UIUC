import rv32i_types::*; /* Import types defined in rv32i_types.sv */
import datapath_types::*;
import pcmux::*;
import marmux::*;
import cmpmux::*;
import alumux::*;
import regfilemux::*;

module control
(
    input clk,
    input rst,

    input datapath_sig dpath_status,
    input logic mem_resp,


    output logic mem_read,
    output logic mem_write,
    output control_sig ctrl_out,
    output logic [3:0] mem_byte_enable
    /*
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic br_en,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    output pcmux::pcmux_sel_t pcmux_sel,
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output marmux::marmux_sel_t marmux_sel,
    output cmpmux::cmpmux_sel_t cmpmux_sel,
    output alu_ops aluop,
    output logic load_pc,
    output logic load_ir,
    output logic load_regfile,
    output logic load_mar,
    output logic load_mdr,
    output logic load_data_out
    */
);

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0] rmask, wmask;
logic [3:0] half_unaligned;
logic [3:0] byte_unaligned;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(dpath_status.funct3);
assign branch_funct3 = branch_funct3_t'(dpath_status.funct3);
assign load_funct3 = load_funct3_t'(dpath_status.funct3);
assign store_funct3 = store_funct3_t'(dpath_status.funct3);
assign rs1_addr = dpath_status.rs1;
assign rs2_addr = dpath_status.rs2;

always_comb
begin : trap_check
    trap = 0;
    rmask = '0;
    wmask = '0;

    case (dpath_status.opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                rv32i_types::lw: rmask = 4'b1111;
                rv32i_types::lh, rv32i_types::lhu: rmask = half_unaligned /* Modify for MP1 Final */ ;
                rv32i_types::lb, rv32i_types::lbu: rmask = byte_unaligned /* Modify for MP1 Final */ ;
                default: trap = 1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                rv32i_types::sw: wmask = 4'b1111;
                rv32i_types::sh: wmask = half_unaligned /* Modify for MP1 Final */ ;
                rv32i_types::sb: wmask = byte_unaligned /* Modify for MP1 Final */ ;
                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end
/*****************************************************************************/
always_comb begin
      unique case(dpath_status.marmux_out[1:0])
            2'b00: half_unaligned = 4'b0011;
            2'b01: half_unaligned = 4'b0110;
            2'b10: half_unaligned = 4'b1100;
            2'b11: half_unaligned = 4'b1001;
      endcase

      unique case(dpath_status.marmux_out[1:0])
            2'b00: byte_unaligned = 4'b0001;
            2'b01: byte_unaligned = 4'b0010;
            2'b10: byte_unaligned = 4'b0100;
            2'b11: byte_unaligned = 4'b1000;
      endcase
end

assign ctrl_out.byte_mask = byte_unaligned;
assign ctrl_out.half_mask = half_unaligned;

enum int unsigned {
    /* List of states */
    fetch1        = 0,
    fetch2        = 1,
    fetch3        = 2,
    decode        = 3,
    imm           = 4,
    lui           = 5,
    calc_addr     = 6,
    ldr1           = 7,
    ldr2           = 8,
    str1           = 9,
    str2           = 10,
    auipc         = 11,
    br            = 12,
    calc_addr_sw  = 13,
    reg_op        = 14,
    jal           = 15,
    jal2          = 16,
    jalr          = 17,
    jalr2         = 18
} state, next_state;

/************************* Function Definitions *******************************/
/**
 *  You do not need to use these functions, but it can be nice to encapsulate
 *  behavior in such a way.  For example, if you use the `loadRegfile`
 *  function, then you only need to ensure that you set the load_regfile bit
 *  to 1'b1 in one place, rather than in many.
 *
 *  SystemVerilog functions must take zero "simulation time" (as opposed to
 *  tasks).  Thus, they are generally synthesizable, and appropraite
 *  for design code.  Arguments to functions are, by default, input.  But
 *  may be passed as outputs, inouts, or by reference using the `ref` keyword.
**/

/**
 *  Rather than filling up an always_block with a whole bunch of default values,
 *  set the default values for controller output signals in this function,
 *   and then call it at the beginning of your always_comb block.
**/
function void set_defaults();
      ctrl_out.load_pc = 1'b0;
      ctrl_out.load_ir = 1'b0;
      ctrl_out.load_regfile = 1'b0;
      ctrl_out.load_mar = 1'b0;
      ctrl_out.load_mdr = 1'b0;
      ctrl_out.load_data_out = 1'b0;
      ctrl_out.pcmux_sel = pcmux::pc_plus4;
      ctrl_out.alumux1_sel = alumux::rs1_out;
      ctrl_out.alumux2_sel = alumux::i_imm;
      ctrl_out.regfilemux_sel = regfilemux::alu_out;
      ctrl_out.marmux_sel = marmux::pc_out;
      ctrl_out.cmpmux_sel = cmpmux::rs2_out;
      ctrl_out.aluop = rv32i_types::alu_add;
      ctrl_out.cmpop = rv32i_types::beq;
      mem_byte_enable = 4'b0000;
      mem_read = 1'b0;
      mem_write = 1'b0;
endfunction

/**
 *  Use the next several functions to set the signals needed to
 *  load various registers
**/
function void loadPC(pcmux::pcmux_sel_t sel);
    ctrl_out.load_pc = 1'b1;
    ctrl_out.pcmux_sel = sel;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
endfunction

function void loadMAR(marmux::marmux_sel_t sel);
endfunction

function void loadMDR();
endfunction

/**
 * SystemVerilog allows for default argument values in a way similar to
 *   C++.
**/
//function void setALU(alumux::alumux1_sel_t sel1,
//                               alumux::alumux2_sel_t sel2,
//                               logic setop = 1'b0, alu_ops op = alu_add);
    /* Student code here */


//    if (setop)
//        ctrl_out.aluop = op; // else default value
//endfunction

//function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
//endfunction

/*****************************************************************************/

    /* Remember to deal with rst signal */

always_comb
begin : state_actions
      /* Default output assignments */
      set_defaults();
      /* Actions for each state */
      if(state == fetch1) begin
            ctrl_out.load_mar = 1'b1;
            ctrl_out.marmux_sel = marmux::pc_out;
      end

      else if (state == fetch2) begin
            ctrl_out.load_mdr = 1'b1;
            mem_read = 1'b1;
      end

      else if (state == fetch3) begin
            ctrl_out.load_ir = 1'b1;
      end

      else if (state == auipc) begin
            ctrl_out.alumux1_sel = alumux::pc_out;
            ctrl_out.alumux2_sel = alumux::u_imm;
            ctrl_out.regfilemux_sel = regfilemux::alu_out;
            ctrl_out.aluop = rv32i_types::alu_add;
            ctrl_out.load_regfile = 1'b1;

            ctrl_out.pcmux_sel = pcmux::pc_plus4;
            ctrl_out.load_pc = 1'b1;

            ctrl_out.marmux_sel = marmux::alu_out;
      end

      else if (state == calc_addr) begin
            ctrl_out.aluop = rv32i_types::alu_add;
            ctrl_out.load_mar = 1'b1;
            ctrl_out.marmux_sel = marmux::alu_out;
      end

      else if (state == ldr1) begin
            ctrl_out.load_mdr = 1'b1;
            mem_read = 1'b1;

            ctrl_out.aluop = rv32i_types::alu_add;
            ctrl_out.marmux_sel = marmux::alu_out;
      end

      else if (state == ldr2) begin
            unique case(dpath_status.funct3)
                  rv32i_types::lb: ctrl_out.regfilemux_sel = regfilemux::lb;
                  rv32i_types::lh: ctrl_out.regfilemux_sel = regfilemux::lh;
                  rv32i_types::lw: ctrl_out.regfilemux_sel = regfilemux::lw;
                  rv32i_types::lbu: ctrl_out.regfilemux_sel = regfilemux::lbu;
                  rv32i_types::lhu: ctrl_out.regfilemux_sel = regfilemux::lhu;
                  default: ctrl_out.regfilemux_sel = regfilemux::alu_out;
            endcase
            ctrl_out.load_regfile = 1'b1;
            ctrl_out.load_pc = 1'b1;

            ctrl_out.aluop = rv32i_types::alu_add;
            ctrl_out.marmux_sel = marmux::alu_out;
      end

      else if (state == lui) begin
            ctrl_out.load_regfile = 1'b1;
            ctrl_out.load_pc = 1'b1;
            ctrl_out.regfilemux_sel = regfilemux::u_imm;
      end

      else if (state == imm) begin
            if (dpath_status.funct3 == rv32i_types::slt) begin
                  ctrl_out.load_regfile = 1'b1;
                  ctrl_out.load_pc = 1'b1;
                  ctrl_out.cmpop = rv32i_types::blt;
                  ctrl_out.cmpmux_sel = cmpmux::i_imm;
                  ctrl_out.regfilemux_sel = regfilemux::br_en;
            end
            else if (dpath_status.funct3 == rv32i_types::sltu) begin
                  ctrl_out.load_regfile = 1'b1;
                  ctrl_out.load_pc = 1'b1;
                  ctrl_out.cmpop = rv32i_types::bltu;
                  ctrl_out.cmpmux_sel = cmpmux::i_imm;
                  ctrl_out.regfilemux_sel = regfilemux::br_en;
            end
            else if (dpath_status.funct3 == rv32i_types::sr) begin
                  ctrl_out.load_regfile = 1'b1;
                  ctrl_out.load_pc = 1'b1;

                  if (dpath_status.funct7 == 7'b0100000)
                        ctrl_out.aluop = rv32i_types::alu_sra;
                  else
                        ctrl_out.aluop = rv32i_types::alu_srl;

                  ctrl_out.regfilemux_sel = regfilemux::alu_out;
            end
            else begin
                  ctrl_out.load_regfile = 1'b1;
                  ctrl_out.load_pc = 1'b1;
                  ctrl_out.aluop = alu_ops ' (dpath_status.funct3);
                  ctrl_out.regfilemux_sel = regfilemux::alu_out;
            end
      end

      else if (state == reg_op) begin
            ctrl_out.load_regfile = 1'b1;
            ctrl_out.load_pc = 1'b1;
            ctrl_out.aluop = rv32i_types::alu_ops ' (dpath_status.funct3);
            ctrl_out.alumux2_sel = alumux::rs2_out;
            ctrl_out.regfilemux_sel = regfilemux::alu_out;
            if((dpath_status.funct3 == rv32i_types::add) && (dpath_status.funct7 == 7'b0000000))
                  ctrl_out.aluop = rv32i_types::alu_add;
            else if((dpath_status.funct3 == rv32i_types::add) && (dpath_status.funct7 == 7'b0100000))
                  ctrl_out.aluop = rv32i_types::alu_sub;
            else if((dpath_status.funct3 == rv32i_types::sll))
                  ctrl_out.aluop = rv32i_types::alu_sll;
            else if((dpath_status.funct3 == rv32i_types::slt)) begin
                  ctrl_out.cmpop = rv32i_types::blt;
                  ctrl_out.cmpmux_sel = cmpmux::rs2_out;
                  ctrl_out.regfilemux_sel = regfilemux::br_en;
            end
            else if((dpath_status.funct3 == rv32i_types::sltu)) begin
                  ctrl_out.cmpop = rv32i_types::bltu;
                  ctrl_out.cmpmux_sel = cmpmux::rs2_out;
                  ctrl_out.regfilemux_sel = regfilemux::br_en;
            end
            else if((dpath_status.funct3 == rv32i_types::axor))
                  ctrl_out.aluop = rv32i_types::alu_xor;
            else if((dpath_status.funct3 == rv32i_types::sr) && (dpath_status.funct7 == 7'b0000000))
                  ctrl_out.aluop = rv32i_types::alu_srl;
            else if((dpath_status.funct3 == rv32i_types::sr) && (dpath_status.funct7 == 7'b0100000))
                  ctrl_out.aluop = rv32i_types::alu_sra;
            else
                  ctrl_out.aluop = rv32i_types::alu_ops ' (dpath_status.funct3);
      end

      else if (state == br) begin
            ctrl_out.pcmux_sel = pcmux::pcmux_sel_t ' (dpath_status.br_en);
            ctrl_out.load_pc = 1'b1;
            ctrl_out.alumux1_sel = alumux::pc_out;
            ctrl_out.alumux2_sel = alumux::b_imm;
            ctrl_out.aluop = rv32i_types::alu_add;
            ctrl_out.cmpop = rv32i_types::branch_funct3_t ' (dpath_status.funct3);
      end

      else if (state == calc_addr_sw) begin
            ctrl_out.alumux2_sel = alumux::s_imm;
            ctrl_out.aluop = rv32i_types::alu_add;
            ctrl_out.load_mar = 1'b1;
            ctrl_out.load_data_out = 1'b1;
            ctrl_out.marmux_sel = marmux::alu_out;
      end

      else if (state == str1) begin
            mem_read = 1'b0;
            mem_write = 1'b1;
            //mem_byte_enable = 4'b1111;
            unique case (dpath_status.funct3)
                  rv32i_types::sb: mem_byte_enable = byte_unaligned;
                  rv32i_types::sh: mem_byte_enable = half_unaligned;
                  rv32i_types::sw: mem_byte_enable = 4'b1111;
                  default: mem_byte_enable = 4'b1111;
            endcase

            ctrl_out.alumux2_sel = alumux::s_imm;
            ctrl_out.aluop = rv32i_types::alu_add;
            ctrl_out.marmux_sel = marmux::alu_out;
      end

      else if (state == str2) begin
            ctrl_out.load_pc = 1'b1;

            ctrl_out.alumux2_sel = alumux::s_imm;
            ctrl_out.aluop = rv32i_types::alu_add;
            ctrl_out.marmux_sel = marmux::alu_out;
      end

      else if (state == jal) begin
            ctrl_out.regfilemux_sel = regfilemux::pc_plus4;
            ctrl_out.load_regfile = 1'b1;

            ctrl_out.aluop = rv32i_types::alu_add;
            ctrl_out.alumux1_sel = alumux::pc_out;
            ctrl_out.alumux2_sel = alumux::j_imm;
            ctrl_out.pcmux_sel = pcmux::alu_mod2;
            ctrl_out.load_pc = 1'b1;
      end

      /*
      else if (state == jal2) begin
            ctrl_out.aluop = rv32i_types::alu_add;
            ctrl_out.alumux1_sel = alumux::pc_out;
            ctrl_out.alumux2_sel = alumux::j_imm;
            ctrl_out.load_pc = 1'b1;
            ctrl_out.pcmux_sel = pcmux::alu_out;
      end
      */

      else if (state == jalr) begin
            ctrl_out.regfilemux_sel = regfilemux::pc_plus4;
            ctrl_out.load_regfile = 1'b1;

            ctrl_out.aluop = rv32i_types::alu_add;
            ctrl_out.alumux1_sel = alumux::rs1_out;
            ctrl_out.alumux2_sel = alumux::i_imm;
            ctrl_out.pcmux_sel = pcmux::alu_mod2;
            ctrl_out.load_pc = 1'b1;
      end

      /*
      else if (state == jalr2) begin
            ctrl_out.aluop = rv32i_types::alu_add;
            ctrl_out.alumux1_sel = alumux::rs1_out;
            ctrl_out.alumux2_sel = alumux::i_imm;
            ctrl_out.load_pc = 1'b1;
            ctrl_out.pcmux_sel = pcmux::alu_out;
      end
      */
end

always_comb
begin : next_state_logic
      /* Next state information and conditions (if any)
      * for transitioning between states */
      if(rst) begin
            next_state <= fetch1;
      end else begin

            if(state == fetch1)
                  next_state <= fetch2;

            else if(state == fetch2) begin
                  if(mem_resp == 1'b0)
                        next_state <= fetch2;
                  else
                        next_state <= fetch3;
            end

            else if(state == fetch3)
                  next_state <= decode;

            else if(state == calc_addr)
                  next_state <= ldr1;

            else if(state == ldr1) begin
                  if(mem_resp == 1'b0)
                        next_state <= ldr1;
                  else
                        next_state <= ldr2;
            end

            else if(state == ldr2)
                  next_state <= fetch1;

            else if(state == decode) begin

                  unique case(dpath_status.opcode)
                        rv32i_types::op_auipc: next_state <= auipc;
                        rv32i_types::op_load: next_state <= calc_addr;
                        rv32i_types::op_lui: next_state <= lui;
                        rv32i_types::op_imm: next_state <= imm;
                        rv32i_types::op_br: next_state <= br;
                        rv32i_types::op_store: next_state <= calc_addr_sw;
                        rv32i_types::op_reg: next_state <= reg_op;
                        rv32i_types::op_jal: next_state <= jal;
                        rv32i_types::op_jalr: next_state <= jalr;
                        default: next_state <= fetch1;
                  endcase

                  /*
                  if(dpath_status.opcode == rv32i_types::op_auipc)
                        next_state <= auipc;
                  else if(dpath_status.opcode == rv32i_types::op_load)
                        next_state <= calc_addr;
                  else if(dpath_status.opcode == rv32i_types::op_lui)
                        next_state <= lui;
                  else if(dpath_status.opcode == rv32i_types::op_imm)
                        next_state <= imm;
                  else if(dpath_status.opcode == rv32i_types::op_br)
                        next_state <= br;
                  else if(dpath_status.opcode == rv32i_types::op_store)
                        next_state <= calc_addr_sw;
                  else if(dpath_status.opcode == rv32i_types::op_reg)
                        next_state <= reg_op;
                  else
                        next_state <= fetch1;
                  */
            end

            else if(state == jal)
                  next_state <= fetch1;

            //else if(state == jal2)
            //      next_state <= fetch1;

            else if(state == jalr)
                  next_state <= fetch1;

            //else if(state == jalr2)
            //      next_state <= fetch1;

            else if(state == lui)
                  next_state <= fetch1;

            else if(state == reg_op)
                  next_state <= fetch1;

            else if(state == auipc)
                  next_state <= fetch1;

            else if(state == br)
                  next_state <= fetch1;

            else if(state == calc_addr_sw)
                  next_state <= str1;

            else if(state == str1) begin
                  if(mem_resp == 1'b0)
                        next_state <= str1;
                  else
                        next_state <= str2;
            end

            else if(state == str2)
                  next_state <= fetch1;

            else
                  next_state <= fetch1;

      end
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    state <= next_state;
end

endmodule : control
