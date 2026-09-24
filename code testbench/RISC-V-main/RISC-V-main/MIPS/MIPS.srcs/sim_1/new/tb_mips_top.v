`timescale 1ns / 1ps

module tb_mips_ultimate();
    reg clk;
    reg reset;

    mips_top dut (
        .clk(clk),
        .reset(reset)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    initial begin
        $display("=======================================");
        $display("BAT DAU TEST KIN DIEN CHO SO DO MIPS...");
        
        reset = 1; #15; 
        reset = 0;
        
        // Chờ 100ns (10 chu kỳ) để CPU thực thi hết toàn bộ 9 lệnh
        #100; 

        $display("--- KET QUA TEST CÁC KHỐI ---");

        // 1. Kiểm tra Mux MemtoReg, Data Memory và khối lw/sw
        if (dut.data_mem.RAM[5] === 32'd12)
            $display("[PASS] Data Memory + lw/sw + SignExtend hoat dong chuan!");
        else
            $display("[FAIL] Loi truy cap Data Memory! (RAM[5] phai la 12, thuc te la %d)", dut.data_mem.RAM[5]);

        // 2. Kiểm tra bộ Mux PCSrc, cổng AND, Mux RegDst và khối ALU
        if (dut.rf.rf[5] === 32'd8) begin
            $display("[PASS] Khoi dieu khien Branch, PC+4, bo cong PCBranch va ALU hoat dong hoan hao!");
            $display("[PASS] Lenh beq da NHAY THANH CONG qua lenh so 7.");
        end else begin
            $display("[FAIL] Mach Branch loi! Lệnh beq không nhảy đúng. ($5 phải là 8, thực tế là %d)", dut.rf.rf[5]);
        end

        $display("=======================================\n");
        $finish; 
    end
endmodule