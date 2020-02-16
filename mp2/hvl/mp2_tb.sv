module mp2_tb;

timeunit 1ns;
timeprecision 1ns;


/*********************** Variable/Interface Declarations *********************/
logic commit;
assign commit = dut.cpu.load_pc;
logic [63:0] order;
initial order = 0;
tb_itf itf();
always @(posedge itf.clk iff commit) order <= order + 1;
int timeout = 100000000;   // Feel Free to adjust the timeout value
assign itf.registers = dut.cpu.datapath.regfile.data;
assign itf.halt = dut.cpu.load_pc &
                  (dut.cpu.datapath.pc_out == dut.cpu.datapath.pcmux_out);
/*****************************************************************************/

/************************* Error Halting Conditions **************************/
// Stop simulation on error detection
always @(itf.errcode iff (itf.errcode != 0)) begin
    repeat (30) @(posedge itf.clk);
    $display("TOP: Halting on Non-Zero Errorcode");
    $finish;
end

// Stop simulation on memory error detection
always @(posedge itf.clk iff (itf.sm_error || itf.pm_error)) begin
    $display("TOP: Halting on %s Memory Error",
            itf.sm_error && itf.pm_error ? "Shadow and Physical" :
            itf.sm_error ? "Shadow" : "Physical");
end

// Stop simulation on timeout (stall detection), halt
always @(posedge itf.clk) begin
    if (itf.halt)
        $finish;
    if (timeout == 0) begin
        $display("TOP: Timed out");
        $finish;
    end
    timeout <= timeout - 1;
end

// Simulataneous Memory Read and Write
always @(posedge itf.clk iff (itf.mem_read && itf.mem_write))
    $error("@%0t TOP: Simultaneous memory read and write detected", $time);

/*****************************************************************************/
mp2 dut(
    .clk              (itf.clk & ~itf.mon_rst),
    .pmem_resp        (itf.mem_resp),
    .pmem_rdata       (itf.mem_rdata),
    .pmem_read        (itf.mem_read),
    .pmem_write       (itf.mem_write),
    .pmem_address     (itf.mem_address),
    .pmem_wdata       (itf.mem_wdata)
);

// Feel free to change shadow_memory signals --- autograder
// Does not use shadow_memory
shadow_memory sm (
    .clk     (itf.clk),
    .valid   (dut.cpu.load_pc),
    .rmask   (dut.cpu.control.rmask),
    .wmask   (dut.cpu.control.wmask),
    .addr    (dut.cpu.datapath.mem_address), // MAR Output
    .rdata   (dut.cpu.datapath.mdrreg_out),
    .wdata   (dut.cpu.datapath.mem_wdata),
    .pc_rdata(dut.cpu.datapath.pc_out),
    .insn    (dut.cpu.datapath.IR.data),
    .error   (itf.sm_error)
);

memory memory(
    .clk     (itf.clk),
    .read    (itf.mem_read),
    .write   (itf.mem_write),
    .address (itf.mem_address),
    .wdata   (itf.mem_wdata),
    .resp    (itf.mem_resp),
    .rdata   (itf.mem_rdata),
    .error   (itf.pm_error)
);

// Do not change monitor signals -- autograder uses monitor
riscv_formal_monitor_rv32i monitor(
    .clock (itf.clk),
    .reset (itf.mon_rst),
    .rvfi_valid (commit),
    .rvfi_order (order),
    .rvfi_insn (dut.cpu.datapath.IR.data),
    .rvfi_trap(dut.cpu.control.trap),
    .rvfi_halt(itf.halt),
    .rvfi_intr(1'b0),
	 .rvfi_mode(2'b00),
    .rvfi_rs1_addr(dut.cpu.control.rs1_addr),
    .rvfi_rs2_addr(dut.cpu.control.rs2_addr),
    .rvfi_rs1_rdata(monitor.rvfi_rs1_addr ? dut.cpu.datapath.rs1_out : 0),
    .rvfi_rs2_rdata(monitor.rvfi_rs2_addr ? dut.cpu.datapath.rs2_out : 0),
    .rvfi_rd_addr(dut.cpu.load_regfile ? dut.cpu.datapath.rd : 5'h0),
    .rvfi_rd_wdata(monitor.rvfi_rd_addr ? dut.cpu.datapath.regfilemux_out : 0),
    .rvfi_pc_rdata(dut.cpu.datapath.pc_out),
    .rvfi_pc_wdata(dut.cpu.datapath.pcmux_out),
    .rvfi_mem_addr(dut.mem_address & 32'hFFFFFFFC),
    .rvfi_mem_rmask(dut.cpu.control.rmask << dut.mem_address[1:0]),
    .rvfi_mem_wmask(dut.mem_byte_enable),
    .rvfi_mem_rdata(dut.cpu.datapath.mdrreg_out),
    .rvfi_mem_wdata(dut.cpu.datapath.mem_wdata),
	 .rvfi_mem_extamo(1'b0),
    .errcode(itf.errcode)
);


endmodule : mp2_tb
