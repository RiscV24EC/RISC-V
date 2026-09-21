`timescale 1ns / 1ps

module tb_mips_top();
    reg clk;
    reg reset;

    // Gọi (instantiate) bo mạch chủ mips_top ra để test
    mips_top dut (
        .clk(clk),
        .reset(reset)
    );

    // Cách tạo xung nhịp an toàn nhất cho Vivado
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Chu kỳ 10ns (đảo trạng thái mỗi 5ns)
    end

    initial begin
        // Trạng thái ban đầu: Kích hoạt reset để đưa PC về 0
        reset = 1; 
        
        // Đợi 10ns (1 chu kỳ), sau đó nhả reset ra để mạch bắt đầu hoạt động
        #10;
        reset = 0;
        
        // Cho mạch chạy trong 300ns để đảm bảo chạy qua hết tất cả các lệnh
        #300; 
        $finish; // Dừng mô phỏng
    end
endmodule