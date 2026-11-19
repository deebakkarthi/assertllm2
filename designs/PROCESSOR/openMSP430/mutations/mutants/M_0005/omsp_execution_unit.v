

module omsp_execution_unit
(
  cpuoff,
  dbg_reg_din,
  gie,
  mab,
  mb_en,
  mb_wr,
  mdb_out,
  oscoff,
  pc_sw,
  pc_sw_wr,
  scg0,
  scg1,
  dbg_halt_st,
  dbg_mem_dout,
  dbg_reg_wr,
  e_state,
  exec_done,
  inst_ad,
  inst_as,
  inst_alu,
  inst_bw,
  inst_dest,
  inst_dext,
  inst_irq_rst,
  inst_jmp,
  inst_mov,
  inst_sext,
  inst_so,
  inst_src,
  inst_type,
  mclk,
  mdb_in,
  pc,
  pc_nxt,
  puc_rst,
  scan_enable
);

  output cpuoff;
  output [15:0] dbg_reg_din;
  output gie;
  output [15:0] mab;
  output mb_en;
  output [1:0] mb_wr;
  output [15:0] mdb_out;
  output oscoff;
  output [15:0] pc_sw;
  output pc_sw_wr;
  output scg0;
  output scg1;
  input dbg_halt_st;
  input [15:0] dbg_mem_dout;
  input dbg_reg_wr;
  input [3:0] e_state;
  input exec_done;
  input [7:0] inst_ad;
  input [7:0] inst_as;
  input [11:0] inst_alu;
  input inst_bw;
  input [15:0] inst_dest;
  input [15:0] inst_dext;
  input inst_irq_rst;
  input [7:0] inst_jmp;
  input inst_mov;
  input [15:0] inst_sext;
  input [7:0] inst_so;
  input [15:0] inst_src;
  input [2:0] inst_type;
  input mclk;
  input [15:0] mdb_in;
  input [15:0] pc;
  input [15:0] pc_nxt;
  input puc_rst;
  input scan_enable;
  wire [15:0] alu_out;
  wire [15:0] alu_out_add;
  wire [3:0] alu_stat;
  wire [3:0] alu_stat_wr;
  wire [15:0] op_dst;
  wire [15:0] op_src;
  wire [15:0] reg_dest;
  wire [15:0] reg_src;
  wire [15:0] mdb_in_bw;
  wire [15:0] mdb_in_val;
  wire [3:0] status;
  wire reg_dest_wr;assign reg_dest_wr = (e_state == 4'hB) & (inst_type[2] & inst_ad[0] & ~inst_alu[11] | inst_type[0] & inst_as[0] & ~(inst_so[4] | inst_so[5] | inst_so[6]) | inst_type[1]) | dbg_reg_wr;
  wire reg_sp_wr;assign reg_sp_wr = ((e_state == 4'h1) | (e_state == 4'h3)) & ~inst_irq_rst | (e_state == 4'h9) & ((inst_so[4] | inst_so[5]) & ~inst_as[1] & ~((inst_as[2] | inst_as[3]) & inst_src[1])) | (e_state == 4'h5) & ((inst_so[4] | inst_so[5]) & inst_as[1]) | (e_state == 4'h6) & ((inst_so[4] | inst_so[5]) & ((inst_as[2] | inst_as[3]) & inst_src[1]));
  wire reg_sr_wr;assign reg_sr_wr = (e_state == 4'h9) & inst_so[6];
  wire reg_sr_clr;assign reg_sr_clr = e_state == 4'h0;
  wire reg_pc_call;assign reg_pc_call = (e_state == 4'hB) & inst_so[5] | (e_state == 4'hA) & inst_so[6];
  wire reg_incr;assign reg_incr = exec_done & inst_as[3] | (e_state == 4'h6) & inst_so[6] | (e_state == 4'hB) & inst_so[6];
  assign dbg_reg_din = reg_dest;

  omsp_register_file
  register_file_0
  (
    .cpuoff(cpuoff),
    .gie(gie),
    .oscoff(oscoff),
    .pc_sw(pc_sw),
    .pc_sw_wr(pc_sw_wr),
    .reg_dest(reg_dest),
    .reg_src(reg_src),
    .scg0(scg0),
    .scg1(scg1),
    .status(status),
    .alu_stat(alu_stat),
    .alu_stat_wr(alu_stat_wr),
    .inst_bw(inst_bw),
    .inst_dest(inst_dest),
    .inst_src(inst_src),
    .mclk(mclk),
    .pc(pc),
    .puc_rst(puc_rst),
    .reg_dest_val(alu_out),
    .reg_dest_wr(reg_dest_wr),
    .reg_pc_call(reg_pc_call),
    .reg_sp_val(alu_out_add),
    .reg_sp_wr(reg_sp_wr),
    .reg_sr_clr(reg_sr_clr),
    .reg_sr_wr(reg_sr_wr),
    .reg_incr(reg_incr),
    .scan_enable(scan_enable)
  );

  wire src_reg_src_sel;assign src_reg_src_sel = (e_state == 4'h2) | (e_state == 4'h0) | (e_state == 4'h6) & ~inst_as[6] | (e_state == 4'h7) & ~inst_as[6] | (e_state == 4'hB) & inst_as[0] & ~inst_type[1];
  wire src_reg_dest_sel;assign src_reg_dest_sel = (e_state == 4'h1) | (e_state == 4'h3) | (e_state == 4'h9) & (inst_so[4] | inst_so[5]) | (e_state == 4'h5) & (inst_so[4] | inst_so[5]) & inst_as[1];
  wire src_mdb_in_val_sel;assign src_mdb_in_val_sel = (e_state == 4'h9) & inst_so[6] | (e_state == 4'hB) & (inst_as[2] | inst_as[3] | inst_as[1] | inst_as[4] | inst_as[6]);
  wire src_inst_dext_sel;assign src_inst_dext_sel = (e_state == 4'h9) & ~(inst_so[4] | inst_so[5]) | (e_state == 4'hA) & ~(inst_so[4] | inst_so[5] | inst_so[6]);
  wire src_inst_sext_sel;assign src_inst_sext_sel = (e_state == 4'hB) & (inst_type[1] | inst_as[5] | inst_as[7] | inst_so[6]);
  assign op_src = (src_reg_src_sel)? reg_src : 
                  (src_reg_dest_sel)? reg_dest : 
                  (src_mdb_in_val_sel)? mdb_in_val : 
                  (src_inst_dext_sel)? inst_dext : 
                  (src_inst_sext_sel)? inst_sext : 16'h0000;
  wire dst_inst_sext_sel;assign dst_inst_sext_sel = (e_state == 4'h6) & (inst_as[1] | inst_as[4] | inst_as[6]) | (e_state == 4'h7) & (inst_as[1] | inst_as[4] | inst_as[6]);
  wire dst_mdb_in_bw_sel;assign dst_mdb_in_bw_sel = (e_state == 4'hA) & inst_so[6] | (e_state == 4'hB) & ~(inst_ad[0] | inst_type[1] | inst_type[0]) & ~inst_so[6];
  wire dst_fffe_sel;assign dst_fffe_sel = (e_state == 4'h2) | (e_state == 4'h1) | (e_state == 4'h3) | (e_state == 4'h9) & (inst_so[4] | inst_so[5]) & ~inst_so[6] | (e_state == 4'h5) & (inst_so[4] | inst_so[5]) & inst_as[1] | (e_state == 4'h6) & (inst_so[4] | inst_so[5]) & (inst_as[2] | inst_as[3]) & inst_src[1];
  wire dst_reg_dest_sel;assign dst_reg_dest_sel = (e_state == 4'h9) & ~(inst_so[4] | inst_so[5] | inst_ad[6] | inst_so[6]) | (e_state == 4'hA) & ~inst_ad[6] | (e_state == 4'hB) & (inst_ad[0] | inst_type[1] | inst_type[0]) & ~inst_so[6];
  assign op_dst = (dst_inst_sext_sel)? inst_sext : 
                  (dst_mdb_in_bw_sel)? mdb_in_bw : 
                  (dst_reg_dest_sel)? reg_dest : 
                  (dst_fffe_sel)? 16'hfffe : 16'h0000;
  wire exec_cycle;assign exec_cycle = e_state == 4'hB;

  omsp_alu
  alu_0
  (
    .alu_out(alu_out),
    .alu_out_add(alu_out_add),
    .alu_stat(alu_stat),
    .alu_stat_wr(alu_stat_wr),
    .dbg_halt_st(dbg_halt_st),
    .exec_cycle(exec_cycle),
    .inst_alu(inst_alu),
    .inst_bw(inst_bw),
    .inst_jmp(inst_jmp),
    .inst_so(inst_so),
    .op_dst(op_dst),
    .op_src(op_src),
    .status(status)
  );

  wire mb_rd_det;assign mb_rd_det = (e_state == 4'h6) & ~inst_as[5] | (e_state == 4'hB) & inst_so[6] | (e_state == 4'h9) & ~inst_type[0] & ~inst_mov;
  wire mb_wr_det;assign mb_wr_det = (e_state == 4'h1) & ~inst_irq_rst | (e_state == 4'h3) & ~inst_irq_rst | (e_state == 4'hA) & ~inst_so[6] | (e_state == 4'h7);
  wire [1:0] mb_wr_msk;assign mb_wr_msk = (inst_alu[11])? 2'b00 : 
                     (~inst_bw)? 2'b11 : 
                     (alu_out_add[0])? 2'b10 : 2'b01;
  assign mb_en = mb_rd_det | mb_wr_det & ~inst_alu[11];
  assign mb_wr = { 2{ mb_wr_det } } & mb_wr_msk;
  assign mab = alu_out_add[15:0];
  reg [15:0] mdb_out_nxt;
  wire mdb_out_nxt_en;assign mdb_out_nxt_en = (e_state == 4'h9) | ((e_state == 4'hB) & ~inst_so[5] | (e_state == 4'h2) | (e_state == 4'h0));
  wire mclk_mdb_out_nxt;

  omsp_clock_gate
  clock_gate_mdb_out_nxt
  (
    .gclk(mclk_mdb_out_nxt),
    .clk(mclk),
    .enable(mdb_out_nxt_en),
    .scan_enable(scan_enable)
  );


  always @(posedge mclk_mdb_out_nxt or posedge puc_rst) if(puc_rst) mdb_out_nxt <= 16'h0000; 
  else if(e_state == 4'h9) mdb_out_nxt <= pc_nxt; 
  else mdb_out_nxt <= alu_out;

  assign mdb_out = (inst_bw)? { 2{ mdb_out_nxt[7:0] } } : mdb_out_nxt;
  reg mab_lsb;

  always @(posedge mclk or posedge puc_rst) if(puc_rst) mab_lsb <= 1'b0; 
  else if(mb_en) mab_lsb <= alu_out_add[0]; 

  assign mdb_in_bw = (~inst_bw)? mdb_in : 
                     (mab_lsb)? { 2{ mdb_in[15:8] } } : mdb_in;
  reg mdb_in_buf_en;

  always @(posedge mclk or posedge puc_rst) if(puc_rst) mdb_in_buf_en <= 1'b0; 
  else mdb_in_buf_en <= e_state == 4'h6;

  reg mdb_in_buf_valid;

  always @(posedge mclk or posedge puc_rst) if(puc_rst) mdb_in_buf_valid <= 1'b0; 
  else if(e_state == 4'hB) mdb_in_buf_valid <= 1'b0; 
  else if(mdb_in_buf_en) mdb_in_buf_valid <= 1'b1; 

  reg [15:0] mdb_in_buf;
  wire mclk_mdb_in_buf;

  omsp_clock_gate
  clock_gate_mdb_in_buf
  (
    .gclk(mclk_mdb_in_buf),
    .clk(mclk),
    .enable(mdb_in_buf_en),
    .scan_enable(scan_enable)
  );


  always @(posedge mclk_mdb_in_buf or posedge puc_rst) if(puc_rst) mdb_in_buf <= 16'h0000; 
  else mdb_in_buf <= mdb_in_bw;

  assign mdb_in_val = (mdb_in_buf_valid)? mdb_in_buf : mdb_in_bw;
  wire UNUSED_inst_ad_idx;assign UNUSED_inst_ad_idx = inst_ad[1];
  wire UNUSED_inst_ad_indir;assign UNUSED_inst_ad_indir = inst_ad[2];
  wire UNUSED_inst_ad_indir_i;assign UNUSED_inst_ad_indir_i = inst_ad[3];
  wire UNUSED_inst_ad_symb;assign UNUSED_inst_ad_symb = inst_ad[4];
  wire UNUSED_inst_ad_imm;assign UNUSED_inst_ad_imm = inst_ad[5];
  wire UNUSED_inst_ad_const;assign UNUSED_inst_ad_const = inst_ad[7];

endmodule

