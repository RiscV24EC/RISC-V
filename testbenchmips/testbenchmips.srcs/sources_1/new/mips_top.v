`timescale 1ns / 1ps

// ==========================================
// 1. TOP MODULE
// ==========================================
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

    // Gọi Bộ Não
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

    // Tính toán rẽ nhánh
    Branch_Logic branch_unit (
        .PCPlus4(pc_plus_4), 
        .instr(instr),
        .read_data1(src_a), 
        .read_data2(rd2),
        .next_PC(pc_next_branch)
    );

    // Gọi Chân tay (Datapath & Memory)
    mux2 #(32) pcjumpmux (.d0(pc_next_branch), .d1(pc_jump), .s(Jump), .y(pc_next));
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

// ==========================================
// 2. CONTROL UNIT VÀ BRANCH LOGIC
// ==========================================
module control_unit (
    input  wire [5:0] Op,          
    input  wire [5:0] Funct,       
    output wire       RegDst, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, Jump,        
    output wire [2:0] ALUControl
);
    wire [1:0] ALUOp;
    main_decoder md (.Op(Op), .RegWrite(RegWrite), .RegDst(RegDst), .ALUSrc(ALUSrc), .Branch(Branch), .MemWrite(MemWrite), .MemtoReg(MemtoReg), .Jump(Jump), .ALUOp(ALUOp));
    alu_decoder ad (.Funct(Funct), .ALUOp(ALUOp), .ALUControl(ALUControl));
endmodule

module main_decoder (
    input  wire [5:0] Op,
    output reg        RegWrite, RegDst, ALUSrc, Branch, MemWrite, MemtoReg, Jump,
    output reg  [1:0] ALUOp
);
    always @(*) begin
        case (Op)
            6'b000000: begin RegWrite=1; RegDst=1; ALUSrc=0; Branch=0; MemWrite=0; MemtoReg=0; Jump=0; ALUOp=2'b10; end // R-type
            6'b100011: begin RegWrite=1; RegDst=0; ALUSrc=1; Branch=0; MemWrite=0; MemtoReg=1; Jump=0; ALUOp=2'b00; end // lw
            6'b101011: begin RegWrite=0; RegDst=0; ALUSrc=1; Branch=0; MemWrite=1; MemtoReg=0; Jump=0; ALUOp=2'b00; end // sw
            6'b000100: begin RegWrite=0; RegDst=0; ALUSrc=0; Branch=1; MemWrite=0; MemtoReg=0; Jump=0; ALUOp=2'b01; end // beq
            6'b001000: begin RegWrite=1; RegDst=0; ALUSrc=1; Branch=0; MemWrite=0; MemtoReg=0; Jump=0; ALUOp=2'b00; end // addi
            6'b000010: begin RegWrite=0; RegDst=0; ALUSrc=0; Branch=0; MemWrite=0; MemtoReg=0; Jump=1; ALUOp=2'b00; end // j
            default:   begin RegWrite=0; RegDst=0; ALUSrc=0; Branch=0; MemWrite=0; MemtoReg=0; Jump=0; ALUOp=2'b00; end
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
            2'b10: case (Funct)
                    6'b100000: ALUControl = 3'b010; // add
                    6'b100010: ALUControl = 3'b110; // sub
                    6'b100100: ALUControl = 3'b000; // and
                    6'b100101: ALUControl = 3'b001; // or
                    6'b101010: ALUControl = 3'b111; // slt
                    default:   ALUControl = 3'bxxx;
                   endcase
            default: ALUControl = 3'bxxx;
        endcase
    end
endmodule              

module Branch_Logic (
    input  [31:0] PCPlus4, instr, read_data1, read_data2,
    output [31:0] next_PC
);
    wire [5:0] opcode = instr[31:26];
    wire is_beq = (opcode == 6'b000100);
    wire is_bne = (opcode == 6'b000101);
    wire Zero = (read_data1 == read_data2) ? 1'b1 : 1'b0;
    wire [31:0] SignImm = {{16{instr[15]}}, instr[15:0]};
    wire [31:0] PCBranch = PCPlus4 + (SignImm << 2);
    wire PCSrc = (is_beq & Zero) | (is_bne & ~Zero);
    assign next_PC = (PCSrc == 1'b1) ? PCBranch : PCPlus4;
endmodule 

// ==========================================
// 3. DATAPATH VÀ BỘ NHỚ
// ==========================================
module mux2 #(parameter WIDTH = 32) (input [WIDTH-1:0] d0, d1, input s, output [WIDTH-1:0] y);
    assign y = s ? d1 : d0;
endmodule

module adder (input [31:0] a, b, output [31:0] y);
    assign y = a + b;
endmodule

module pc_reg (input clk, reset, input [31:0] pc_next, output reg [31:0] pc);
    always @(posedge clk or posedge reset) begin
        if (reset) pc <= 32'b0;
        else       pc <= pc_next;
    end
endmodule

module sign_extend (input [15:0] a, output [31:0] y);
    assign y = {{16{a[15]}}, a};
endmodule

module regfile (
    input clk, we3, input [4:0] a1, a2, a3, input [31:0] wd3, output [31:0] rd1, rd2
);
    reg [31:0] rf[31:0];
    integer i;
    initial begin for (i=0; i<32; i=i+1) rf[i] = 32'b0; end
    assign rd1 = (a1 != 0) ? rf[a1] : 32'b0;
    assign rd2 = (a2 != 0) ? rf[a2] : 32'b0;
    always @(posedge clk) begin if (we3) rf[a3] <= wd3; end
endmodule

module alu (
    input [31:0] src_a, src_b, input [2:0] alu_control, output reg [31:0] alu_result, output zero
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

module dmem (input clk, we, input [31:0] a, wd, output [31:0] rd);
    reg [31:0] RAM [63:0];
    integer i;
    initial begin for (i=0; i<64; i=i+1) RAM[i] = 32'b0; end
    assign rd = RAM[a[31:2]];
    always @(posedge clk) begin if (we) RAM[a[31:2]] <= wd; end
endmodule

module imem (input [31:0] a, output [31:0] rd);
    reg [31:0] RAM [63:0];
    integer i;
    initial begin
        for (i=0; i<64; i=i+1) RAM[i] = 32'b0;
        RAM[0] = 32'h2010000a; // 1. addi $16, $0, 10
        RAM[1] = 32'h20110005; // 2. addi $17, $0, 5
        RAM[2] = 32'h02119020; // 3. add  $18, $16, $17
        RAM[3] = 32'hac120004; // 4. sw   $18, 4($0)
        RAM[4] = 32'h8c130004; // 5. lw   $19, 4($0)
        RAM[5] = 32'h12530001; // 6. beq  $18, $19, 1
        RAM[6] = 32'h20140063; // 7. addi $20, $0, 99 (skip)
        RAM[7] = 32'h2015002a; // 8. addi $21, $0, 42
        RAM[8] = 32'h08000008; // 9. j loop
    end
    assign rd = RAM[a[31:2]]; 
endmodule