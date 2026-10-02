`timescale 1ns / 1ps

module tb_mips_top();
    reg clk;
    reg reset;

    // Gọi CPU
    mips_top dut (
        .clk(clk),
        .reset(reset)
    );

    // ========================================================
    // TẠO CLOCK: 10ns / chu kỳ (5ns LOW, 5ns HIGH)
    // Sườn lên rơi đúng vào các mốc: 5ns, 15ns, 25ns, 35ns...
    // ========================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // ========================================================
    // KỊCH BẢN THỜI GIAN VÀ BÁO CÁO 9 CHU KỲ
    // ========================================================
    initial begin
        // Reset hệ thống
        reset = 1; 
        
        // GIỮ RESET ĐẾN 16ns
        // Sườn lên 15ns bị bỏ qua do reset đang = 1. PC được ép về 0.
        // Tại 16ns, tắt reset. CPU bắt đầu 5 giai đoạn thực thi (IF->ID->EX->MEM->WB) của lệnh 1.
        // Mọi thứ hoàn tất vào đúng sườn lên 25ns!
        #16; 
        reset = 0;
        
        $display("=========================================================");
        $display(" BAT DAU MOP HONG 9 CHU KY (Moi chu ky 10ns)");
        $display(" 5 giai doan IF, ID, EX, MEM, WB hoan tat trong moi 10ns");
        $display("=========================================================");

        // --- ĐO KIỂM SAU MỖI CHU KỲ ---
        
        #10; // Đợi đến 26ns (Sau khi kết thúc Chu kỳ 1: 15ns-25ns)
        $display("[Time = %0t ns] Chu ky 1 (15-25ns) xong: Lenh addi $16, $0, 10. Thanh ghi $16 = %0d", $time, dut.rf.rf[16]);

        #10; // Đợi đến 36ns (Sau khi kết thúc Chu kỳ 2: 25ns-35ns)
        $display("[Time = %0t ns] Chu ky 2 (25-35ns) xong: Lenh addi $17, $0, 5.  Thanh ghi $17 = %0d", $time, dut.rf.rf[17]);

        #10; // 46ns
        $display("[Time = %0t ns] Chu ky 3 (35-45ns) xong: Lenh add $18, $16, $17.  Thanh ghi $18 = %0d", $time, dut.rf.rf[18]);

        #10; // 56ns
        $display("[Time = %0t ns] Chu ky 4 (45-55ns) xong: Lenh sw $18, 4($0).      Data RAM[1] = %0d", $time, dut.data_mem.RAM[1]);

        #10; // 66ns
        $display("[Time = %0t ns] Chu ky 5 (55-65ns) xong: Lenh lw $19, 4($0).      Thanh ghi $19 = %0d", $time, dut.rf.rf[19]);

        #10; // 76ns
        $display("[Time = %0t ns] Chu ky 6 (65-75ns) xong: Lenh beq $18, $19, 1.    PC nhay len %0d (0x%0h)", $time, dut.pc, dut.pc);

        #10; // 86ns
        $display("[Time = %0t ns] Chu ky 7 (75-85ns) xong: Lenh addi $21, $0, 42.   Thanh ghi $21 = %0d (Bo qua lenh PC=24)", $time, dut.rf.rf[21]);

        #10; // 96ns
        $display("[Time = %0t ns] Chu ky 8 (85-95ns) xong: Lenh j loop.             PC nhay ve %0d (0x%0h)", $time, dut.pc, dut.pc);

        #10; // 106ns
        $display("[Time = %0t ns] Chu ky 9 (95-105ns) xong: Vong lap vo han.        PC giu nguyen %0d (0x%0h)", $time, dut.pc, dut.pc);

        // Chờ thêm một chút rồi kết thúc
        #20;
        $display("=========================================================");
        $display("--- TONG KET CHUNG ---");
        if (dut.data_mem.RAM[1] === 32'd15 && dut.rf.rf[19] === 32'd15 && dut.rf.rf[21] === 32'd42 && dut.rf.rf[20] === 32'd0)
            $display("[PASS] TAT CA 9 CHU KY DA HOAT DONG CHUAN XAC THEO KHUNG 10NS!");
        else
            $display("[FAIL] Co loi xay ra.");
        $display("=========================================================\n");
        
        $finish; 
    end
endmodule