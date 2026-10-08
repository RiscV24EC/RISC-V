`timescale 1ns / 1ps

module tb_mips_top();
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
        reset = 1; 
        
        // Mở khóa mạch ở ĐÚNG MỐC 15NS
        #15; 
        reset = 0;
        
        $display("=========================================================");
        $display(" KICH HOAT TINH NANG CÁCH LY CHU KỲ (PIPELINE VISUALIZATION)");
        $display("=========================================================");

        #11; 
        $display("[Time = %0t ns] Chu ky 1 (15-25ns): Lenh addi $16, $0, 10. Thanh ghi $16 = %0d", $time, dut.rf.rf[16]);

        #10; 
        $display("[Time = %0t ns] Chu ky 2 (25-35ns): Lenh addi $17, $0, 5.  Thanh ghi $17 = %0d", $time, dut.rf.rf[17]);

        #10; 
        $display("[Time = %0t ns] Chu ky 3 (35-45ns): Lenh add $18, $16, $17.  Thanh ghi $18 = %0d", $time, dut.rf.rf[18]);

        #10; 
        $display("[Time = %0t ns] Chu ky 4 (45-55ns): Lenh sw $18, 4($0).      Data RAM[1] = %0d", $time, dut.data_mem.RAM[1]);

        #10; 
        $display("[Time = %0t ns] Chu ky 5 (55-65ns): Lenh lw $19, 4($0).      Thanh ghi $19 = %0d", $time, dut.rf.rf[19]);

        #10; 
        $display("[Time = %0t ns] Chu ky 6 (65-75ns): Lenh beq $18, $19, 1.    PC nhay len %0d", $time, dut.pc);

        #10; 
        $display("[Time = %0t ns] Chu ky 7 (75-85ns): Lenh addi $21, $0, 37.   Thanh ghi $21 = %0d", $time, dut.rf.rf[21]);

        #10; 
        $display("[Time = %0t ns] Chu ky 8 (85-95ns): Lenh j loop.             PC chuan bi nhay ve %0d", $time, dut.pc_next);

        #10; 
        $display("[Time = %0t ns] Chu ky 9 (95-105ns): Vong lap vo han.        PC = %0d", $time, dut.pc);

        #20;
        $finish; 
    end
endmodule