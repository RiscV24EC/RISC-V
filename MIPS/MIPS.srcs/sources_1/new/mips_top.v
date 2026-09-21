`timescale 1ns / 1ps

module mips_top (
    input wire clk,
    input wire reset
);
    // --- KHAI BÁO CÁC ĐƯỜNG DÂY NỐI (WIRES) ---
    wire [31:0] pc, pc_next, pc_plus_4;
    wire [31:0] instr, sign_imm;
    wire [31:0] src_a, src_b, rd2, wd3;
    wire [31:0] alu_result, read_data;
    wire [4:0]  write_reg;
    
    // Tín hiệu điều khiển từ Control Unit
    wire RegDst, ALUSrc, MemtoReg, RegWrite, MemWrite, Branch, Jump;
    wire [2:0] ALUControl;
    wire zero; 

    // Các đường dây dành riêng cho tính toán địa chỉ nhảy (Jump)
    wire [31:0] pc_next_branch; 
    wire [31:0] pc_jump;
    // Lấy 4 bit cao của PC+4 ghép với 26 bit lệnh dịch trái 2 bit
    assign pc_jump = {pc_plus_4[31:28], instr[25:0], 2'b00};

    // ==========================================
    // 1. KHỐI ĐIỀU KHIỂN (CONTROL UNIT)
    // ==========================================
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

    // ==========================================
    // 2. KHỐI RẼ NHÁNH TÍCH HỢP (BRANCH LOGIC)
    // ==========================================
    Branch_Logic branch_unit (
        .PCPlus4(pc_plus_4), 
        .instr(instr),
        .read_data1(src_a), 
        .read_data2(rd2),
        .next_PC(pc_next_branch) // Xuất ra địa chỉ PC sau khi tính toán rẽ nhánh
    );

    // ==========================================
    // 3. MUX CHỌN ĐƯỜNG ĐI CUỐI CÙNG (JUMP HAY BRANCH)
    // ==========================================
    mux2 #(32) pcjumpmux (
        .d0(pc_next_branch), // Nếu ko có lệnh j -> Lấy kết quả từ khối Branch_Logic
        .d1(pc_jump),        // Nếu có lệnh j   -> Nhảy thẳng tới pc_jump
        .s(Jump), 
        .y(pc_next)          // Đưa địa chỉ cuối cùng vào thanh ghi PC
    );

    // ==========================================
    // 4. CÁC KHỐI DATAPATH CÒN LẠI
    // ==========================================
    
    // Fetch (Lấy lệnh)
    pc_reg pcreg (.clk(clk), .reset(reset), .pc_next(pc_next), .pc(pc));
    adder pcadd1 (.a(pc), .b(32'd4), .y(pc_plus_4));
    imem inst_mem (.a(pc), .rd(instr));
    
    // Decode (Giải mã lệnh & Đọc thanh ghi)
    mux2 #(5) regdstmux (.d0(instr[20:16]), .d1(instr[15:11]), .s(RegDst), .y(write_reg));
    regfile rf (.clk(clk), .we3(RegWrite), .a1(instr[25:21]), .a2(instr[20:16]), .a3(write_reg), .wd3(wd3), .rd1(src_a), .rd2(rd2));
    sign_extend se (.a(instr[15:0]), .y(sign_imm));
    
    // Execute (Thực thi - ALU)
    mux2 #(32) alusrcmux (.d0(rd2), .d1(sign_imm), .s(ALUSrc), .y(src_b));
    alu alu_inst (.src_a(src_a), .src_b(src_b), .alu_control(ALUControl), .alu_result(alu_result), .zero(zero));
    
    // Memory & Write Back (Bộ nhớ dữ liệu và Ghi lại thanh ghi)
    dmem data_mem (.clk(clk), .we(MemWrite), .a(alu_result), .wd(rd2), .rd(read_data));
    mux2 #(32) resmux (.d0(alu_result), .d1(read_data), .s(MemtoReg), .y(wd3));

endmodule