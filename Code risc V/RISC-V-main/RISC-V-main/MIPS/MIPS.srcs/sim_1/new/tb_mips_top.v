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
        $display("=======================================");
        $display("BAT DAU CHAY TESTBENCH KIEM TRA RE NHANH VA BO NHO...");
        
        reset = 1; #15; 
        reset = 0;
        
        // Chờ 150ns (15 chu kỳ) để CPU thực thi đến lệnh j loop
        #150; 

        $display("--- KET QUA TEST ---");

        // 1. Kiểm tra lệnh Tính toán và Ghi bộ nhớ (add, sw)
        // Kết quả 15 phải được lưu ở địa chỉ byte 4 (tức là RAM[1] của data_mem)
        if (dut.data_mem.RAM[1] === 32'd15)
            $display("[PASS] Tinh tong $s2 va ghi vao Data Memory thanh cong (Gia tri: 15).");
        else
            $display("[FAIL] Loi tinh tong hoac ghi bo nho!");

        // 2. Kiểm tra lệnh Load (lw)
        if (dut.rf.rf[19] === 32'd15)
            $display("[PASS] Doc lw vao $s3 thanh cong (Gia tri: 15).");
        else
            $display("[FAIL] Loi doc bo nho lw!");

        // 3. Kiểm tra logic rẽ nhánh (beq)
        // Nếu rẽ nhánh thành công, $s4 (thanh ghi 20) phải bằng 0 do bị nhảy qua.
        // Ngược lại, nếu nó bằng 99 (0x63), nghĩa là beq bị lỗi.
        if (dut.rf.rf[20] === 32'd0 && dut.rf.rf[21] === 32'd42) begin
            $display("[PASS] Lenh beq HOAT DONG CHUAN XAC! Da nhay qua lenh cong 99.");
            $display("[PASS] Thanh ghi $s5 nhan dung gia tri 42.");
        end else begin
            $display("[FAIL] Loi nhanh beq! Mach da chay nham vao lenh cong 99.");
        end

        $display("=======================================\n");
        $finish; 
    end
endmodule