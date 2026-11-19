

module altor32_exec
(
  input clk_i,
  input rst_i,
  input intr_i,
  input break_i,
  output reg fault_o,
  output reg break_o,
  output reg icache_flush_o,
  output reg dcache_flush_o,
  output branch_o,
  output [31:0] branch_pc_o,
  output stall_o,
  input [31:0] opcode_i,
  input [31:0] opcode_pc_i,
  input opcode_valid_i,
  input [4:0] reg_ra_i,
  input [31:0] reg_ra_value_i,
  input [4:0] reg_rb_i,
  input [31:0] reg_rb_value_i,
  input [4:0] reg_rd_i,
  output [31:0] opcode_o,
  output [31:0] opcode_pc_o,
  output [4:0] reg_rd_o,
  output [31:0] reg_rd_value_o,
  output [63:0] mult_res_o,
  input [4:0] wb_rd_i,
  input [31:0] wb_rd_value_i,
  output reg [31:0] dmem_addr_o,
  output reg [31:0] dmem_data_out_o,
  input [31:0] dmem_data_in_i,
  output reg [3:0] dmem_sel_o,
  output reg dmem_we_o,
  output reg dmem_stb_o,
  output reg dmem_cyc_o,
  input dmem_stall_i,
  input dmem_ack_i
);


  function [0:0] less_than_signed;
    input [31:0] x;
    input [31:0] y;
    reg [31:0] v;
    begin
      v = x - y;
      if(x[31] != y[31]) less_than_signed = x[31]; 
      else less_than_signed = v[31];
    end
  endfunction


  function [0:0] less_than_equal_signed;
    input [31:0] x;
    input [31:0] y;
    reg [31:0] v;
    begin
      v = x - y;
      if(x == y) less_than_equal_signed = 1'b1; 
      else if(x[31] != y[31]) less_than_equal_signed = x[31]; 
      else less_than_equal_signed = v[31];
    end
  endfunction


  function [0:0] greater_than_signed;
    input [31:0] x;
    input [31:0] y;
    reg [31:0] v;
    begin
      v = y - x;
      if(x[31] != y[31]) greater_than_signed = y[31]; 
      else greater_than_signed = v[31];
    end
  endfunction


  function [0:0] greater_than_equal_signed;
    input [31:0] x;
    input [31:0] y;
    reg [31:0] v;
    begin
      v = y - x;
      if(x == y) greater_than_equal_signed = 1'b1; 
      else if(x[31] != y[31]) greater_than_equal_signed = y[31]; 
      else greater_than_equal_signed = v[31];
    end
  endfunction


  function [31:0] sign_extend_imm16;
    input [15:0] x;
    reg [31:0] y;
    begin
      if(x[15] == 1'b0) y[31:16] = 16'b0000000000000000; 
      else y[31:16] = 16'b1111111111111111;
      y[15:0] = x;
      sign_extend_imm16 = y;
    end
  endfunction


  function [31:0] sign_extend_imm26;
    input [25:0] x;
    reg [31:0] y;
    begin
      if(x[25] == 1'b0) y[31:26] = 6'b000000; 
      else y[31:26] = 6'b111111;
      y[25:0] = x;
      sign_extend_imm26 = y;
    end
  endfunction


  function [31:0] extend_imm16;
    input [15:0] x;
    begin
      extend_imm16 = { 16'h0000, x };
    end
  endfunction


  function [0:0] less_than_zero;
    input [31:0] x;
    begin
      if((x != 32'h00000000) & (x[31] == 1'b1)) less_than_zero = 1'b1; 
      else less_than_zero = 1'b0;
    end
  endfunction


  function [0:0] less_than_equal_zero;
    input [31:0] x;
    begin
      if((x == 32'h00000000) | (x[31] == 1'b1)) less_than_equal_zero = 1'b1; 
      else less_than_equal_zero = 1'b0;
    end
  endfunction


  function [0:0] more_than_equal_zero;
    input [31:0] x;
    begin
      if((x == 32'h00000000) | (x[31] == 1'b0)) more_than_equal_zero = 1'b1; 
      else more_than_equal_zero = 1'b0;
    end
  endfunction


  function [0:0] more_than_zero;
    input [31:0] x;
    begin
      if((x != 32'h00000000) & (x[31] == 1'b0)) more_than_zero = 1'b1; 
      else more_than_zero = 1'b0;
    end
  endfunction


  function [0:0] is_load_operation;
    input [7:0] opcode;
    begin
      is_load_operation = ((opcode == 8'h24) || (opcode == 8'h23) || (opcode == 8'h26) || (opcode == 8'h25) || (opcode == 8'h21) || (opcode == 8'h22))? 1'b1 : 1'b0;
    end
  endfunction


  function [0:0] is_store_operation;
    input [7:0] opcode;
    begin
      is_store_operation = ((opcode == 8'h36) || (opcode == 8'h37) || (opcode == 8'h35))? 1'b1 : 1'b0;
    end
  endfunction

  parameter BOOT_VECTOR = 32'h00000000;
  parameter ISR_VECTOR = 32'h00000000;
  reg [31:0] pc_branch_q;
  reg pc_fetch_q;
  reg [31:0] epc_q;
  reg [31:0] sr_q;
  reg [31:0] esr_q;
  reg [4:0] ex_rd_q;
  reg [31:0] ex_opcode_q;
  reg [31:0] ex_opcode_pc_q;
  reg [31:0] ex_alu_a_q;
  reg [31:0] ex_alu_b_q;
  wire [31:0] ex_result_w;
  wire [31:0] ra_resolved_w;
  wire [31:0] rb_resolved_w;
  wire operand_resolved_w;
  wire resolve_failed_w;
  wire alu_carry_out_w;
  wire alu_carry_update_w;
  wire alu_flag_update_w;
  wire compare_equal_w;
  wire compare_gts_w;
  wire compare_gt_w;
  wire compare_lts_w;
  wire compare_lt_w;
  reg [3:0] ex_alu_func_q;
  reg [4:0] load_rd_q;
  reg [7:0] load_inst_q;
  reg [1:0] load_offset_q;
  wire load_inst_w;
  wire [31:0] load_result_w;
  reg mem_load_q;
  reg mem_store_q;
  reg mem_access_q;
  wire load_pending_w;
  wire store_pending_w;
  wire load_insert_w;
  wire load_stall_w;
  reg d_mem_load_q;
  reg break_q;
  reg exc_last_q;

  altor32_alu
  alu
  (
    .op_i(ex_alu_func_q),
    .a_i(ex_alu_a_q),
    .b_i(ex_alu_b_q),
    .c_i(sr_q[10]),
    .p_o(ex_result_w),
    .c_o(alu_carry_out_w),
    .c_update_o(alu_carry_update_w),
    .equal_o(compare_equal_w),
    .greater_than_signed_o(compare_gts_w),
    .greater_than_o(compare_gt_w),
    .less_than_signed_o(compare_lts_w),
    .less_than_o(compare_lt_w),
    .flag_update_o(alu_flag_update_w)
  );


  altor32_lfu
  u_lfu
  (
    .opcode_i(load_inst_q),
    .mem_result_i(dmem_data_in_i),
    .mem_offset_i(load_offset_q),
    .load_result_o(load_result_w),
    .load_insn_o(load_inst_w)
  );


  altor32_lsu
  u_lsu
  (
    .opcode_valid_i(opcode_valid_i & ~pc_fetch_q),
    .opcode_i({ 2'b00, opcode_i[31:26] }),
    .load_pending_i(mem_load_q),
    .store_pending_i(mem_store_q),
    .rd_load_i(load_rd_q),
    .load_wb_i(d_mem_load_q),
    .mem_access_i(mem_access_q),
    .mem_ack_i(dmem_ack_i),
    .load_pending_o(load_pending_w),
    .store_pending_o(store_pending_w),
    .write_result_o(load_insert_w),
    .stall_o(load_stall_w)
  );


  altor32_dfu
  u_dfu
  (
    .ra_i(reg_ra_i),
    .rb_i(reg_rb_i),
    .ra_regval_i(reg_ra_value_i),
    .rb_regval_i(reg_rb_value_i),
    .rd_ex_i(ex_rd_q),
    .rd_wb_i(wb_rd_i),
    .load_pending_i(load_pending_w),
    .rd_load_i(load_rd_q),
    .mult_ex_i(1'b0),
    .result_ex_i(ex_result_w),
    .result_wb_i(wb_rd_value_i),
    .result_ra_o(ra_resolved_w),
    .result_rb_o(rb_resolved_w),
    .resolved_o(operand_resolved_w),
    .stall_o(resolve_failed_w)
  );

  reg [7:0] inst_r;
  reg [7:0] alu_op_r;
  reg [1:0] shift_op_r;
  reg [15:0] sfxx_op_r;
  reg [15:0] uint16_r;
  reg [31:0] uint32_r;
  reg [31:0] int32_r;
  reg [31:0] store_int32_r;
  reg [15:0] mxspr_uint16_r;
  reg [31:0] target_int26_r;
  reg [31:0] reg_ra_r;
  reg [31:0] reg_rb_r;
  reg [31:0] shift_rb_r;
  reg [31:0] shift_imm_r;

  always @(*) begin
    inst_r = { 2'b00, opcode_i[31:26] };
    alu_op_r = { opcode_i[9:6], opcode_i[3:0] };
    sfxx_op_r = { 5'b00, opcode_i[31:21] } & 16'hFD3F;
    shift_op_r = opcode_i[7:6];
    target_int26_r = sign_extend_imm26(opcode_i[25:0]);
    store_int32_r = sign_extend_imm16({ opcode_i[25:21], opcode_i[10:0] });
    uint16_r = opcode_i[15:0];
    int32_r = sign_extend_imm16(opcode_i[15:0]);
    uint32_r = extend_imm16(opcode_i[15:0]);
    reg_ra_r = ra_resolved_w;
    reg_rb_r = rb_resolved_w;
    shift_rb_r = { 26'b00, rb_resolved_w[5:0] };
    shift_imm_r = { 26'b00, opcode_i[5:0] };
    mxspr_uint16_r = reg_ra_value_i[15:0] | { 5'b00000, opcode_i[10:0] };
  end

  wire inst_add_w;assign inst_add_w = (inst_r == 8'h38) & (alu_op_r == 8'h00);
  wire inst_addc_w;assign inst_addc_w = (inst_r == 8'h38) & (alu_op_r == 8'h01);
  wire inst_and_w;assign inst_and_w = (inst_r == 8'h38) & (alu_op_r == 8'h03);
  wire inst_or_w;assign inst_or_w = (inst_r == 8'h38) & (alu_op_r == 8'h04);
  wire inst_sll_w;assign inst_sll_w = (inst_r == 8'h38) & (alu_op_r == 8'h08);
  wire inst_sra_w;assign inst_sra_w = (inst_r == 8'h38) & (alu_op_r == 8'h28);
  wire inst_srl_w;assign inst_srl_w = (inst_r == 8'h38) & (alu_op_r == 8'h18);
  wire inst_sub_w;assign inst_sub_w = (inst_r == 8'h38) & (alu_op_r == 8'h02);
  wire inst_xor_w;assign inst_xor_w = (inst_r == 8'h38) & (alu_op_r == 8'h05);
  wire inst_mul_w;assign inst_mul_w = (inst_r == 8'h38) & (alu_op_r == 8'hc6);
  wire inst_mulu_w;assign inst_mulu_w = (inst_r == 8'h38) & (alu_op_r == 8'hcb);
  wire inst_addi_w;assign inst_addi_w = inst_r == 8'h27;
  wire inst_andi_w;assign inst_andi_w = inst_r == 8'h29;
  wire inst_bf_w;assign inst_bf_w = inst_r == 8'h04;
  wire inst_bnf_w;assign inst_bnf_w = inst_r == 8'h03;
  wire inst_j_w;assign inst_j_w = inst_r == 8'h00;
  wire inst_jal_w;assign inst_jal_w = inst_r == 8'h01;
  wire inst_jalr_w;assign inst_jalr_w = inst_r == 8'h12;
  wire inst_jr_w;assign inst_jr_w = inst_r == 8'h11;
  wire inst_lbs_w;assign inst_lbs_w = inst_r == 8'h24;
  wire inst_lhs_w;assign inst_lhs_w = inst_r == 8'h26;
  wire inst_lws_w;assign inst_lws_w = inst_r == 8'h22;
  wire inst_lbz_w;assign inst_lbz_w = inst_r == 8'h23;
  wire inst_lhz_w;assign inst_lhz_w = inst_r == 8'h25;
  wire inst_lwz_w;assign inst_lwz_w = inst_r == 8'h21;
  wire inst_mfspr_w;assign inst_mfspr_w = inst_r == 8'h2D;
  wire inst_mtspr_w;assign inst_mtspr_w = inst_r == 8'h30;
  wire inst_movhi_w;assign inst_movhi_w = inst_r == 8'h06;
  wire inst_nop_w;assign inst_nop_w = inst_r == 8'h05;
  wire inst_ori_w;assign inst_ori_w = inst_r == 8'h2A;
  wire inst_rfe_w;assign inst_rfe_w = inst_r == 8'h09;
  wire inst_sb_w;assign inst_sb_w = inst_r == 8'h36;
  wire inst_sh_w;assign inst_sh_w = inst_r == 8'h37;
  wire inst_sw_w;assign inst_sw_w = inst_r == 8'h35;
  wire inst_slli_w;assign inst_slli_w = (inst_r == 8'h2E) & (shift_op_r == 2'b00);
  wire inst_srai_w;assign inst_srai_w = (inst_r == 8'h2E) & (shift_op_r == 2'b10);
  wire inst_srli_w;assign inst_srli_w = (inst_r == 8'h2E) & (shift_op_r == 2'b01);
  wire inst_xori_w;assign inst_xori_w = inst_r == 8'h2B;
  wire inst_sfxx_w;assign inst_sfxx_w = inst_r == 8'h39;
  wire inst_sfxxi_w;assign inst_sfxxi_w = inst_r == 8'h2F;
  wire inst_sfeq_w;assign inst_sfeq_w = (inst_sfxx_w || inst_sfxxi_w) & (sfxx_op_r == 16'h0520);
  wire inst_sfges_w;assign inst_sfges_w = (inst_sfxx_w || inst_sfxxi_w) & (sfxx_op_r == 16'h052B);
  wire inst_sfgeu_w;assign inst_sfgeu_w = (inst_sfxx_w || inst_sfxxi_w) & (sfxx_op_r == 16'h0523);
  wire inst_sfgts_w;assign inst_sfgts_w = (inst_sfxx_w || inst_sfxxi_w) & (sfxx_op_r == 16'h052A);
  wire inst_sfgtu_w;assign inst_sfgtu_w = (inst_sfxx_w || inst_sfxxi_w) & (sfxx_op_r == 16'h0522);
  wire inst_sfles_w;assign inst_sfles_w = (inst_sfxx_w || inst_sfxxi_w) & (sfxx_op_r == 16'h052D);
  wire inst_sfleu_w;assign inst_sfleu_w = (inst_sfxx_w || inst_sfxxi_w) & (sfxx_op_r == 16'h0525);
  wire inst_sflts_w;assign inst_sflts_w = (inst_sfxx_w || inst_sfxxi_w) & (sfxx_op_r == 16'h052C);
  wire inst_sfltu_w;assign inst_sfltu_w = (inst_sfxx_w || inst_sfxxi_w) & (sfxx_op_r == 16'h0524);
  wire inst_sfne_w;assign inst_sfne_w = (inst_sfxx_w || inst_sfxxi_w) & (sfxx_op_r == 16'h0521);
  wire inst_sys_w;assign inst_sys_w = (inst_r == 8'h08) & (opcode_i[31:24] == 8'h20);
  wire inst_trap_w;assign inst_trap_w = (inst_r == 8'h08) & (opcode_i[31:24] != 8'h21);
  reg execute_inst_r;
  reg stall_inst_r;

  always @(*) begin
    execute_inst_r = 1'b1;
    stall_inst_r = 1'b0;
    if(~opcode_valid_i | pc_fetch_q) execute_inst_r = 1'b0; 
    else if(resolve_failed_w | load_stall_w | operand_resolved_w & (inst_mfspr_w | inst_mtspr_w)) stall_inst_r = 1'b1; 
  end

  reg [31:0] next_pc_r;

  always @(*) begin
    next_pc_r = opcode_pc_i + 4;
  end

  reg [31:0] next_sr_r;
  reg compare_result_r;

  always @(*) begin
    next_sr_r = sr_q;
    if(alu_flag_update_w) next_sr_r[9] = compare_result_r; 
    if(alu_carry_update_w) next_sr_r[10] = alu_carry_out_w; 
    if(execute_inst_r & ~stall_inst_r) begin
      if(!inst_sys_w && !inst_trap_w) next_sr_r[19] = 1'b0; 
      case(1'b1)
        inst_mtspr_w: begin
          case(mxspr_uint16_r)
            16'h0011: begin
              next_sr_r = reg_rb_r;
              next_sr_r[17] = 1'b0;
              next_sr_r[18] = 1'b0;
            end
            default: ;
          endcase
        end
        inst_rfe_w: next_sr_r = esr_q;
        default: ;
      endcase
    end 
  end

  reg [31:0] next_epc_r;
  reg [31:0] next_esr_r;

  always @(*) begin
    next_epc_r = epc_q;
    next_esr_r = esr_q;
    if(exc_last_q && alu_flag_update_w) next_esr_r[9] = compare_result_r; 
    if(exc_last_q && alu_carry_update_w) next_esr_r[10] = alu_carry_out_w; 
    if(execute_inst_r & ~stall_inst_r) begin
      case(1'b1)
        inst_mtspr_w: begin
          case(mxspr_uint16_r)
            16'h0020: next_epc_r = reg_rb_r;
            16'h0040: next_esr_r = reg_rb_r;
          endcase
        end
        default: ;
      endcase
    end 
  end

  reg [3:0] alu_func_r;
  reg [31:0] alu_input_a_r;
  reg [31:0] alu_input_b_r;
  reg write_rd_r;

  always @(*) begin
    alu_func_r = 4'b0000;
    alu_input_a_r = 32'b0;
    alu_input_b_r = 32'b0;
    write_rd_r = 1'b0;
    case(1'b1)
      inst_add_w: begin
        alu_func_r = 4'b0100;
        alu_input_a_r = reg_ra_r;
        alu_input_b_r = reg_rb_r;
        write_rd_r = 1'b1;
      end
      inst_addc_w: begin
        alu_func_r = 4'b0101;
        alu_input_a_r = reg_ra_r;
        alu_input_b_r = reg_rb_r;
        write_rd_r = 1'b1;
      end
      inst_and_w: begin
        alu_func_r = 4'b0111;
        alu_input_a_r = reg_ra_r;
        alu_input_b_r = reg_rb_r;
        write_rd_r = 1'b1;
      end
      inst_or_w: begin
        alu_func_r = 4'b1000;
        alu_input_a_r = reg_ra_r;
        alu_input_b_r = reg_rb_r;
        write_rd_r = 1'b1;
      end
      inst_sll_w: begin
        alu_func_r = 4'b0001;
        alu_input_a_r = reg_ra_r;
        alu_input_b_r = shift_rb_r;
        write_rd_r = 1'b1;
      end
      inst_sra_w: begin
        alu_func_r = 4'b0011;
        alu_input_a_r = reg_ra_r;
        alu_input_b_r = shift_rb_r;
        write_rd_r = 1'b1;
      end
      inst_srl_w: begin
        alu_func_r = 4'b0010;
        alu_input_a_r = reg_ra_r;
        alu_input_b_r = shift_rb_r;
        write_rd_r = 1'b1;
      end
      inst_sub_w: begin
        alu_func_r = 4'b0110;
        alu_input_a_r = reg_ra_r;
        alu_input_b_r = reg_rb_r;
        write_rd_r = 1'b1;
      end
      inst_xor_w: begin
        alu_func_r = 4'b1001;
        alu_input_a_r = reg_ra_r;
        alu_input_b_r = reg_rb_r;
        write_rd_r = 1'b1;
      end
      inst_addi_w: begin
        alu_func_r = 4'b0100;
        alu_input_a_r = reg_ra_r;
        alu_input_b_r = int32_r;
        write_rd_r = 1'b1;
      end
      inst_andi_w: begin
        alu_func_r = 4'b0111;
        alu_input_a_r = reg_ra_r;
        alu_input_b_r = uint32_r;
        write_rd_r = 1'b1;
      end
      inst_jal_w: begin
        alu_input_a_r = next_pc_r;
        write_rd_r = 1'b1;
      end
      inst_jalr_w: begin
        alu_input_a_r = next_pc_r;
        write_rd_r = 1'b1;
      end
      inst_mfspr_w: begin
        case(mxspr_uint16_r)
          16'h0011: begin
            alu_input_a_r = next_sr_r;
            write_rd_r = 1'b1;
          end
          16'h0020: begin
            alu_input_a_r = epc_q;
            write_rd_r = 1'b1;
          end
          16'h0040: begin
            alu_input_a_r = esr_q;
            write_rd_r = 1'b1;
          end
          default: ;
        endcase
      end
      inst_movhi_w: begin
        alu_input_a_r = { uint16_r, 16'h0000 };
        write_rd_r = 1'b1;
      end
      inst_ori_w: begin
        alu_func_r = 4'b1000;
        alu_input_a_r = reg_ra_r;
        alu_input_b_r = uint32_r;
        write_rd_r = 1'b1;
      end
      inst_slli_w: begin
        alu_func_r = 4'b0001;
        alu_input_a_r = reg_ra_r;
        alu_input_b_r = shift_imm_r;
        write_rd_r = 1'b1;
      end
      inst_srai_w: begin
        alu_func_r = 4'b0011;
        alu_input_a_r = reg_ra_r;
        alu_input_b_r = shift_imm_r;
        write_rd_r = 1'b1;
      end
      inst_srli_w: begin
        alu_func_r = 4'b0010;
        alu_input_a_r = reg_ra_r;
        alu_input_b_r = shift_imm_r;
        write_rd_r = 1'b1;
      end
      inst_lbs_w, inst_lhs_w, inst_lws_w, inst_lbz_w, inst_lhz_w, inst_lwz_w: write_rd_r = 1'b1;
      inst_sfxxi_w: begin
        alu_func_r = 4'b1010;
        alu_input_a_r = reg_ra_r;
        alu_input_b_r = int32_r;
      end
      inst_sfxx_w: begin
        alu_func_r = 4'b1010;
        alu_input_a_r = reg_ra_r;
        alu_input_b_r = reg_rb_r;
      end
      inst_xori_w: begin
        alu_func_r = 4'b1001;
        alu_input_a_r = reg_ra_r;
        alu_input_b_r = int32_r;
        write_rd_r = 1'b1;
      end
      default: ;
    endcase
  end

  reg inst_sfges_r;
  reg inst_sfgeu_r;
  reg inst_sfgts_r;
  reg inst_sfgtu_r;
  reg inst_sfles_r;
  reg inst_sfleu_r;
  reg inst_sflts_r;
  reg inst_sfltu_r;
  reg inst_sfne_r;
  reg inst_sfges_q;
  reg inst_sfgeu_q;
  reg inst_sfgts_q;
  reg inst_sfgtu_q;
  reg inst_sfles_q;
  reg inst_sfleu_q;
  reg inst_sflts_q;
  reg inst_sfltu_q;
  reg inst_sfne_q;

  always @(*) begin
    inst_sfges_r = 1'b0;
    inst_sfgeu_r = 1'b0;
    inst_sfgts_r = 1'b0;
    inst_sfgtu_r = 1'b0;
    inst_sfles_r = 1'b0;
    inst_sfleu_r = 1'b0;
    inst_sflts_r = 1'b0;
    inst_sfltu_r = 1'b0;
    inst_sfne_r = 1'b0;
    if(execute_inst_r && ~stall_inst_r) begin
      case(1'b1)
        inst_sfges_w: inst_sfges_r = 1'b1;
        inst_sfgeu_w: inst_sfgeu_r = 1'b1;
        inst_sfgts_w: inst_sfgts_r = 1'b1;
        inst_sfgtu_w: inst_sfgtu_r = 1'b1;
        inst_sfles_w: inst_sfles_r = 1'b1;
        inst_sfleu_w: inst_sfleu_r = 1'b1;
        inst_sflts_w: inst_sflts_r = 1'b1;
        inst_sfltu_w: inst_sfltu_r = 1'b1;
        inst_sfne_w: inst_sfne_r = 1'b1;
        default: ;
      endcase
    end 
  end


  always @(posedge clk_i or posedge rst_i) begin
    if(rst_i == 1'b1) begin
      inst_sfges_q <= 1'b0;
      inst_sfgeu_q <= 1'b0;
      inst_sfgts_q <= 1'b0;
      inst_sfgtu_q <= 1'b0;
      inst_sfles_q <= 1'b0;
      inst_sfleu_q <= 1'b0;
      inst_sflts_q <= 1'b0;
      inst_sfltu_q <= 1'b0;
      inst_sfne_q <= 1'b0;
    end else begin
      inst_sfges_q <= inst_sfges_r;
      inst_sfgeu_q <= inst_sfgeu_r;
      inst_sfgts_q <= inst_sfgts_r;
      inst_sfgtu_q <= inst_sfgtu_r;
      inst_sfles_q <= inst_sfles_r;
      inst_sfleu_q <= inst_sfleu_r;
      inst_sflts_q <= inst_sflts_r;
      inst_sfltu_q <= inst_sfltu_r;
      inst_sfne_q <= inst_sfne_r;
    end
  end


  always @(*) begin
    case(1'b1)
      inst_sfges_q: compare_result_r = compare_gts_w | compare_equal_w;
      inst_sfgeu_q: compare_result_r = compare_gt_w | compare_equal_w;
      inst_sfgts_q: compare_result_r = compare_gts_w;
      inst_sfgtu_q: compare_result_r = compare_gt_w;
      inst_sfles_q: compare_result_r = compare_lts_w | compare_equal_w;
      inst_sfleu_q: compare_result_r = compare_lt_w | compare_equal_w;
      inst_sflts_q: compare_result_r = compare_lts_w;
      inst_sfltu_q: compare_result_r = compare_lt_w;
      inst_sfne_q: compare_result_r = ~compare_equal_w;
      default: compare_result_r = compare_equal_w;
    endcase
  end

  reg load_inst_r;
  reg store_inst_r;
  reg [31:0] mem_addr_r;

  always @(*) begin
    load_inst_r = inst_lbs_w | inst_lhs_w | inst_lws_w | inst_lbz_w | inst_lhz_w | inst_lwz_w;
    store_inst_r = inst_sb_w | inst_sh_w | inst_sw_w;
    mem_addr_r = reg_ra_r + ((store_inst_r)? store_int32_r : int32_r);
  end

  reg branch_r;
  reg branch_link_r;
  reg [31:0] branch_target_r;
  reg branch_except_r;

  always @(*) begin
    branch_r = 1'b0;
    branch_link_r = 1'b0;
    branch_except_r = 1'b0;
    branch_target_r = opcode_pc_i + { target_int26_r[29:0], 2'b00 };
    case(1'b1)
      inst_bf_w: branch_r = next_sr_r[9];
      inst_bnf_w: branch_r = ~next_sr_r[9];
      inst_j_w: branch_r = 1'b1;
      inst_jal_w: begin
        branch_link_r = 1'b1;
        branch_r = 1'b1;
      end
      inst_jalr_w: begin
        branch_link_r = 1'b1;
        branch_r = 1'b1;
        branch_target_r = reg_rb_r;
      end
      inst_jr_w: begin
        branch_r = 1'b1;
        branch_target_r = reg_rb_r;
      end
      inst_rfe_w: begin
        branch_r = 1'b1;
        branch_target_r = epc_q;
      end
      inst_sys_w: begin
        branch_r = 1'b1;
        branch_except_r = 1'b1;
        branch_target_r = ISR_VECTOR + 32'h00000400;
      end
      inst_trap_w: begin
        branch_r = 1'b1;
        branch_except_r = 1'b1;
        branch_target_r = ISR_VECTOR + 32'h00000600;
      end
      default: ;
    endcase
  end

  reg invalid_inst_r;

  always @(*) begin
    case(1'b1)
      inst_add_w, inst_addc_w, inst_and_w, inst_or_w, inst_sll_w, inst_sra_w, inst_srl_w, inst_sub_w, inst_xor_w, inst_addi_w, inst_andi_w, inst_bf_w, inst_bnf_w, inst_j_w, inst_jal_w, inst_jalr_w, inst_jr_w, inst_lbs_w, inst_lhs_w, inst_lws_w, inst_lbz_w, inst_lhz_w, inst_lwz_w, inst_mfspr_w, inst_mtspr_w, inst_movhi_w, inst_nop_w, inst_ori_w, inst_rfe_w, inst_sb_w, inst_sh_w, inst_sw_w, inst_xori_w, inst_slli_w, inst_srai_w, inst_srli_w, inst_sfeq_w, inst_sfges_w, inst_sfgeu_w, inst_sfgts_w, inst_sfgtu_w, inst_sfles_w, inst_sfleu_w, inst_sflts_w, inst_sfltu_w, inst_sfne_w, inst_sys_w, inst_trap_w: invalid_inst_r = 1'b0;
      default: invalid_inst_r = 1'b1;
    endcase
  end


  always @(posedge clk_i or posedge rst_i) begin
    if(rst_i == 1'b1) begin
      ex_alu_func_q <= 4'b0000;
      ex_alu_a_q <= 32'h00000000;
      ex_alu_b_q <= 32'h00000000;
      ex_rd_q <= 5'b00000;
    end else begin
      if(~execute_inst_r | stall_inst_r) begin
        if(load_insert_w) begin
          ex_alu_func_q <= 4'b0000;
          ex_alu_a_q <= load_result_w;
          ex_alu_b_q <= 32'b0;
          ex_rd_q <= load_rd_q;
        end else begin
          ex_alu_func_q <= 4'b0000;
          ex_alu_a_q <= 32'b0;
          ex_alu_b_q <= 32'b0;
          ex_rd_q <= 5'b0;
        end
      end else begin
        ex_alu_func_q <= alu_func_r;
        ex_alu_a_q <= alu_input_a_r;
        ex_alu_b_q <= alu_input_b_r;
        if(branch_link_r) ex_rd_q <= 5'd9; 
        else if(write_rd_r) ex_rd_q <= reg_rd_i; 
        else ex_rd_q <= 5'b0;
      end
    end
  end


  always @(posedge clk_i or posedge rst_i) begin
    if(rst_i == 1'b1) begin
      ex_opcode_q <= 32'h00000000;
      ex_opcode_pc_q <= 32'h00000000;
    end else begin
      if(~execute_inst_r | stall_inst_r) begin
        ex_opcode_q <= 32'hFC000000;
        ex_opcode_pc_q <= opcode_pc_i;
      end else begin
        ex_opcode_q <= opcode_i;
        ex_opcode_pc_q <= opcode_pc_i;
      end
    end
  end


  always @(posedge clk_i or posedge rst_i) begin
    if(rst_i == 1'b1) begin
      pc_branch_q <= 32'h00000000;
      pc_fetch_q <= 1'b0;
      exc_last_q <= 1'b0;
      epc_q <= 32'h00000000;
      sr_q <= 32'h00000000;
      esr_q <= 32'h00000000;
      fault_o <= 1'b0;
      break_q <= 1'b0;
      break_o <= 1'b0;
    end else begin
      if(break_i) break_q <= 1'b1; 
      pc_fetch_q <= 1'b0;
      exc_last_q <= 1'b0;
      break_o <= 1'b0;
      sr_q <= next_sr_r;
      epc_q <= next_epc_r;
      esr_q <= next_esr_r;
      if(execute_inst_r & ~stall_inst_r) begin
        if(invalid_inst_r || (opcode_pc_i[1:0] != 2'b00)) begin
          epc_q <= next_pc_r;
          esr_q <= next_sr_r;
          sr_q <= 32'b0;
          if(invalid_inst_r) pc_branch_q <= ISR_VECTOR + 32'h00000200; 
          else pc_branch_q <= ISR_VECTOR + 32'h00000800;
          pc_fetch_q <= 1'b1;
          exc_last_q <= 1'b1;
          fault_o <= 1'b1;
        end else if(branch_except_r) begin
          epc_q <= next_pc_r;
          esr_q <= next_sr_r;
          sr_q <= 32'b0;
          pc_branch_q <= branch_target_r;
          pc_fetch_q <= 1'b1;
          exc_last_q <= 1'b1;
          if(inst_trap_w) break_o <= 1'b1; 
        end else if((sr_q[19] || break_q) && sr_q[20]) begin
          if(branch_r) epc_q <= branch_target_r; 
          else epc_q <= next_pc_r;
          esr_q <= next_sr_r;
          sr_q <= 32'b0;
          break_q <= 1'b0;
          break_o <= 1'b1;
          pc_branch_q <= ISR_VECTOR + 32'h00000600;
          pc_fetch_q <= 1'b1;
          exc_last_q <= 1'b1;
        end else if(intr_i && next_sr_r[2]) begin
          if(branch_r) epc_q <= branch_target_r; 
          else epc_q <= next_pc_r;
          esr_q <= next_sr_r;
          sr_q <= 32'b0;
          pc_branch_q <= ISR_VECTOR + 32'h00000300;
          pc_fetch_q <= 1'b1;
          exc_last_q <= 1'b1;
        end else if(branch_r) begin
          pc_branch_q <= branch_target_r;
          pc_fetch_q <= 1'b1;
        end 
      end 
    end
  end


  always @(posedge clk_i or posedge rst_i) begin
    if(rst_i == 1'b1) begin
      dmem_addr_o <= 32'h00000000;
      dmem_data_out_o <= 32'h00000000;
      dmem_we_o <= 1'b0;
      dmem_sel_o <= 4'b0000;
      dmem_stb_o <= 1'b0;
      dmem_cyc_o <= 1'b0;
      mem_load_q <= 1'b0;
      mem_store_q <= 1'b0;
      mem_access_q <= 1'b0;
      load_rd_q <= 5'b00000;
      load_inst_q <= 8'h00;
      load_offset_q <= 2'b00;
      d_mem_load_q <= 1'b0;
    end else begin
      if(~dmem_stall_i) dmem_stb_o <= 1'b0; 
      if(dmem_ack_i) dmem_cyc_o <= 1'b0; 
      mem_access_q <= 1'b0;
      d_mem_load_q <= mem_access_q & mem_load_q;
      mem_load_q <= load_pending_w;
      mem_store_q <= store_pending_w;
      if(execute_inst_r & ~stall_inst_r) begin
        if(branch_link_r) begin
          if(load_rd_q == 5'd9) load_rd_q <= 5'b00000; 
        end else if(write_rd_r) begin
          if((reg_rd_i == load_rd_q) && ~load_inst_r) load_rd_q <= 5'b00000; 
        end 
        case(1'b1)
          load_inst_r: begin
            dmem_addr_o <= mem_addr_r;
            dmem_data_out_o <= 32'h00000000;
            dmem_sel_o <= 4'b1111;
            dmem_we_o <= 1'b0;
            dmem_stb_o <= 1'b1;
            dmem_cyc_o <= 1'b1;
            mem_load_q <= 1'b1;
            mem_access_q <= 1'b1;
            load_rd_q <= reg_rd_i;
            load_inst_q <= inst_r;
            load_offset_q <= mem_addr_r[1:0];
          end
          inst_sb_w: begin
            dmem_addr_o <= mem_addr_r;
            mem_access_q <= 1'b1;
            case(mem_addr_r[1:0])
              2'b00: begin
                dmem_data_out_o <= { reg_rb_r[7:0], 24'h000000 };
                dmem_sel_o <= 4'b1000;
                dmem_we_o <= 1'b1;
                dmem_stb_o <= 1'b1;
                dmem_cyc_o <= 1'b1;
                mem_store_q <= 1'b1;
              end
              2'b01: begin
                dmem_data_out_o <= { { 8'h00, reg_rb_r[7:0] }, 16'h0000 };
                dmem_sel_o <= 4'b0100;
                dmem_we_o <= 1'b1;
                dmem_stb_o <= 1'b1;
                dmem_cyc_o <= 1'b1;
                mem_store_q <= 1'b1;
              end
              2'b10: begin
                dmem_data_out_o <= { { 16'h0000, reg_rb_r[7:0] }, 8'h00 };
                dmem_sel_o <= 4'b0010;
                dmem_we_o <= 1'b1;
                dmem_stb_o <= 1'b1;
                dmem_cyc_o <= 1'b1;
                mem_store_q <= 1'b1;
              end
              2'b11: begin
                dmem_data_out_o <= { 24'h000000, reg_rb_r[7:0] };
                dmem_sel_o <= 4'b0001;
                dmem_we_o <= 1'b1;
                dmem_stb_o <= 1'b1;
                dmem_cyc_o <= 1'b1;
                mem_store_q <= 1'b1;
              end
              default: ;
            endcase
          end
          inst_sh_w: begin
            dmem_addr_o <= mem_addr_r;
            mem_access_q <= 1'b1;
            case(mem_addr_r[1:0])
              2'b00: begin
                dmem_data_out_o <= { reg_rb_r[15:0], 16'h0000 };
                dmem_sel_o <= 4'b1100;
                dmem_we_o <= 1'b1;
                dmem_stb_o <= 1'b1;
                dmem_cyc_o <= 1'b1;
                mem_store_q <= 1'b1;
              end
              2'b10: begin
                dmem_data_out_o <= { 16'h0000, reg_rb_r[15:0] };
                dmem_sel_o <= 4'b0011;
                dmem_we_o <= 1'b1;
                dmem_stb_o <= 1'b1;
                dmem_cyc_o <= 1'b1;
                mem_store_q <= 1'b1;
              end
              default: ;
            endcase
          end
          inst_sw_w: begin
            dmem_addr_o <= mem_addr_r;
            dmem_data_out_o <= reg_rb_r;
            dmem_sel_o <= 4'b1111;
            dmem_we_o <= 1'b1;
            dmem_stb_o <= 1'b1;
            dmem_cyc_o <= 1'b1;
            mem_access_q <= 1'b1;
            mem_store_q <= 1'b1;
          end
          default: ;
        endcase
      end 
    end
  end


  always @(posedge clk_i or posedge rst_i) begin
    if(rst_i == 1'b1) begin
      icache_flush_o <= 1'b0;
      dcache_flush_o <= 1'b0;
    end else begin
      icache_flush_o <= 1'b0;
      dcache_flush_o <= 1'b0;
      if(execute_inst_r & ~stall_inst_r) begin
        case(1'b1)
          inst_mtspr_w: begin
            case(mxspr_uint16_r)
              16'h0011: begin
                icache_flush_o <= reg_rb_r[17];
                dcache_flush_o <= reg_rb_r[18];
              end
            endcase
          end
          default: ;
        endcase
      end 
    end
  end

  assign branch_pc_o = pc_branch_q;
  assign branch_o = pc_fetch_q;
  assign stall_o = stall_inst_r;
  assign opcode_o = ex_opcode_q;
  assign opcode_pc_o = ex_opcode_pc_q;
  assign reg_rd_o = ex_rd_q;
  assign reg_rd_value_o = ex_result_w;
  assign mult_res_o = 64'b0;

endmodule

