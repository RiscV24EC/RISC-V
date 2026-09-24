`timescale 1ns / 1ps

module mux2 #(parameter WIDTH = 32) (
    input  [WIDTH-1:0] d0,
    input  [WIDTH-1:0] d1,
    input              s,
    output [WIDTH-1:0] y
);
    assign y = s ? d1 : d0;
endmodule

module adder (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] y
);
    assign y = a + b;
endmodule

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

module sign_extend (
    input  [15:0] a,
    output [31:0] y
);
    assign y = {{16{a[15]}}, a};
endmodule

module regfile (
    input         clk,
    input         we3,
    input  [4:0]  a1, a2, a3,
    input  [31:0] wd3,
    output [31:0] rd1, rd2
);
    reg [31:0] rf[31:0];
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            rf[i] = 32'b0;
        end
    end
    assign rd1 = (a1 != 0) ? rf[a1] : 32'b0;
    assign rd2 = (a2 != 0) ? rf[a2] : 32'b0;
    always @(posedge clk) begin
        if (we3) rf[a3] <= wd3;
    end
endmodule

module alu (
    input  [31:0] src_a,
    input  [31:0] src_b,
    input  [2:0]  alu_control,
    output reg [31:0] alu_result,
    output        zero
);
    always @(*) begin
        case (alu_control)
            3'b010: alu_result = src_a + src_b;      
            3'b110: alu_result = src_a - src_b;      
            3'b000: alu_result = src_a & src_b;      
            3'b001: alu_result = src_a | src_b;      
            3'b111: alu_result = (src_a < src_b) ? 1 : 0; 
            default: alu_result = 32'b0;
        endcase
    end
    assign zero = (alu_result == 32'b0);
endmodule

module dmem (
    input         clk,
    input         we,
    input  [31:0] a,
    input  [31:0] wd,
    output [31:0] rd
);
    reg [31:0] RAM [63:0];
    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            RAM[i] = 32'b0;
        end
    end
    assign rd = RAM[a[31:2]];
    always @(posedge clk) begin
        if (we) RAM[a[31:2]] <= wd;
    end
endmodule

module imem (
    input  [31:0] a,
    output [31:0] rd
);
    reg [31:0] RAM [63:0];
    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            RAM[i] = 32'b0;
        end
        // Kịch bản của bạn: addi, addi, add, sw, lw, beq, addi (skip), addi, j loop
        RAM[0] = 32'h2010000a; 
        RAM[1] = 32'h20110005; 
        RAM[2] = 32'h02119020; 
        RAM[3] = 32'hac120004; 
        RAM[4] = 32'h8c130004; 
        RAM[5] = 32'h12530001; 
        RAM[6] = 32'h20140063; 
        RAM[7] = 32'h2015002a; 
        RAM[8] = 32'h08000008; 
    end
    assign rd = RAM[a[31:2]]; 
endmodule