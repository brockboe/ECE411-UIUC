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
    output control_sig ctrl_out
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
                //lh, lhu: rmask = 4'bXXXX /* Modify for MP1 Final */ ;
                //lb, lbu: rmask = 4'bXXXX /* Modify for MP1 Final */ ;
                default: trap = 1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                rv32i_types::sw: wmask = 4'b1111;
                //sh: wmask = 4'bXXXX /* Modify for MP1 Final */ ;
                //sb: wmask = 4'bXXXX /* Modify for MP1 Final */ ;
                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end
/*****************************************************************************/

enum int unsigned {
    /* List of states */
    fetch1        = 0,
    fetch2        = 1,
    fetch3        = 2,
    decode        = 3,
    imm           = 4,
    lui           = 5,
    calc_addr     = 6,
    ld1           = 7,
    ld2           = 8,
    st1           = 9,
    st2           = 10,
    auipc         = 11,
    br            = 12
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
end

always_comb
begin : next_state_logic
      /* Next state information and conditions (if any)
      * for transitioning between states */
      if(rst) begin
            next_state <= fetch1;
      end else begin

            if(state == fetch1) begin
                  next_state <= fetch2;
            end

            else if(state == fetch2) begin
                  if(mem_resp == 1'b0)
                        next_state <= fetch2;
                  else
                        next_state <= fetch3;
            end

            else if(state == fetch3) begin
                  next_state <= decode;
            end

            else begin
                  next_state <= fetch1;
            end

      end
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    state <= next_state;
end

endmodule : control
