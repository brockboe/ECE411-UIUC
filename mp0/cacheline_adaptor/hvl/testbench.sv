`include "hdl/cacheline_adaptor.sv"
`define LOG $error("%s", s); $fdisplay(fd, "%s", s); $fdisplay(lfd, "%s", s)
module testbench;
    string s;
    int fd, lfd;

    bit clk;
    always #5 clk = (clk === 1'b0);
    bit reset_n, read_i, write_i, resp_o, read_o, write_o, resp_i;
    bit [255:0] line_i, line_o;
    bit [63:0] burst_i, burst_o;
    bit [31:0] address_i, address_o;

    cacheline_adaptor dut(.*);

    default clocking cb @(posedge clk);
        input line_o, resp_o, burst_o, address_o, read_o, write_o;
        output reset_n, line_i, address_i, read_i, write_i, burst_i, resp_i;
    endclocking

    initial begin
        // $monitor("time: %0t; ", $time,
        //          "dut.state.macro: %s; ", dut.state.macro.name(),
        //          "cb.read_o: %1b; ", cb.read_o,
        //          "cb.write_o: %1b; ", cb.write_o,
        //          "read_i: %1b; ", read_i,
        //          "write_i: %1b; ", write_i,
        //          "dut.write_i: %1b; ", dut.write_i,
        //          "{read_i, write_i}: %2b; ", {dut.read_i, dut.write_i});
        fd = $fopen("./student_log.txt", "w");
        lfd = $fopen("./log.txt", "w");
        if (fd == 0 || lfd == 0) begin
            $error("%s %0d: Unable to open log file(s)",
                        `__FILE__, `__LINE__);
            $exit;
        end
    end

    final begin
        $fclose(fd);
        $fclose(lfd);
    end

    task reset;
        cb.read_i <= 1'b0;
        cb.write_i <= 1'b0;
        cb.reset_n <= 1'b0;
        cb.resp_i <= 1'b0;
        ##10;
        assert((cb.read_o == 1'b0) && cb.write_o == 1'b0) else begin
            $sformat(s, "@%0t TB: memory access during reset", $time);
            `LOG;
        end
        cb.reset_n <= 1'b1;
        ##10;
    endtask

    task read_test;
        static integer it;
        static bit [255:0] readline;
        static bit [4:0] delay;
        @(cb iff ~(cb.read_o | cb.write_o));
        cb.read_i <= 1'b1;
        cb.write_i <= 1'b0;
        cb.reset_n <= 1'b1;
        cb.address_i <= $urandom;
        for (it = 0; it < 8; ++it) begin
            readline[32*it +: 32] = $urandom;
        end
        delay = $urandom;
        @(cb iff cb.read_o);
        repeat (delay) begin
            assert(cb.address_o == address_i) else begin
                $sformat(s, "@%0t TB: mismatch in read addresses", $time);
                `LOG;
            end
            ##1;
        end
        for (it = 0; it < 4; ++it) begin
            cb.resp_i <= 1'b1;
            cb.burst_i <= readline[64*it +: 64];
            cb.read_i <= 1'b0;
            ##1;
        end
        cb.resp_i <= 1'b0;
        @(cb iff cb.resp_o);
        repeat (5) begin
            assert(cb.line_o == readline) else begin
                $sformat(s, "@%0t TB: read / expected\n\t%x\n\t%x", $time,
                    cb.line_o, readline);
                `LOG;
            end
        end
    endtask : read_test

    bit [255:0] writeline;
    task write_test;
        static integer it;
        static bit [4:0] delay;
        @(cb iff ~(cb.read_o | cb.write_o));
        cb.read_i <= 1'b0;
        cb.write_i <= 1'b1;
        cb.reset_n <= 1'b1;
        cb.address_i <= $urandom;
        for (it = 0; it < 8; ++it) begin
            line_i[32*it +: 32] = $urandom;
        end
        delay = $urandom;
        @(cb iff cb.write_o);
        for (int it = 0; it < delay; ++it) begin
            assert(cb.address_o == address_i) else begin
                $sformat(s, "@%0t TB: mismatch in read addresses", $time);
                `LOG;
            end
            ##1;
        end
        ##1 cb.resp_i <= 1'b1;
        for (it = 0; it < 4; ++it) begin
            ##1;
            cb.resp_i <= 1'b1;
            cb.write_i <= 1'b0;
            writeline[64*it +: 64] <= cb.burst_o;
        end
        cb.resp_i <= 1'b0;
        @(cb iff cb.resp_o);
        assert(writeline == line_i) else begin
            $sformat(s, "@%0t TB: writeline / expected\n\t%x\n\t%x", $time,
                writeline, line_i);
            `LOG;
        end
    endtask : write_test

    always @(cb iff cb.write_o && cb.read_o && reset_n) begin
        $sformat(s, "@%0t TB: Simultaneous read and write to mem", $time);
        `LOG;
    end

    always @(cb iff write_i && read_i) begin
        $sformat(s, "@%0t TB: Simultaneous read and write to adaptor", $time);
        `LOG;
        $fatal("Fatal Error");
    end

    initial begin
        reset();
        $display("Starting Read Tests");
        repeat (50) read_test();
        $display("Read Tests Complete");
        $display("Starting Write Tests");
        repeat (50) write_test();
        $display("Write Tests Complete");
        $finish;
    end

    initial begin : timeout
        ##50000;
        $sformat(s, "@%0t TB: timeout", $time);
        `LOG;
        $finish;
    end

endmodule : testbench
