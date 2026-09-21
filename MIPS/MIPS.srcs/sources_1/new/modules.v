`timescale 1ns / 1ps

// ==========================================
// 1. MUX 2 sang 1
// ==========================================
module mux2 #(parameter WIDTH = 32) (
    input  [WIDTH-1:0] d0,
    input  [WIDTH-1:0] d1,
    input              s,
    output [WIDTH-1:0] y
);
    assign y = s ? d1 : d0;
endmodule

// ==========================================
// 2. Bộ cộng (Adder)
// ==========================================
module adder (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] y
);
    assign y = a + b;
endmodule

// ==========================================
// 3. Thanh ghi PC
// ==========================================
module pc_reg (
    input             clk,
    input             reset,
    input      [31:0] pc_next,
    output reg [31:0] pc
);
    always @(posedge clk or posedge reset) begin
        if (reset) pc <= 32'b0;
        else       pc <= pc_next;
    end
endmodule

// ==========================================
// 4. Mở rộng dấu (Sign Extend)
// ==========================================
module sign_extend (
    input  [15:0] a,
    output [31:0] y
);
    assign y = {{16{a[15]}}, a};
endmodule

// ==========================================
// 5. Tập thanh ghi (Register File) - ĐÃ SỬA LỖI ĐỎ (X)
// ==========================================
module regfile (
    input         clk,
    input         we3,
    input  [4:0]  a1, a2, a3,
    input  [31:0] wd3,
    output [31:0] rd1, rd2
);
    reg [31:0] rf[31:0];
    
    // Khởi tạo toàn bộ 32 thanh ghi bằng 0 để xóa dải màu đỏ (Unknown - X)
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            rf[i] = 32'b0;
        end
    end

    // Đọc dữ liệu (Thanh ghi 0 luôn bằng 0)
    assign rd1 = (a1 != 0) ? rf[a1] : 32'b0;
    assign rd2 = (a2 != 0) ? rf[a2] : 32'b0;
    
    // Ghi dữ liệu khi có sườn lên của xung nhịp
    always @(posedge clk) begin
        if (we3) rf[a3] <= wd3;
    end
endmodule

// ==========================================
// 6. Khối ALU
// ==========================================
module alu (
    input  [31:0] src_a,
    input  [31:0] src_b,
    input  [2:0]  alu_control,
    output reg [31:0] alu_result,
    output        zero
);
    always @(*) begin
        case (alu_control)
            3'b010: alu_result = src_a + src_b;      // ADD
            3'b110: alu_result = src_a - src_b;      // SUB
            3'b000: alu_result = src_a & src_b;      // AND
            3'b001: alu_result = src_a | src_b;      // OR
            3'b111: alu_result = (src_a < src_b) ? 1 : 0; // SLT
            default: alu_result = 32'b0;
        endcase
    end
    assign zero = (alu_result == 32'b0);
endmodule

// ==========================================
// 7. Bộ nhớ Dữ liệu (Data Memory)
// ==========================================
module dmem (
    input         clk,
    input         we,
    input  [31:0] a,
    input  [31:0] wd,
    output [31:0] rd
);
    reg [31:0] RAM [63:0];
    assign rd = RAM[a[31:2]];
    
    always @(posedge clk) begin
        if (we) RAM[a[31:2]] <= wd;
    end
endmodule

// ==========================================
// 8. Bộ nhớ Lệnh (Instruction Memory)
// ==========================================
module imem (
    input  [31:0] a,
    output [31:0] rd
);
    reg [31:0] RAM [63:0];
    
    // Nạp sẵn chương trình hợp ngữ (Assembly) của bạn
    initial begin
        RAM[0] = 32'h2010000a; // addi $s0, $zero, 10
        RAM[1] = 32'h20110005; // addi $s1, $zero, 5
        RAM[2] = 32'h02119020; // add  $s2, $s0, $s1
        RAM[3] = 32'hac120004; // sw   $s2, 4($zero)
        RAM[4] = 32'h8c130004; // lw   $s3, 4($zero)
        RAM[5] = 32'h12530001; // beq  $s2, $s3, skip
        RAM[6] = 32'h20140063; // addi $s4, $zero, 99
        RAM[7] = 32'h2015002a; // skip: addi $s5, $zero, 42
        RAM[8] = 32'h08000008; // loop: j loop
    end
    
    assign rd = RAM[a[31:2]]; 
endmodule