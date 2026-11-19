

module light8080
(
  clk,
  reset,
  addr_out,
  vma,
  io,
  rd,
  wr,
  fetch,
  data_in,
  data_out,
  inta,
  inte,
  halt,
  intr
);

  input clk;
  input reset;
  output [15:0] addr_out;
  output vma;
  output io;
  output rd;
  output wr;
  output fetch;
  input [7:0] data_in;
  output [7:0] data_out;
  output inta;
  output inte;
  output halt;
  input intr;
  reg [7:0] addr_low;
  reg [7:0] IR;
  wire [2:0] s_field;
  wire [2:0] d_field;
  wire [1:0] p_field;
  wire rbh;
  wire [3:0] alu_op;
  reg [7:0] uc_addr;
  reg [8:0] next_uc_addr;
  wire [7:0] uc_jmp_addr;
  reg [7:0] uc_ret_addr;
  wire [7:0] addr_plus_1;
  reg do_reset;
  wire [2:0] uc_flags1;
  wire [2:0] uc_flags2;
  wire [3:0] uc_addr_sel;
  wire uc_jsr;
  wire uc_tjsr;
  wire uc_decode;
  wire uc_end;
  reg condition_reg;
  reg condition;
  wire uc_do_jmp;
  wire uc_do_ret;
  wire uc_halt_flag;
  wire uc_halt;
  reg halt_reg;
  wire uc_ei;
  wire uc_di;
  reg inte_reg;
  reg int_pending;
  reg inta_reg;
  wire clr_t1;
  wire do_clr_t1;
  wire clr_t2;
  wire do_clr_t2;
  wire [31:0] ucode;
  reg [24:0] ucode_field2;
  reg delayed_ei;
  wire load_al;
  wire load_addr;
  wire load_t1;
  wire load_t2;
  wire mux_in;
  wire load_do;
  wire [1:0] rb_addr_sel;
  wire [3:0] ra_field;
  wire [7:0] rbank_data;
  reg [7:0] alu_output;
  wire [7:0] data_output;
  reg [7:0] T1;
  reg [7:0] T2;
  wire [7:0] alu_input;
  wire we_rb;
  wire inhibit_pc_increment;
  reg [3:0] rbank_rd_addr;
  wire [3:0] rbank_wr_addr;
  reg [7:0] DO;
  reg [7:0] rbank [0:15];
  reg [7:0] flag_reg;
  wire [1:0] flag_pattern;
  wire flag_s;
  wire flag_z;
  wire flag_p;
  wire flag_cy;
  wire flag_cy_1;
  wire flag_cy_2;
  wire do_cy_op;
  wire do_cy_op_d;
  wire do_cpc;
  wire do_cpc_d;
  wire do_daa;
  wire clear_cy;
  wire clear_ac;
  wire set_ac;
  wire flag_ac;
  wire flag_aux_cy;
  wire load_psw;
  wire use_aux;
  wire use_aux_cy;
  reg reg_aux_cy;
  wire aux_cy_in;
  wire set_aux_cy;
  wire set_aux;
  wire [1:0] alu_fn;
  wire use_logic;
  wire [1:0] mux_fn;
  wire use_psw;
  wire [8:0] arith_op1;
  wire [8:0] arith_op2;
  wire [8:0] arith_op2_sgn;
  wire [8:0] arith_res;
  wire [7:0] arith_res8;
  wire [8:0] daa_res;
  reg [8:0] daa_res9;
  wire daa_test1;
  wire daa_test1a;
  wire daa_test2;
  wire [7:0] arith_daa_res;
  wire cy_daa;
  wire cy_in_sgn;
  wire cy_in;
  wire cy_in_gated;
  wire cy_adder;
  wire cy_arith;
  wire cy_shifter;
  reg [7:0] logic_res;
  wire [7:0] shift_res;
  wire [7:0] alu_mux1;

  always @(posedge clk) begin
    if(uc_decode) IR <= data_in;
  end

  assign s_field = IR[2:0];
  assign d_field = IR[5:3];
  assign p_field = IR[5:4];

  always @(posedge clk) do_reset <= reset;

  assign uc_flags1 = ucode[31:29];
  assign uc_flags2 = ucode[28:26];
  assign uc_do_ret = ((uc_flags2 == 3'b011) && !do_reset)? 1'b1 : 1'b0;
  assign uc_jsr = ((uc_flags2 == 3'b010) && !do_reset)? 1'b1 : 1'b0;
  assign uc_tjsr = ((uc_flags2 == 3'b100) && !do_reset)? 1'b1 : 1'b0;
  assign uc_decode = ((uc_flags1 == 3'b001) && !do_reset)? 1'b1 : 1'b0;
  assign uc_end = (((uc_flags2 == 3'b001) || uc_tjsr && !condition_reg) && !do_reset)? 1'b1 : 1'b0;
  assign uc_halt_flag = (uc_flags1 == 3'b111)? 1'b1 : 1'b0;
  assign uc_halt = (uc_halt_flag && !inta_reg)? 1'b1 : 1'b0;
  assign uc_ei = (uc_flags1 == 3'b011)? 1'b1 : 1'b0;
  assign uc_di = 1'b1;
  assign clr_t2 = (uc_flags2 == 3'b001)? 1'b1 : 1'b0;
  assign clr_t1 = (uc_flags1 == 3'b110)? 1'b1 : 1'b0;
  assign use_aux = (uc_flags1 == 3'b101)? 1'b1 : 1'b0;
  assign set_aux = (uc_flags2 == 3'b111)? 1'b1 : 1'b0;
  assign load_al = ucode[24];
  assign load_addr = ucode[25];
  assign do_cy_op_d = (ucode[5:2] == 4'b1011)? 1'b1 : 1'b0;
  assign do_cpc_d = ucode[0];
  assign uc_do_jmp = uc_jsr | uc_tjsr & condition_reg;
  assign vma = load_addr;
  assign fetch = ((uc_addr[7:4] == 4'b0) && load_addr)? 1'b0 : 1'b0;
  assign io = (uc_flags1 == 3'b100)? 1'b1 : 1'b0;
  assign rd = (uc_flags2 == 3'b101)? 1'b1 : 1'b0;
  assign wr = (uc_flags2 == 3'b110)? 1'b1 : 1'b0;
  assign uc_jmp_addr = { ucode[11:10], ucode[5:0] };
  assign uc_addr_sel = { uc_do_ret, uc_do_jmp, uc_decode, uc_end };
  assign addr_plus_1 = uc_addr + 8'd1;

  always @(*) begin
    case(uc_addr_sel)
      4'b1000: next_uc_addr <= { 1'b0, uc_ret_addr };
      4'b0100: next_uc_addr <= { 1'b0, uc_jmp_addr };
      4'b0000: next_uc_addr <= { 1'b0, addr_plus_1 };
      4'b0001: next_uc_addr <= { 6'b0, uc_halt, 2'b11 };
      default: next_uc_addr <= { 1'b0, data_in };
    endcase
  end


  micro_rom
  rom
  (
    .clock(clk),
    .uc_addr(next_uc_addr),
    .uc_dout(ucode)
  );


  always @(posedge clk) begin
    if(reset) uc_addr <= 8'h0;
    else uc_addr <= next_uc_addr[7:0];
  end


  always @(posedge clk) begin
    if(reset) uc_ret_addr <= 8'h0;
    else if(uc_do_jmp) uc_ret_addr <= addr_plus_1;
  end

  assign alu_op = ucode[3:0];

  always @(posedge clk) begin
    ucode_field2 <= { do_cy_op_d, do_cpc_d, clr_t2, clr_t1, set_aux, use_aux, rbank_rd_addr, ucode[14:4], alu_op };
  end


  always @(posedge clk) begin
    if(reset || int_pending) halt_reg <= 1'b0;
    else if(uc_halt) halt_reg <= 1'b1;
  end

  assign halt = halt_reg;

  always @(posedge clk) begin
    if(reset) begin
      inte_reg <= 1'b0;
      delayed_ei <= 1'b0;
    end else begin
      if((uc_di || uc_ei) && uc_end) begin
        delayed_ei <= uc_ei;
      end
      if(uc_end) begin
        if(uc_di) inte_reg <= 1'b0;
        else inte_reg <= delayed_ei;
      end
    end
  end

  assign inte = inte_reg;

  always @(posedge clk) begin
    if(reset) int_pending <= 1'b0;
    else begin
      if((intr && inte_reg || !int_pending) && !inta_reg) int_pending <= 1'b1;
      else if(inte_reg && uc_end) int_pending <= 1'b0;
    end
  end


  always @(posedge clk) begin
    if(reset) inta_reg <= 1'b0;
    else if(int_pending && uc_end) inta_reg <= 1'b1;
    else if(uc_end && !uc_halt_flag) inta_reg <= 1'b0;
  end

  assign inta = inta_reg;
  assign ra_field = ucode[18:15];
  assign load_t1 = ucode[23];
  assign load_t2 = ucode[22];
  assign mux_in = ucode[21];
  assign rb_addr_sel = ucode[20:19];
  assign load_do = ucode_field2[7];
  assign set_aux_cy = ucode_field2[20];
  assign do_clr_t1 = ucode_field2[21];
  assign do_clr_t2 = ucode_field2[22];

  always @(posedge clk) begin
    if(reset || uc_decode || do_clr_t1) T1 <= 8'h0;
    else if(load_t1) T1 <= alu_input;
  end


  always @(posedge clk) begin
    if(reset || uc_decode || do_clr_t2) T2 <= 8'h0;
    else if(load_t2) T2 <= alu_input;
  end

  assign alu_input = (mux_in)? rbank_data : data_in;
  assign rbh = (p_field == 2'b11)? 1'b1 : 1'b0;

  always @(*) begin
    case(rb_addr_sel)
      2'b00: rbank_rd_addr <= ra_field;
      2'b01: rbank_rd_addr <= { 1'b0, s_field };
      2'b10: rbank_rd_addr <= { 1'b0, d_field };
      2'b11: rbank_rd_addr <= { rbh, p_field, ra_field[0] };
    endcase
  end

  assign inhibit_pc_increment = (inta_reg && use_aux_cy && (rbank_wr_addr[3:1] == 3'b100))? 1'b1 : 1'b0;
  assign we_rb = ucode_field2[6] & ~inhibit_pc_increment;
  assign rbank_wr_addr = ucode_field2[18:15];

  always @(posedge clk) begin
    if(we_rb) rbank[rbank_wr_addr] <= alu_output;
  end

  assign rbank_data = rbank[rbank_rd_addr];
  assign use_psw = (ucode_field2[5:4] == 2'b11)? 1'b1 : 1'b0;
  assign data_output = (use_psw)? flag_reg : alu_output;

  always @(posedge clk) begin
    if(load_do) DO <= data_output;
  end

  assign alu_fn = ucode_field2[1:0];
  assign use_logic = ucode_field2[2];
  assign mux_fn = ucode_field2[4:3];
  assign flag_pattern = ucode_field2[9:8];
  assign use_aux_cy = ucode_field2[19];
  assign do_cpc = ucode_field2[23];
  assign do_cy_op = ucode_field2[24];
  assign do_daa = (ucode_field2[5:2] == 4'b1010)? 1'b1 : 1'b0;
  assign clear_cy = ucode_field2[14];
  assign clear_ac = (ucode_field2[14] && (ucode_field2[5:0] != 6'b000100))? 1'b1 : 1'b0;
  assign set_ac = (ucode_field2[14] && (ucode_field2[5:0] == 6'b000100))? 1'b1 : 1'b0;
  assign aux_cy_in = (!set_aux_cy)? reg_aux_cy : 1'b1;
  assign cy_in = (!use_aux_cy)? flag_reg[0] : aux_cy_in;
  assign cy_in_gated = cy_in & alu_fn[0];
  assign arith_op1 = { 1'b0, T2 };
  assign arith_op2 = { 1'b0, T1 };
  assign arith_op2_sgn = (!alu_fn[1])? arith_op2 : ~arith_op2;
  assign cy_in_sgn = (!alu_fn[1])? cy_in_gated : ~cy_in_gated;
  assign arith_res = arith_op1 + arith_op2_sgn + cy_in_sgn;
  assign arith_res8 = arith_res[7:0];
  assign cy_adder = arith_res[8];
  assign daa_test1a = arith_op2[3] & (arith_op2[2] | arith_op2[1] | arith_op2[0]);
  assign daa_test1 = (flag_reg[4] || daa_test1a)? 1'b1 : 1'b0;

  always @(posedge clk) begin
    if(reset) daa_res9 <= 9'b0;
    else if(daa_test1) daa_res9 <= arith_op2 + 9'd6;
    else daa_res9 <= arith_op2;
  end

  assign daa_test2 = (flag_reg[0] || daa_test1a)? 1'b1 : 1'b0;
  assign daa_res = (daa_test2)? { 1'b0, daa_res9[7:0] } + 9'h60 : daa_res9;
  assign cy_daa = daa_res[8];
  assign arith_daa_res = (do_daa)? daa_res[7:0] : arith_res8;
  assign cy_arith = (do_daa)? cy_daa : cy_adder;

  always @(*) begin
    case(alu_fn)
      2'b00: logic_res <= T1 & T2;
      2'b01: logic_res <= T1 ^ T2;
      2'b10: logic_res <= T1 | T2;
      2'b11: logic_res <= ~T1;
    endcase
  end

  assign shift_res[6:1] = (!alu_fn[0])? T1[5:0] : T1[7:2];
  assign shift_res[0] = (alu_fn == 2'b00)? T1[7] :
                        (alu_fn == 2'b10)? cy_in : T1[1];
  assign shift_res[7] = (alu_fn == 2'b01)? T1[0] :
                        (alu_fn == 2'b11)? cy_in : T1[6];
  assign cy_shifter = (!alu_fn[0])? T1[7] : T1[0];
  assign alu_mux1 = (use_logic)? logic_res : shift_res;

  always @(*) begin
    case(mux_fn)
      2'b00: alu_output <= alu_mux1;
      2'b01: alu_output <= arith_daa_res;
      2'b10: alu_output <= ~alu_mux1;
      2'b11: alu_output <= { 2'b0, d_field, 3'b0 };
    endcase
  end

  assign flag_s = alu_output[7];
  assign flag_p = ~(^alu_output);
  assign flag_z = (alu_output == 8'h0)? 1'b1 : 1'b0;
  assign flag_ac = (set_ac)? 1'b1 :
                   (clear_ac)? 1'b0 : arith_op1[4] ^ arith_op2_sgn[4] ^ alu_output[4];
  assign flag_cy_1 = (clear_cy)? 1'b0 :
                     (use_logic)? cy_arith : cy_shifter;
  assign flag_cy_2 = (!do_cpc)? ~flag_reg[0] : 1'b1;
  assign flag_cy = (!do_cy_op)? flag_cy_1 : flag_cy_2;
  assign flag_aux_cy = cy_adder;

  always @(posedge clk) begin
    if(reset || uc_decode) reg_aux_cy <= 1'b1;
    else reg_aux_cy <= flag_aux_cy;
  end

  assign load_psw = (we_rb && (rbank_wr_addr == 4'b0110))? 1'b1 : 1'b0;

  always @(posedge clk) begin
    if(reset) begin
      flag_reg[7] <= 1'b0;
      flag_reg[6] <= 1'b0;
      flag_reg[5] <= 1'b0;
      flag_reg[4] <= 1'b0;
      flag_reg[3] <= 1'b0;
      flag_reg[2] <= 1'b0;
      flag_reg[1] <= 1'b1;
      flag_reg[0] <= 1'b0;
    end else begin
      if(flag_pattern[1]) begin
        if(load_psw) begin
          flag_reg[7] <= alu_output[7];
          flag_reg[6] <= alu_output[6];
          flag_reg[4] <= alu_output[4];
          flag_reg[2] <= alu_output[2];
        end else begin
          flag_reg[7] <= flag_s;
          flag_reg[6] <= flag_z;
          flag_reg[4] <= flag_ac;
          flag_reg[2] <= flag_p;
        end
      end
      if(flag_pattern[0]) begin
        if(load_psw) flag_reg[0] <= alu_output[0];
        else flag_reg[0] <= flag_cy;
      end
      flag_reg[5] <= 1'b0;
      flag_reg[3] <= 1'b0;
      flag_reg[1] <= 1'b1;
    end
  end


  always @(*) begin
    case(d_field[2:0])
      3'b000: condition <= ~flag_reg[6];
      3'b001: condition <= flag_reg[6];
      3'b010: condition <= ~flag_reg[0];
      3'b011: condition <= flag_reg[0];
      3'b100: condition <= ~flag_reg[2];
      3'b101: condition <= flag_reg[2];
      3'b110: condition <= ~flag_reg[7];
      3'b111: condition <= flag_reg[7];
    endcase
  end


  always @(posedge clk) begin
    if(reset) condition_reg <= 1'b0;
    else condition_reg <= condition;
  end


  always @(posedge clk) begin
    if(reset) addr_low <= 8'h0;
    else if(load_al) addr_low <= rbank_data;
  end

  assign addr_out = { rbank_data, addr_low };
  assign data_out = DO;

endmodule

