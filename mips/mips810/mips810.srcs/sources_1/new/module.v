`timescale 1ns / 1ps

// ===============================================
// KỸ THUẬT DELAY CÁCH LY CHU KỲ:
// Mỗi khối sẽ lập tức xả về 0 khi nhận tín hiệu mới (đầu chu kỳ), 
// sau đó mới xuất kết quả sau một khoảng Delay nhất định.
// ===============================================

module mux2 #(parameter WIDTH = 32) (input [WIDTH-1:0] d0, d1, input s, output reg [WIDTH-1:0] y);
    wire [WIDTH-1:0] temp = s ? d1 : d0;
    always @(temp) begin
        y <= 0;                // Lập tức xả về 0 khi có biến
        y <= #1 temp;          // Xuất kết quả sau 1ns
    end
endmodule

module adder (input [31:0] a, b, output reg [31:0] y);
    wire [31:0] temp = a + b;
    always @(temp) begin 
        y <= 0; 
        y <= #1 temp;          // Bộ cộng mất 1ns
    end
endmodule

module pc_reg (input clk, reset, input [31:0] pc_next, output reg [31:0] pc = 0);
    always @(posedge clk or posedge reset) begin
        if (reset) pc <= 32'b0;
        else       pc <= pc_next;
    end
endmodule

module sign_extend (input [15:0] a, output reg [31:0] y);
    wire [31:0] temp = {{16{a[15]}}, a};
    always @(temp) begin 
        y <= 0; 
        y <= #1 temp;          // Mở rộng dấu mất 1ns
    end
endmodule

module regfile (
    input clk, we3, input [4:0] a1, a2, a3, input [31:0] wd3, output reg [31:0] rd1, rd2
);
    reg [31:0] rf[31:0];
    integer i;
    initial begin for (i=0; i<32; i=i+1) rf[i] = 32'b0; end
    
    wire [31:0] t_rd1 = (a1 != 0) ? rf[a1] : 32'b0;
    wire [31:0] t_rd2 = (a2 != 0) ? rf[a2] : 32'b0;
    
    always @(t_rd1) begin rd1 <= 0; rd1 <= #1 t_rd1; end // Đọc thanh ghi mất 1ns
    always @(t_rd2) begin rd2 <= 0; rd2 <= #1 t_rd2; end
    
    always @(posedge clk) begin if (we3) rf[a3] <= wd3; end
endmodule

module alu (
    input [31:0] src_a, src_b, input [2:0] alu_control, output reg [31:0] alu_result, output reg zero
);
    reg [31:0] temp_res;
    always @(*) begin
        case (alu_control)
            3'b010: temp_res = src_a + src_b;      
            3'b110: temp_res = src_a - src_b;      
            3'b000: temp_res = src_a & src_b;      
            3'b001: temp_res = src_a | src_b;      
            3'b111: temp_res = (src_a < src_b) ? 1 : 0; 
            default: temp_res = 32'b0;
        endcase
    end
    
    always @(temp_res) begin
        alu_result <= 0; zero <= 0;
        alu_result <= #2 temp_res;         // ALU thực thi mất 2ns
        zero       <= #2 (temp_res == 0);
    end
endmodule

module dmem (input clk, we, input [31:0] a, wd, output reg [31:0] rd);
    reg [31:0] RAM [63:0];
    integer i;
    initial begin for (i=0; i<64; i=i+1) RAM[i] = 32'b0; end
    
    wire [31:0] temp_rd = RAM[a[31:2]];
    always @(temp_rd) begin 
        rd <= 0; 
        rd <= #2 temp_rd;                  // RAM đọc mất 2ns
    end
    
    always @(posedge clk) begin if (we) RAM[a[31:2]] <= wd; end
endmodule

module imem (input reset, input [31:0] a, output reg [31:0] rd);
    reg [31:0] RAM [63:0];
    integer i;
    initial begin
        for (i=0; i<64; i=i+1) RAM[i] = 32'b0;
        RAM[0] = 32'h2010000a; 
        RAM[1] = 32'h20110005; 
        RAM[2] = 32'h02119020; 
        RAM[3] = 32'hac120004; 
        RAM[4] = 32'h8c130004; 
        RAM[5] = 32'h12530001; 
        RAM[6] = 32'h20140063; 
        RAM[7] = 32'h20150025; 
        RAM[8] = 32'h08000008; 
    end
    
    wire [31:0] temp_rd = (reset) ? 32'b0 : RAM[a[31:2]];
    always @(temp_rd) begin
        rd <= 0;
        rd <= #2 temp_rd;                  // Giai đoạn Fetch mất 2ns
    end
endmodule

// ===============================================
// CONTROL UNIT VÀ BỘ GIẢI MÃ
// ===============================================
module control_unit (
    input  wire       reset,
    input  wire [5:0] Op,          
    input  wire [5:0] Funct,       
    output wire       RegDst, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, Jump,        
    output wire [2:0] ALUControl
);
    wire [1:0] ALUOp;
    main_decoder md (.reset(reset), .Op(Op), .RegWrite(RegWrite), .RegDst(RegDst), .ALUSrc(ALUSrc), .Branch(Branch), .MemWrite(MemWrite), .MemtoReg(MemtoReg), .Jump(Jump), .ALUOp(ALUOp));
    alu_decoder ad (.reset(reset), .Funct(Funct), .ALUOp(ALUOp), .ALUControl(ALUControl));
endmodule

module main_decoder (
    input  wire       reset,
    input  wire [5:0] Op,
    output reg        RegWrite, RegDst, ALUSrc, Branch, MemWrite, MemtoReg, Jump,
    output reg  [1:0] ALUOp
);
    reg rw, rd_flag, as, br, mw, mt, jmp;
    reg [1:0] aop;
    always @(*) begin
        if (reset) begin
            rw=0; rd_flag=0; as=0; br=0; mw=0; mt=0; jmp=0; aop=2'b00;
        end else begin
            case (Op)
                6'b000000: begin rw=1; rd_flag=1; as=0; br=0; mw=0; mt=0; jmp=0; aop=2'b10; end 
                6'b100011: begin rw=1; rd_flag=0; as=1; br=0; mw=0; mt=1; jmp=0; aop=2'b00; end 
                6'b101011: begin rw=0; rd_flag=0; as=1; br=0; mw=1; mt=0; jmp=0; aop=2'b00; end 
                6'b000100: begin rw=0; rd_flag=0; as=0; br=1; mw=0; mt=0; jmp=0; aop=2'b01; end 
                6'b001000: begin rw=1; rd_flag=0; as=1; br=0; mw=0; mt=0; jmp=0; aop=2'b00; end 
                6'b000010: begin rw=0; rd_flag=0; as=0; br=0; mw=0; mt=0; jmp=1; aop=2'b00; end 
                default:   begin rw=0; rd_flag=0; as=0; br=0; mw=0; mt=0; jmp=0; aop=2'b00; end
            endcase
        end
    end
    
    // Gom các tín hiệu điều khiển lại để Delay 1ns (Giải mã)
    always @(rw or rd_flag or as or br or mw or mt or jmp or aop) begin
        RegWrite <= 0; RegDst <= 0; ALUSrc <= 0; Branch <= 0; MemWrite <= 0; MemtoReg <= 0; Jump <= 0; ALUOp <= 0;
        RegWrite <= #1 rw; RegDst <= #1 rd_flag; ALUSrc <= #1 as; Branch <= #1 br; 
        MemWrite <= #1 mw; MemtoReg <= #1 mt; Jump <= #1 jmp; ALUOp <= #1 aop;
    end
endmodule

module alu_decoder (
    input  wire       reset,
    input  wire [5:0] Funct,
    input  wire [1:0] ALUOp,
    output reg  [2:0] ALUControl
);
    reg [2:0] ac;
    always @(*) begin
        if (reset) ac = 3'b000;
        else begin
            case (ALUOp)
                2'b00: ac = 3'b010; 
                2'b01: ac = 3'b110; 
                2'b10: case (Funct)
                        6'b100000: ac = 3'b010; 
                        6'b100010: ac = 3'b110; 
                        6'b100100: ac = 3'b000; 
                        6'b100101: ac = 3'b001; 
                        6'b101010: ac = 3'b111; 
                        default:   ac = 3'bxxx;
                       endcase
                default: ac = 3'bxxx;
            endcase
        end
    end
    
    always @(ac) begin 
        ALUControl <= 0; 
        ALUControl <= #1 ac; 
    end
endmodule              

module Branch_Logic (
    input  [31:0] PCPlus4, instr, read_data1, read_data2,
    output reg [31:0] next_PC
);
    wire [5:0] opcode = instr[31:26];
    wire is_beq = (opcode == 6'b000100);
    wire is_bne = (opcode == 6'b000101);
    
    wire Zero = (read_data1 == read_data2) ? 1'b1 : 1'b0;
    wire [31:0] SignImm = {{16{instr[15]}}, instr[15:0]};
    wire [31:0] PCBranch = PCPlus4 + (SignImm << 2);
    wire PCSrc = (is_beq & Zero) | (is_bne & ~Zero);
    
    wire [31:0] temp_npc = (PCSrc == 1'b1) ? PCBranch : PCPlus4;
    always @(temp_npc) begin
        next_PC <= 0;
        next_PC <= #2 temp_npc;
    end
endmodule