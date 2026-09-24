`timescale 1ns / 1ps

module control_unit (
    input  wire [5:0] Op,          // Instr[31:26]
    input  wire [5:0] Funct,       // Instr[5:0]
    output wire       RegDst,
    output wire       ALUSrc,
    output wire       MemtoReg,
    output wire       RegWrite,
    output wire       MemWrite,
    output wire       Branch,
    output wire       Jump,        // Tín hiệu mới cho lệnh J-type
    output wire [2:0] ALUControl
);

    wire [1:0] ALUOp;

    // Tầng 1: Main Decoder
    main_decoder md (
        .Op(Op),
        .RegWrite(RegWrite),
        .RegDst(RegDst),
        .ALUSrc(ALUSrc),
        .Branch(Branch),
        .MemWrite(MemWrite),
        .MemtoReg(MemtoReg),
        .Jump(Jump),
        .ALUOp(ALUOp)
    );

    // Tầng 2: ALU Decoder
    alu_decoder ad (
        .Funct(Funct),
        .ALUOp(ALUOp),
        .ALUControl(ALUControl)
    );

endmodule

// ==========================================
// Module Main Decoder
// ==========================================
module main_decoder (
    input  wire [5:0] Op,
    output reg        RegWrite,
    output reg        RegDst,
    output reg        ALUSrc,
    output reg        Branch,
    output reg        MemWrite,
    output reg        MemtoReg,
    output reg        Jump,
    output reg  [1:0] ALUOp
);

    always @(*) begin
        case (Op)
            6'b000000: begin // R-type (add, sub, and, or, slt)
                RegWrite = 1'b1;
                RegDst   = 1'b1; // Chọn rd (Instr[15:11])
                ALUSrc   = 1'b0; // Chọn RD2
                Branch   = 1'b0;
                MemWrite = 1'b0;
                MemtoReg = 1'b0; // Lấy ALUResult
                Jump     = 1'b0;
                ALUOp    = 2'b10;
            end
            
            6'b100011: begin // lw (Load Word - I-type)
                RegWrite = 1'b1;
                RegDst   = 1'b0; // Chọn rt (Instr[20:16])
                ALUSrc   = 1'b1; // Chọn SignImm
                Branch   = 1'b0;
                MemWrite = 1'b0;
                MemtoReg = 1'b1; // Lấy ReadData từ RAM
                Jump     = 1'b0;
                ALUOp    = 2'b00; // Phép cộng địa chỉ
            end
            
            6'b101011: begin // sw (Store Word - I-type)
                RegWrite = 1'b0;
                RegDst   = 1'b0; // Don't care
                ALUSrc   = 1'b1; // Chọn SignImm
                Branch   = 1'b0;
                MemWrite = 1'b1; // Ghi RAM
                MemtoReg = 1'b0; // Don't care
                Jump     = 1'b0;
                ALUOp    = 2'b00; // Phép cộng địa chỉ
            end
            
            6'b000100: begin // beq (Branch if Equal - I-type)
                RegWrite = 1'b0;
                RegDst   = 1'b0; // Don't care
                ALUSrc   = 1'b0; // So sánh hai thanh ghi
                Branch   = 1'b1;
                MemWrite = 1'b0;
                MemtoReg = 1'b0; // Don't care
                Jump     = 1'b0;
                ALUOp    = 2'b01; // Phép trừ so sánh
            end

            // ================= MỞ RỘNG THÊM =================
            6'b001000: begin // addi (Add Immediate - I-type ALU)
                RegWrite = 1'b1; // Ghi kết quả vào thanh ghi
                RegDst   = 1'b0; // Đích là rt (Instr[20:16])
                ALUSrc   = 1'b1; // Toán hạng 2 lấy SignImm
                Branch   = 1'b0;
                MemWrite = 1'b0;
                MemtoReg = 1'b0; // Lấy kết quả từ ALU
                Jump     = 1'b0;
                ALUOp    = 2'b00; // Thực hiện phép cộng
            end

            6'b000010: begin // j (Unconditional Jump - J-type)
                RegWrite = 1'b0;
                RegDst   = 1'b0; // Don't care
                ALUSrc   = 1'b0; // Don't care
                Branch   = 1'b0;
                MemWrite = 1'b0;
                MemtoReg = 1'b0; // Don't care
                Jump     = 1'b1; // Kích hoạt nhảy không điều kiện
                ALUOp    = 2'b00; // Don't care
            end
            // ===============================================

            default: begin // Giá trị mặc định khi lệnh không hợp lệ
                RegWrite = 1'b0;
                RegDst   = 1'b0;
                ALUSrc   = 1'b0;
                Branch   = 1'b0;
                MemWrite = 1'b0;
                MemtoReg = 1'b0;
                Jump     = 1'b0;
                ALUOp    = 2'b00;
            end
        endcase
    end

endmodule

// ==========================================
// Module ALU Decoder
// ==========================================
module alu_decoder (
    input  wire [5:0] Funct,
    input  wire [1:0] ALUOp,
    output reg  [2:0] ALUControl
);

    always @(*) begin
        case (ALUOp)
            2'b00: ALUControl = 3'b010; // add (dùng cho lw, sw, addi)
            2'b01: ALUControl = 3'b110; // sub (dùng cho beq)
            2'b10: begin                // Lệnh R-type, tra cứu Funct
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