`timescale 1ns / 1ps

module mips_top (
    input wire clk,
    input wire reset
);
    wire [31:0] pc, pc_next, pc_plus_4;
    wire [31:0] instr, sign_imm;
    wire [31:0] src_a, src_b, rd2, wd3;
    wire [31:0] alu_result, read_data;
    wire [4:0]  write_reg;
    
    wire RegDst, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, Jump;
    wire [2:0] ALUControl;
    wire zero; 

    wire [31:0] pc_next_branch; 
    wire [31:0] pc_jump;
    assign pc_jump = {pc_plus_4[31:28], instr[25:0], 2'b00};

    control_unit ctrl (
        .reset(reset), 
        .Op(instr[31:26]), 
        .Funct(instr[5:0]), 
        .RegDst(RegDst), 
        .ALUSrc(ALUSrc), 
        .MemtoReg(MemtoReg), 
        .RegWrite(RegWrite), 
        .MemWrite(MemWrite), 
        .Branch(Branch), 
        .Jump(Jump), 
        .ALUControl(ALUControl)
    );

    Branch_Logic branch_unit (
        .PCPlus4(pc_plus_4), 
        .instr(instr),
        .read_data1(src_a), 
        .read_data2(rd2),
        .next_PC(pc_next_branch)
    );

    mux2 #(32) pcjumpmux (.d0(pc_next_branch), .d1(pc_jump), .s(Jump), .y(pc_next));
    pc_reg pcreg (.clk(clk), .reset(reset), .pc_next(pc_next), .pc(pc));
    
    adder pcadd1 (.a(pc), .b(reset ? 32'd0 : 32'd4), .y(pc_plus_4));
    imem inst_mem (.reset(reset), .a(pc), .rd(instr));
    
    mux2 #(5) regdstmux (.d0(instr[20:16]), .d1(instr[15:11]), .s(RegDst), .y(write_reg));
    regfile rf (.clk(clk), .we3(RegWrite), .a1(instr[25:21]), .a2(instr[20:16]), .a3(write_reg), .wd3(wd3), .rd1(src_a), .rd2(rd2));
    sign_extend se (.a(instr[15:0]), .y(sign_imm));
    
    mux2 #(32) alusrcmux (.d0(rd2), .d1(sign_imm), .s(ALUSrc), .y(src_b));
    alu alu_inst (.src_a(src_a), .src_b(src_b), .alu_control(ALUControl), .alu_result(alu_result), .zero(zero));
    
    dmem data_mem (.clk(clk), .we(MemWrite), .a(alu_result), .wd(rd2), .rd(read_data));
    mux2 #(32) resmux (.d0(alu_result), .d1(read_data), .s(MemtoReg), .y(wd3));
endmodule