`timescale 1ns / 1ps

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