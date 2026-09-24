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

    mux2 #(32) pcjumpmux (
        .d0(pc_next_branch),
        .d1(pc_jump),        
        .s(Jump), 
        .y(pc_next)          
    );

    pc_reg pcreg (.clk(clk), .reset(reset), .pc_next(pc_next), .pc(pc));
    adder pcadd1 (.a(pc), .b(32'd4), .y(pc_plus_4));
    imem inst_mem (.a(pc), .rd(instr));
    
    mux2 #(5) regdstmux (.d0(instr[20:16]), .d1(instr[15:11]), .s(RegDst), .y(write_reg));
    regfile rf (.clk(clk), .we3(RegWrite), .a1(instr[25:21]), .a2(instr[20:16]), .a3(write_reg), .wd3(wd3), .rd1(src_a), .rd2(rd2));
    sign_extend se (.a(instr[15:0]), .y(sign_imm));
    
    mux2 #(32) alusrcmux (.d0(rd2), .d1(sign_imm), .s(ALUSrc), .y(src_b));
    alu alu_inst (.src_a(src_a), .src_b(src_b), .alu_control(ALUControl), .alu_result(alu_result), .zero(zero));
    
    dmem data_mem (.clk(clk), .we(MemWrite), .a(alu_result), .wd(rd2), .rd(read_data));
    mux2 #(32) resmux (.d0(alu_result), .d1(read_data), .s(MemtoReg), .y(wd3));
endmodule

module control_unit (
    input  wire [5:0] Op,          
    input  wire [5:0] Funct,       
    output wire       RegDst,
    output wire       ALUSrc,
    output wire       MemtoReg,
    output wire       RegWrite,
    output wire       MemWrite,
    output wire       Branch,
    output wire       Jump,        
    output wire [2:0] ALUControl
);
    wire [1:0] ALUOp;

    main_decoder md (
        .Op(Op), .RegWrite(RegWrite), .RegDst(RegDst), .ALUSrc(ALUSrc),
        .Branch(Branch), .MemWrite(MemWrite), .MemtoReg(MemtoReg),
        .Jump(Jump), .ALUOp(ALUOp)
    );

    alu_decoder ad (
        .Funct(Funct), .ALUOp(ALUOp), .ALUControl(ALUControl)
    );
endmodule

module main_decoder (
    input  wire [5:0] Op,
    output reg        RegWrite, RegDst, ALUSrc, Branch, MemWrite, MemtoReg, Jump,
    output reg  [1:0] ALUOp
);
    always @(*) begin
        case (Op)
            6'b000000: begin // R-type
                RegWrite = 1; RegDst = 1; ALUSrc = 0; Branch = 0; MemWrite = 0; MemtoReg = 0; Jump = 0; ALUOp = 2'b10;
            end
            6'b100011: begin // lw
                RegWrite = 1; RegDst = 0; ALUSrc = 1; Branch = 0; MemWrite = 0; MemtoReg = 1; Jump = 0; ALUOp = 2'b00;
            end
            6'b101011: begin // sw
                RegWrite = 0; RegDst = 0; ALUSrc = 1; Branch = 0; MemWrite = 1; MemtoReg = 0; Jump = 0; ALUOp = 2'b00;
            end
            6'b000100: begin // beq
                RegWrite = 0; RegDst = 0; ALUSrc = 0; Branch = 1; MemWrite = 0; MemtoReg = 0; Jump = 0; ALUOp = 2'b01;
            end
            6'b001000: begin // addi
                RegWrite = 1; RegDst = 0; ALUSrc = 1; Branch = 0; MemWrite = 0; MemtoReg = 0; Jump = 0; ALUOp = 2'b00;
            end
            6'b000010: begin // j
                RegWrite = 0; RegDst = 0; ALUSrc = 0; Branch = 0; MemWrite = 0; MemtoReg = 0; Jump = 1; ALUOp = 2'b00;
            end
            default: begin 
                RegWrite = 0; RegDst = 0; ALUSrc = 0; Branch = 0; MemWrite = 0; MemtoReg = 0; Jump = 0; ALUOp = 2'b00;
            end
        endcase
    end
endmodule

module alu_decoder (
    input  wire [5:0] Funct,
    input  wire [1:0] ALUOp,
    output reg  [2:0] ALUControl
);
    always @(*) begin
        case (ALUOp)
            2'b00: ALUControl = 3'b010; // add
            2'b01: ALUControl = 3'b110; // sub 
            2'b10: begin                
                case (Funct)
                    6'b100000: ALUControl = 3'b010; // add
                    6'b100010: ALUControl = 3'b110; // sub
                    6'b100100: ALUControl = 3'b000; // and
                    6'b100101: ALUControl = 3'b001; // or
                    6'b101010: ALUControl = 3'b111; // slt
                    default:   ALUControl = 3'bxxx;
                endcase
            end
            default: ALUControl = 3'bxxx;
        endcase
    end
endmodule              

module Branch_Logic (
    input  [31:0] PCPlus4,
    input  [31:0] instr,
    input  [31:0] read_data1,
    input  [31:0] read_data2,
    output [31:0] next_PC
);
    wire [5:0] opcode = instr[31:26];
    wire is_beq = (opcode == 6'b000100);
    wire is_bne = (opcode == 6'b000101);
    wire Zero = (read_data1 == read_data2) ? 1'b1 : 1'b0;
    wire [31:0] SignImm;
    assign SignImm = {{16{instr[15]}}, instr[15:0]};
    wire [31:0] PCBranch;
    assign PCBranch = PCPlus4 + (SignImm << 2);
    wire PCSrc;
    assign PCSrc = (is_beq & Zero) | (is_bne & ~Zero);
    assign next_PC = (PCSrc == 1'b1) ? PCBranch : PCPlus4;
endmodule