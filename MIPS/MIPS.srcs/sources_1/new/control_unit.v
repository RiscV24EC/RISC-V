`timescale 1ns / 1ps

module control_unit (
    input  wire [5:0] Op,          
    input  wire [5:0] Funct,       
    output wire       RegDst,
    output wire       ALUSrc,
    output wire       MemtoReg,
    output wire       RegWrite,
    output wire       MemWrite,
    output wire       Branch,
    output wire       Jump,        // BỔ SUNG: Tín hiệu nhảy J-type
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
            6'b001000: begin // addi (BỔ SUNG)
                RegWrite = 1; RegDst = 0; ALUSrc = 1; Branch = 0; MemWrite = 0; MemtoReg = 0; Jump = 0; ALUOp = 2'b00;
            end
            6'b000010: begin // j (BỔ SUNG)
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
            2'b00: ALUControl = 3'b010; // add (cho lw, sw, addi)
            2'b01: ALUControl = 3'b110; // sub (cho beq)
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