`timescale 1ns / 1ps

module top (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] cyc_cnt,
    output wire        passed,
    output wire        failed
);

    // ==========================================
    // 1. REGISTER FILE & DATA MEMORY
    // ==========================================
    logic [31:0] rf   [0:31];
    logic [31:0] dmem [0:15];

    // Instruction Memory (ROM)
    logic [31:0] instrs [0:15];
    initial begin
        // 0: ADD  r10, r0,  r0     (r10 = 0)
        instrs[0]  = {7'b0000000, 5'd0,  5'd0,  3'b000, 5'd10, 7'b0110011};
        // 1: ADD  r14, r10, r0     (r14 = r10 = 0)
        instrs[1]  = {7'b0000000, 5'd0,  5'd10, 3'b000, 5'd14, 7'b0110011};
        // 2: ADDI r12, r0, 10      (r12 = 10)
        instrs[2]  = {12'b0000_0000_1010, 5'd0, 3'b000, 5'd12, 7'b0010011};
        // 3: ADD  r13, r10, r0     (r13 = r10 = 0)
        instrs[3]  = {7'b0000000, 5'd0,  5'd10, 3'b000, 5'd13, 7'b0110011};
        // 4: ADD  r14, r13, r14    (r14 = r13 + r14, accumulate sum)
        instrs[4]  = {7'b0000000, 5'd14, 5'd13, 3'b000, 5'd14, 7'b0110011};
        // 5: ADDI r13, r13, 1      (r13 = r13 + 1, increment counter)
        instrs[5]  = {12'b0000_0000_0001, 5'd13, 3'b000, 5'd13, 7'b0010011};
        // 6: BLT r13, r12, -8      (if r13 < r12, branch back to instruction 4)
        instrs[6]  = 32'hfec6cce3;
        // 7: ADD  r10, r14, r0     (r10 = r14 = 45)
        instrs[7]  = {7'b0000000, 5'd0,  5'd14, 3'b000, 5'd10, 7'b0110011};
        // 8: SW   r10, 16(r0)      (mem[4] = r10)
        instrs[8]  = {7'b0000000, 5'd10, 5'd0,  3'b010, 5'b10000, 7'b0100011};
        // 9: LW   r17, 16(r0)      (r17 = mem[4])
        instrs[9]  = {12'b0000_0001_0000, 5'd0, 3'b010, 5'd17, 7'b0000011};
        // 10-15: NOP (ADDI x0, x0, 0)
        instrs[10] = 32'h0000_0013;
        instrs[11] = 32'h0000_0013;
        instrs[12] = 32'h0000_0013;
        instrs[13] = 32'h0000_0013;
        instrs[14] = 32'h0000_0013;
        instrs[15] = 32'h0000_0013;
    end

    // ==========================================
    // 2. STAGE 1 - FETCH (Clock Gated)
    // ==========================================
    logic [31:0] CPU_pc_a1 = 32'd0;

    wire  [31:0] CPU_inc_pc_a1 = CPU_pc_a1 + 32'd4;
    wire  [31:0] CPU_instr_a1  = instrs[CPU_pc_a1[5:2]];
    wire  [6:0]  CPU_opcode_a1 = CPU_instr_a1[6:0];

    wire CPU_is_i_instr_a1 = (CPU_opcode_a1 == 7'b0000011) ||
                             (CPU_opcode_a1 == 7'b0010011) ||
                             (CPU_opcode_a1 == 7'b1100111);
    wire CPU_is_r_instr_a1 = (CPU_opcode_a1 == 7'b0110011);
    wire CPU_is_s_instr_a1 = (CPU_opcode_a1 == 7'b0100011);
    wire CPU_is_b_instr_a1 = (CPU_opcode_a1 == 7'b1100011);
    wire CPU_is_u_instr_a1 = (CPU_opcode_a1 == 7'b0110111) ||
                             (CPU_opcode_a1 == 7'b0010111);
    wire CPU_is_j_instr_a1 = (CPU_opcode_a1 == 7'b1101111);

    wire [31:0] CPU_imm_a1 =
        CPU_is_i_instr_a1 ? { {21{CPU_instr_a1[31]}}, CPU_instr_a1[30:20] } :
        CPU_is_s_instr_a1 ? { {21{CPU_instr_a1[31]}}, CPU_instr_a1[30:25], CPU_instr_a1[11:7] } :
        CPU_is_b_instr_a1 ? { {20{CPU_instr_a1[31]}}, CPU_instr_a1[7],
                               CPU_instr_a1[30:25], CPU_instr_a1[11:8], 1'b0 } :
        CPU_is_u_instr_a1 ? { CPU_instr_a1[31:12], 12'b0 } :
        CPU_is_j_instr_a1 ? { {12{CPU_instr_a1[31]}}, CPU_instr_a1[19:12],
                               CPU_instr_a1[20], CPU_instr_a1[30:21], 1'b0 } :
        32'b0;

    wire CPU_rs2_valid_a1    = CPU_is_r_instr_a1 || CPU_is_s_instr_a1 || CPU_is_b_instr_a1;
    wire CPU_rs1_valid_a1    = CPU_is_r_instr_a1 || CPU_is_s_instr_a1 ||
                                CPU_is_b_instr_a1 || CPU_is_i_instr_a1;
    wire CPU_rd_valid_a1     = CPU_is_r_instr_a1 || CPU_is_i_instr_a1 ||
                                CPU_is_u_instr_a1 || CPU_is_j_instr_a1;
    wire CPU_funct3_valid_a1 = CPU_is_r_instr_a1 || CPU_is_s_instr_a1 ||
                                CPU_is_b_instr_a1 || CPU_is_i_instr_a1;
    wire CPU_funct7_valid_a1 = CPU_is_r_instr_a1;

    wire [4:0] CPU_rs2_a1    = CPU_instr_a1[24:20];
    wire [4:0] CPU_rs1_a1    = CPU_instr_a1[19:15];
    wire [4:0] CPU_rd_a1     = CPU_instr_a1[11:7];
    wire [2:0] CPU_funct3_a1 = CPU_instr_a1[14:12];
    wire [6:0] CPU_funct7_a1 = CPU_instr_a1[31:25];

    // ==========================================
    // 3. STAGE 2 - DECODE (Clock Gated)
    // ==========================================
    logic [31:0] CPU_pc_a2        = 32'd0;
    logic [31:0] CPU_instr_a2     = 32'd0;
    logic [31:0] CPU_imm_a2       = 32'd0;
    logic [4:0]  CPU_rs1_a2       = 5'd0;
    logic [4:0]  CPU_rs2_a2       = 5'd0;
    logic [4:0]  CPU_rd_a2        = 5'd0;
    logic [31:0] CPU_inc_pc_a2    = 32'd0;
    logic [2:0]  CPU_funct3_a2    = 3'd0;
    logic [6:0]  CPU_funct7_a2    = 7'd0;
    logic [6:0]  CPU_opcode_a2    = 7'd0;
    logic        CPU_rs1_valid_a2 = 1'b0;
    logic        CPU_rs2_valid_a2 = 1'b0;
    logic        CPU_rd_valid_a2  = 1'b0;

    wire CPU_is_s_instr_a2 = (CPU_opcode_a2 == 7'b0100011);

    wire CPU_is_beq_a2   = (CPU_opcode_a2 == 7'b1100011) && (CPU_funct3_a2 == 3'b000);
    wire CPU_is_bne_a2   = (CPU_opcode_a2 == 7'b1100011) && (CPU_funct3_a2 == 3'b001);
    wire CPU_is_blt_a2   = (CPU_opcode_a2 == 7'b1100011) && (CPU_funct3_a2 == 3'b100);
    wire CPU_is_bge_a2   = (CPU_opcode_a2 == 7'b1100011) && (CPU_funct3_a2 == 3'b101);
    wire CPU_is_bltu_a2  = (CPU_opcode_a2 == 7'b1100011) && (CPU_funct3_a2 == 3'b110);
    wire CPU_is_bgeu_a2  = (CPU_opcode_a2 == 7'b1100011) && (CPU_funct3_a2 == 3'b111);

    wire CPU_is_addi_a2  = (CPU_opcode_a2 == 7'b0010011) && (CPU_funct3_a2 == 3'b000);
    wire CPU_is_add_a2   = (CPU_opcode_a2 == 7'b0110011) && (CPU_funct3_a2 == 3'b000) && !CPU_funct7_a2[5];
    wire CPU_is_sub_a2   = (CPU_opcode_a2 == 7'b0110011) && (CPU_funct3_a2 == 3'b000) &&  CPU_funct7_a2[5];

    wire CPU_is_andi_a2  = (CPU_opcode_a2 == 7'b0010011) && (CPU_funct3_a2 == 3'b111);
    wire CPU_is_ori_a2   = (CPU_opcode_a2 == 7'b0010011) && (CPU_funct3_a2 == 3'b110);
    wire CPU_is_xori_a2  = (CPU_opcode_a2 == 7'b0010011) && (CPU_funct3_a2 == 3'b100);
    wire CPU_is_slli_a2  = (CPU_opcode_a2 == 7'b0010011) && (CPU_funct3_a2 == 3'b001) && !CPU_funct7_a2[5];
    wire CPU_is_srli_a2  = (CPU_opcode_a2 == 7'b0010011) && (CPU_funct3_a2 == 3'b101) && !CPU_funct7_a2[5];
    wire CPU_is_srai_a2  = (CPU_opcode_a2 == 7'b0010011) && (CPU_funct3_a2 == 3'b101) &&  CPU_funct7_a2[5];

    wire CPU_is_sll_a2   = (CPU_opcode_a2 == 7'b0110011) && (CPU_funct3_a2 == 3'b001) && !CPU_funct7_a2[5];
    wire CPU_is_slt_a2   = (CPU_opcode_a2 == 7'b0110011) && (CPU_funct3_a2 == 3'b010) && !CPU_funct7_a2[5];
    wire CPU_is_sltu_a2  = (CPU_opcode_a2 == 7'b0110011) && (CPU_funct3_a2 == 3'b011) && !CPU_funct7_a2[5];
    wire CPU_is_xor_a2   = (CPU_opcode_a2 == 7'b0110011) && (CPU_funct3_a2 == 3'b100) && !CPU_funct7_a2[5];
    wire CPU_is_srl_a2   = (CPU_opcode_a2 == 7'b0110011) && (CPU_funct3_a2 == 3'b101) && !CPU_funct7_a2[5];
    wire CPU_is_sra_a2   = (CPU_opcode_a2 == 7'b0110011) && (CPU_funct3_a2 == 3'b101) &&  CPU_funct7_a2[5];
    wire CPU_is_or_a2    = (CPU_opcode_a2 == 7'b0110011) && (CPU_funct3_a2 == 3'b110) && !CPU_funct7_a2[5];
    wire CPU_is_and_a2   = (CPU_opcode_a2 == 7'b0110011) && (CPU_funct3_a2 == 3'b111) && !CPU_funct7_a2[5];

    wire CPU_is_lui_a2   = (CPU_opcode_a2 == 7'b0110111);
    wire CPU_is_auipc_a2 = (CPU_opcode_a2 == 7'b0010111);
    wire CPU_is_jal_a2   = (CPU_opcode_a2 == 7'b1101111);
    wire CPU_is_jalr_a2  = (CPU_opcode_a2 == 7'b1100111) && (CPU_funct3_a2 == 3'b000);
    wire CPU_is_sw_a2    = (CPU_opcode_a2 == 7'b0100011) && (CPU_funct3_a2 == 3'b010);
    wire CPU_is_slti_a2  = (CPU_opcode_a2 == 7'b0010011) && (CPU_funct3_a2 == 3'b010);
    wire CPU_is_sltiu_a2 = (CPU_opcode_a2 == 7'b0010011) && (CPU_funct3_a2 == 3'b011);
    wire CPU_is_load_a2  = (CPU_opcode_a2 == 7'b0000011);

    wire [31:0] CPU_rf_rd_data1_a2 = rf[CPU_rs1_a2];
    wire [31:0] CPU_rf_rd_data2_a2 = rf[CPU_rs2_a2];

    // ==========================================
    // 4. STAGE 3 - EXECUTE (Clock Gated)
    // ==========================================
    logic [31:0] CPU_pc_a3          = 32'd0;
    logic [31:0] CPU_imm_a3         = 32'd0;
    logic [4:0]  CPU_rd_a3          = 5'd0;
    logic        CPU_rd_valid_a3    = 1'b0;
    logic [31:0] CPU_src1_value_a3  = 32'd0;
    logic [31:0] CPU_src2_value_a3  = 32'd0;
    logic [31:0] CPU_inc_pc_a3      = 32'd0;
    logic [31:0] CPU_br_tgt_pc_a3   = 32'd0;
    logic [31:0] CPU_jalr_tgt_pc_a3 = 32'd0;

    logic CPU_is_beq_a3    = 1'b0;
    logic CPU_is_bne_a3    = 1'b0;
    logic CPU_is_blt_a3    = 1'b0;
    logic CPU_is_bge_a3    = 1'b0;
    logic CPU_is_bltu_a3   = 1'b0;
    logic CPU_is_bgeu_a3   = 1'b0;
    logic CPU_is_addi_a3   = 1'b0;
    logic CPU_is_add_a3    = 1'b0;
    logic CPU_is_sub_a3    = 1'b0;
    logic CPU_is_and_a3    = 1'b0;
    logic CPU_is_or_a3     = 1'b0;
    logic CPU_is_xor_a3    = 1'b0;
    logic CPU_is_andi_a3   = 1'b0;
    logic CPU_is_ori_a3    = 1'b0;
    logic CPU_is_xori_a3   = 1'b0;
    logic CPU_is_slli_a3   = 1'b0;
    logic CPU_is_srli_a3   = 1'b0;
    logic CPU_is_srai_a3   = 1'b0;
    logic CPU_is_sll_a3    = 1'b0;
    logic CPU_is_srl_a3    = 1'b0;
    logic CPU_is_sra_a3    = 1'b0;
    logic CPU_is_sltu_a3   = 1'b0;
    logic CPU_is_sltiu_a3  = 1'b0;
    logic CPU_is_slt_a3    = 1'b0;
    logic CPU_is_slti_a3   = 1'b0;
    logic CPU_is_lui_a3    = 1'b0;
    logic CPU_is_auipc_a3  = 1'b0;
    logic CPU_is_jal_a3    = 1'b0;
    logic CPU_is_jalr_a3   = 1'b0;
    logic CPU_is_load_a3   = 1'b0;
    logic CPU_is_s_instr_a3= 1'b0;
    logic CPU_is_sw_a3     = 1'b0;

    // Forwarding from stage 3 (EX) and stage 4 (MEM)
    logic [4:0]  CPU_rd_a4        = 5'd0;
    logic        CPU_valid_a4     = 1'b0;
    logic        CPU_valid_load_a4= 1'b0;
    logic [31:0] CPU_result_a4    = 32'd0;

    logic [4:0]  CPU_rd_a5        = 5'd0;
    logic        CPU_valid_load_a5= 1'b0;
    logic [31:0] CPU_ld_data_a5;

    // Writeback signals (declared early for forwarding)
    wire [4:0]  CPU_rf_wr_index_a3;
    wire [31:0] CPU_rf_wr_data_a3;
    wire        CPU_rf_wr_en_a3;

    // Forwarding muxes for stage 2 -> stage 3
    wire [31:0] CPU_src1_value_a2;
    wire [31:0] CPU_src2_value_a2;

    assign CPU_src1_value_a2 =
        ((CPU_rf_wr_index_a3 == CPU_rs1_a2) && CPU_rf_wr_en_a3 && (CPU_rs1_a2 != 5'd0))
            ? CPU_rf_wr_data_a3 :
        ((CPU_rd_a4 == CPU_rs1_a2) && CPU_valid_a4 && (CPU_rs1_a2 != 5'd0))
            ? CPU_result_a4 :
        ((CPU_rd_a5 == CPU_rs1_a2) && CPU_valid_load_a5 && (CPU_rs1_a2 != 5'd0))
            ? CPU_ld_data_a5 :
            CPU_rf_rd_data1_a2;

    assign CPU_src2_value_a2 =
        ((CPU_rf_wr_index_a3 == CPU_rs2_a2) && CPU_rf_wr_en_a3 && (CPU_rs2_a2 != 5'd0))
            ? CPU_rf_wr_data_a3 :
        ((CPU_rd_a4 == CPU_rs2_a2) && CPU_valid_a4 && (CPU_rs2_a2 != 5'd0))
            ? CPU_result_a4 :
        ((CPU_rd_a5 == CPU_rs2_a2) && CPU_valid_load_a5 && (CPU_rs2_a2 != 5'd0))
            ? CPU_ld_data_a5 :
            CPU_rf_rd_data2_a2;

    wire [31:0] CPU_br_tgt_pc_a2   = CPU_pc_a2 + CPU_imm_a2;
    wire [31:0] CPU_jalr_tgt_pc_a2 = CPU_src1_value_a2 + CPU_imm_a2;

    // Branch taken logic
    wire CPU_taken_br_a3 =
        CPU_is_beq_a3  ? (CPU_src1_value_a3 == CPU_src2_value_a3) :
        CPU_is_bne_a3  ? (CPU_src1_value_a3 != CPU_src2_value_a3) :
        CPU_is_bltu_a3 ? (CPU_src1_value_a3 <  CPU_src2_value_a3) :
        CPU_is_bgeu_a3 ? (CPU_src1_value_a3 >= CPU_src2_value_a3) :
        CPU_is_blt_a3  ? ($signed(CPU_src1_value_a3) <  $signed(CPU_src2_value_a3)) :
        CPU_is_bge_a3  ? ($signed(CPU_src1_value_a3) >= $signed(CPU_src2_value_a3)) :
        1'b0;

    // Load-use hazard detection
    wire load_use_hazard_a3 = CPU_is_load_a3 && CPU_rd_valid_a3 && (CPU_rd_a3 != 5'b0) &&
                              ((CPU_rs1_a2 == CPU_rd_a3 && CPU_rs1_valid_a2) ||
                               (CPU_rs2_a2 == CPU_rd_a3 && CPU_rs2_valid_a2));
    wire load_use_hazard_a4 = CPU_valid_load_a4 && (CPU_rd_a4 != 5'b0) &&
                              ((CPU_rs1_a2 == CPU_rd_a4 && CPU_rs1_valid_a2) ||
                               (CPU_rs2_a2 == CPU_rd_a4 && CPU_rs2_valid_a2));
    wire CPU_valid_a3 = ~(load_use_hazard_a3 || load_use_hazard_a4);

    wire CPU_valid_taken_br_a3 = CPU_valid_a3 && CPU_taken_br_a3;
    wire CPU_valid_load_a3     = CPU_valid_a3 && CPU_is_load_a3;
    wire CPU_is_jump_a3        = CPU_is_jal_a3 || CPU_is_jalr_a3;
    wire CPU_valid_jump_a3     = CPU_valid_a3 && CPU_is_jump_a3;

    // ALU result
    wire [31:0] CPU_sltu_rslt_a3  = (CPU_src1_value_a3 < CPU_src2_value_a3) ? 32'd1 : 32'd0;
    wire [31:0] CPU_sltiu_rslt_a3 = ($unsigned(CPU_src1_value_a3) < $unsigned(CPU_imm_a3)) ? 32'd1 : 32'd0;

    wire [31:0] CPU_result_a3 =
        CPU_is_add_a3     ? (CPU_src1_value_a3 + CPU_src2_value_a3)       :
        CPU_is_sub_a3     ? (CPU_src1_value_a3 - CPU_src2_value_a3)       :
        CPU_is_and_a3     ? (CPU_src1_value_a3 & CPU_src2_value_a3)       :
        CPU_is_or_a3      ? (CPU_src1_value_a3 | CPU_src2_value_a3)       :
        CPU_is_xor_a3     ? (CPU_src1_value_a3 ^ CPU_src2_value_a3)       :
        CPU_is_addi_a3    ? (CPU_src1_value_a3 + CPU_imm_a3)              :
        CPU_is_andi_a3    ? (CPU_src1_value_a3 & CPU_imm_a3)              :
        CPU_is_ori_a3     ? (CPU_src1_value_a3 | CPU_imm_a3)              :
        CPU_is_xori_a3    ? (CPU_src1_value_a3 ^ CPU_imm_a3)              :
        CPU_is_load_a3    ? (CPU_src1_value_a3 + CPU_imm_a3)              :
        CPU_is_s_instr_a3 ? (CPU_src1_value_a3 + CPU_imm_a3)              :
        CPU_is_slli_a3    ? (CPU_src1_value_a3 << CPU_imm_a3[4:0])        :
        CPU_is_srli_a3    ? (CPU_src1_value_a3 >> CPU_imm_a3[4:0])        :
        CPU_is_sll_a3     ? (CPU_src1_value_a3 << CPU_src2_value_a3[4:0]) :
        CPU_is_srl_a3     ? (CPU_src1_value_a3 >> CPU_src2_value_a3[4:0]) :
        CPU_is_sltu_a3    ? CPU_sltu_rslt_a3                              :
        CPU_is_sltiu_a3   ? CPU_sltiu_rslt_a3                             :
        CPU_is_lui_a3     ? {CPU_imm_a3[31:12], 12'b0}                    :
        CPU_is_auipc_a3   ? (CPU_pc_a3 + CPU_imm_a3)                      :
        CPU_is_jal_a3     ? (CPU_pc_a3 + 32'd4)                           :
        CPU_is_jalr_a3    ? (CPU_pc_a3 + 32'd4)                           :
        CPU_is_srai_a3    ? ($signed(CPU_src1_value_a3) >>> CPU_imm_a3[4:0]) :
        CPU_is_slt_a3     ? (($signed(CPU_src1_value_a3) < $signed(CPU_src2_value_a3)) ? 32'd1 : 32'd0) :
        CPU_is_slti_a3    ? (($signed(CPU_src1_value_a3) < $signed(CPU_imm_a3)) ? 32'd1 : 32'd0) :
        CPU_is_sra_a3     ? ($signed(CPU_src1_value_a3) >>> CPU_src2_value_a3[4:0]) :
        32'b0;

    // Writeback mux: load from stage 5 takes priority
    assign CPU_rf_wr_en_a3    = (CPU_valid_a3 && CPU_rd_valid_a3 && (CPU_rd_a3 != 5'b0))
                                  || CPU_valid_load_a5;
    assign CPU_rf_wr_index_a3 = CPU_valid_load_a5 ? CPU_rd_a5 : CPU_rd_a3;
    assign CPU_rf_wr_data_a3  = CPU_valid_load_a5 ? CPU_ld_data_a5 : CPU_result_a3;

    // ==========================================
    // 5. STAGE 4 - MEMORY (Clock Gated)
    // ==========================================
    logic [31:0] CPU_src2_value_a4    = 32'd0;
    logic        CPU_is_load_a4        = 1'b0;
    logic        CPU_is_s_instr_a4     = 1'b0;
    logic        CPU_valid_taken_br_a4 = 1'b0;

    wire         CPU_dmem_wr_en_a4   = CPU_is_s_instr_a4 && CPU_valid_a4;
    wire  [3:0]  CPU_dmem_addr_a4    = CPU_result_a4[5:2];
    wire  [31:0] CPU_dmem_wr_data_a4 = CPU_src2_value_a4;
    wire  [31:0] CPU_dmem_rd_data_a4 = dmem[CPU_dmem_addr_a4];

    // ==========================================
    // 6. STAGE 5 - WRITEBACK (Clock Gated)
    // ==========================================
    logic [31:0] CPU_result_a5       = 32'd0;
    logic [31:0] CPU_dmem_rd_data_a5 = 32'd0;
    logic        CPU_valid_a5        = 1'b0;
    logic        CPU_valid_taken_br_a5 = 1'b0;

    assign CPU_ld_data_a5 = CPU_dmem_rd_data_a5;

    // ==========================================
    // 7. CLOCK GATING CONTROL LOGIC
    // ==========================================
    wire pc_en = ~reset && (CPU_valid_a3 || CPU_valid_taken_br_a3 || CPU_valid_jump_a3);
    wire a2_en = ~reset && CPU_valid_a3 && ~CPU_valid_taken_br_a3 && ~CPU_valid_jump_a3;
    wire a3_en = ~reset;
    wire a4_en = ~reset;
    wire a5_en = ~reset;

    // ==========================================
    // 8. CLOCK GATED FLIP-FLOPS
    // ==========================================

    // PC register with clock gating
    always_ff @(posedge clk) begin
        if (pc_en) begin
            if (CPU_valid_taken_br_a3)
                CPU_pc_a1 <= CPU_br_tgt_pc_a3;
            else if (CPU_valid_jump_a3 && CPU_is_jal_a3)
                CPU_pc_a1 <= CPU_br_tgt_pc_a3;
            else if (CPU_valid_jump_a3 && CPU_is_jalr_a3)
                CPU_pc_a1 <= CPU_jalr_tgt_pc_a3;
            else
                CPU_pc_a1 <= CPU_inc_pc_a1;
        end
    end

    // Stage 2 registers with clock gating
    always_ff @(posedge clk) begin
        if (a2_en) begin
            CPU_pc_a2        <= CPU_pc_a1;
            CPU_instr_a2     <= CPU_instr_a1;
            CPU_imm_a2       <= CPU_imm_a1;
            CPU_rs1_a2       <= CPU_rs1_a1;
            CPU_rs2_a2       <= CPU_rs2_a1;
            CPU_rd_a2        <= CPU_rd_a1;
            CPU_rs1_valid_a2 <= CPU_rs1_valid_a1;
            CPU_rs2_valid_a2 <= CPU_rs2_valid_a1;
            CPU_rd_valid_a2  <= CPU_rd_valid_a1;
            CPU_funct3_a2    <= CPU_funct3_a1;
            CPU_funct7_a2    <= CPU_funct7_a1;
            CPU_opcode_a2    <= CPU_opcode_a1;
            CPU_inc_pc_a2    <= CPU_inc_pc_a1;
        end
    end

    // Stage 3 registers with clock gating
    always_ff @(posedge clk) begin
        if (a3_en) begin
            if (CPU_valid_a3) begin
                CPU_pc_a3          <= CPU_pc_a2;
                CPU_imm_a3         <= CPU_imm_a2;
                CPU_rd_a3          <= CPU_rd_a2;
                CPU_rd_valid_a3    <= CPU_rd_valid_a2;
                CPU_src1_value_a3  <= CPU_src1_value_a2;
                CPU_src2_value_a3  <= CPU_src2_value_a2;
                CPU_inc_pc_a3      <= CPU_inc_pc_a2;
                CPU_br_tgt_pc_a3   <= CPU_br_tgt_pc_a2;
                CPU_jalr_tgt_pc_a3 <= CPU_jalr_tgt_pc_a2;

                CPU_is_beq_a3    <= CPU_is_beq_a2;
                CPU_is_bne_a3    <= CPU_is_bne_a2;
                CPU_is_blt_a3    <= CPU_is_blt_a2;
                CPU_is_bge_a3    <= CPU_is_bge_a2;
                CPU_is_bltu_a3   <= CPU_is_bltu_a2;
                CPU_is_bgeu_a3   <= CPU_is_bgeu_a2;
                CPU_is_addi_a3   <= CPU_is_addi_a2;
                CPU_is_add_a3    <= CPU_is_add_a2;
                CPU_is_sub_a3    <= CPU_is_sub_a2;
                CPU_is_andi_a3   <= CPU_is_andi_a2;
                CPU_is_ori_a3    <= CPU_is_ori_a2;
                CPU_is_xori_a3   <= CPU_is_xori_a2;
                CPU_is_slli_a3   <= CPU_is_slli_a2;
                CPU_is_srli_a3   <= CPU_is_srli_a2;
                CPU_is_srai_a3   <= CPU_is_srai_a2;
                CPU_is_sll_a3    <= CPU_is_sll_a2;
                CPU_is_srl_a3    <= CPU_is_srl_a2;
                CPU_is_sra_a3    <= CPU_is_sra_a2;
                CPU_is_sltu_a3   <= CPU_is_sltu_a2;
                CPU_is_sltiu_a3  <= CPU_is_sltiu_a2;
                CPU_is_slt_a3    <= CPU_is_slt_a2;
                CPU_is_slti_a3   <= CPU_is_slti_a2;
                CPU_is_lui_a3    <= CPU_is_lui_a2;
                CPU_is_auipc_a3  <= CPU_is_auipc_a2;
                CPU_is_jal_a3    <= CPU_is_jal_a2;
                CPU_is_jalr_a3   <= CPU_is_jalr_a2;
                CPU_is_sw_a3     <= CPU_is_sw_a2;
                CPU_is_load_a3   <= CPU_is_load_a2;
                CPU_is_s_instr_a3<= CPU_is_s_instr_a2;
                CPU_is_and_a3    <= CPU_is_and_a2;
                CPU_is_or_a3     <= CPU_is_or_a2;
                CPU_is_xor_a3    <= CPU_is_xor_a2;
            end else begin
                CPU_rd_valid_a3   <= 1'b0;
                CPU_is_beq_a3    <= 1'b0; CPU_is_bne_a3    <= 1'b0;
                CPU_is_blt_a3    <= 1'b0; CPU_is_bge_a3    <= 1'b0;
                CPU_is_bltu_a3   <= 1'b0; CPU_is_bgeu_a3   <= 1'b0;
                CPU_is_addi_a3   <= 1'b0; CPU_is_add_a3    <= 1'b0;
                CPU_is_sub_a3    <= 1'b0; CPU_is_andi_a3   <= 1'b0;
                CPU_is_ori_a3    <= 1'b0; CPU_is_xori_a3   <= 1'b0;
                CPU_is_slli_a3   <= 1'b0; CPU_is_srli_a3   <= 1'b0;
                CPU_is_srai_a3   <= 1'b0; CPU_is_sll_a3    <= 1'b0;
                CPU_is_srl_a3    <= 1'b0; CPU_is_sra_a3    <= 1'b0;
                CPU_is_sltu_a3   <= 1'b0; CPU_is_sltiu_a3  <= 1'b0;
                CPU_is_slt_a3    <= 1'b0; CPU_is_slti_a3   <= 1'b0;
                CPU_is_lui_a3    <= 1'b0; CPU_is_auipc_a3  <= 1'b0;
                CPU_is_jal_a3    <= 1'b0; CPU_is_jalr_a3   <= 1'b0;
                CPU_is_sw_a3     <= 1'b0; CPU_is_load_a3   <= 1'b0;
                CPU_is_s_instr_a3<= 1'b0; CPU_is_and_a3   <= 1'b0;
                CPU_is_or_a3     <= 1'b0; CPU_is_xor_a3    <= 1'b0;
            end
        end
    end

    // Stage 4 registers with clock gating
    always_ff @(posedge clk) begin
        if (a4_en) begin
            CPU_result_a4     <= CPU_result_a3;
            CPU_src2_value_a4 <= CPU_src2_value_a3;
            CPU_is_load_a4    <= CPU_is_load_a3;
            CPU_is_s_instr_a4 <= CPU_is_s_instr_a3;
            CPU_rd_a4         <= CPU_rd_a3;
            CPU_valid_a4      <= CPU_valid_a3;
            CPU_valid_load_a4 <= CPU_valid_load_a3;
            CPU_valid_taken_br_a4 <= CPU_valid_taken_br_a3;
        end
    end

    // Stage 5 registers with clock gating
    always_ff @(posedge clk) begin
        if (a5_en) begin
            CPU_result_a5       <= CPU_result_a4;
            CPU_rd_a5           <= CPU_rd_a4;
            CPU_dmem_rd_data_a5 <= CPU_dmem_rd_data_a4;
            CPU_valid_load_a5   <= CPU_valid_load_a4;
            CPU_valid_a5        <= CPU_valid_a4;
            CPU_valid_taken_br_a5 <= CPU_valid_taken_br_a4;
        end
    end

    // ==========================================
    // 9. REGISTER FILE WRITE (Clock Gated)
    // ==========================================
    wire rf_en = ~reset && CPU_rf_wr_en_a3;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 32; i++) rf[i] <= 32'd0;
        end else if (rf_en) begin
            if (CPU_rf_wr_index_a3 != 5'b0)
                rf[CPU_rf_wr_index_a3] <= CPU_rf_wr_data_a3;
        end
    end

    // ==========================================
    // 10. DATA MEMORY WRITE (Clock Gated)
    // ==========================================
    wire dmem_en = CPU_dmem_wr_en_a4;
    
    always_ff @(posedge clk) begin
        if (dmem_en)
            dmem[CPU_dmem_addr_a4] <= CPU_dmem_wr_data_a4;
    end

    // ==========================================
    // 11. PASS / FAIL
    // ==========================================
    assign passed = (rf[10] == 32'd45);
    assign failed = 1'b0;

endmodule
