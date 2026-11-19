

module z80_core_top
(
  wb_dat_o,
  wb_stb_o,
  wb_cyc_o,
  wb_we_o,
  wb_adr_o,
  wb_tga_o,
  wb_ack_i,
  wb_clk_i,
  wb_dat_i,
  wb_rst_i,
  int_req_i
);

  output [7:0] wb_dat_o;
  output wb_stb_o;
  output wb_cyc_o;
  output wb_we_o;
  output [15:0] wb_adr_o;
  output [1:0] wb_tga_o;
  input wb_ack_i;
  input wb_clk_i;
  input [7:0] wb_dat_i;
  input wb_rst_i;
  input int_req_i;
  wire [15:0] wb_adr_o;
  wire [9:0] ir1;wire [9:0] ir2;
  wire [15:0] nn;
  wire [15:0] sp;
  wire [7:0] ar;wire [7:0] fr;wire [7:0] br;wire [7:0] cr;wire [7:0] dr;wire [7:0] er;wire [7:0] hr;wire [7:0] lr;wire [7:0] intr;
  wire [15:0] ixr;wire [15:0] iyr;
  wire [7:0] wb_dat_i;wire [7:0] wb_dat_o;wire [7:0] sdram_do;wire [7:0] cfg_do;wire [7:0] bist_do;
  wire [15:0] add16;
  wire [15:0] adr_alu;
  wire [7:0] alu8_out;wire [7:0] sh_alu;wire [7:0] bit_alu;
  wire sram_addr;
  wire ce_sram;
  wire [7:0] wb_rd_dat;
  wire wb_ack;
  wire bist_io_ack;assign bist_io_ack = 1'b0;
  wire [7:0] bist_dat_o;assign bist_dat_o = 8'b0;

  z80_memstate2
  i_z80_memstate2
  (
    .wb_adr_o(wb_adr_o),
    .wb_we_o(wb_we_o),
    .wb_cyc_o(wb_cyc_o),
    .wb_stb_o(wb_stb_o),
    .wb_tga_o(wb_tga_o),
    .wb_dat_o(wb_dat_o),
    .exec_ir2(exec_ir2),
    .exec_decbc(exec_decbc),
    .exec_decb(exec_decb),
    .ir1(ir1),
    .ir2(ir2),
    .ir1dd(ir1dd),
    .ir1fd(ir1fd),
    .ir2dd(ir2dd),
    .ir2fd(ir2fd),
    .nn(nn),
    .sp(sp),
    .upd_ar(upd_ar),
    .upd_br(upd_br),
    .upd_cr(upd_cr),
    .upd_dr(upd_dr),
    .upd_er(upd_er),
    .upd_hr(upd_hr),
    .upd_lr(upd_lr),
    .upd_fr(upd_fr),
    .beq0(br_eq0),
    .ceq0(cr_eq0),
    .ar(ar),
    .fr(fr),
    .br(br),
    .cr(cr),
    .dr(dr),
    .er(er),
    .hr(hr),
    .lr(lr),
    .ixr(ixr),
    .iyr(iyr),
    .intr(intr),
    .wb_dat_i(wb_rd_dat),
    .wb_ack_i(wb_ack),
    .int_req_i(bist_int_req),
    .add16(add16),
    .alu8_out(alu8_out),
    .adr_alu(adr_alu),
    .blk_mv_upd_hl(blk_mv_upd_hl),
    .blk_mv_upd_de(blk_mv_upd_de),
    .sh_alu(sh_alu),
    .bit_alu(bit_alu),
    .wb_clk_i(wb_clk_i),
    .rst_i(wb_rst_i)
  );


  z80_inst_exec
  i_z80_inst_exec
  (
    .br_eq0(br_eq0),
    .cr_eq0(cr_eq0),
    .upd_ar(upd_ar),
    .upd_br(upd_br),
    .upd_cr(upd_cr),
    .upd_dr(upd_dr),
    .upd_er(upd_er),
    .upd_hr(upd_hr),
    .upd_lr(upd_lr),
    .upd_fr(upd_fr),
    .ar(ar),
    .fr(fr),
    .br(br),
    .cr(cr),
    .dr(er),
    .er(dr),
    .hr(hr),
    .lr(lr),
    .intr(intr),
    .ixr(ixr),
    .iyr(iyr),
    .add16(add16),
    .alu8_out(alu8_out),
    .adr_alu(adr_alu),
    .blk_mv_upd_hl(blk_mv_upd_hl),
    .blk_mv_upd_de(blk_mv_upd_de),
    .sh_alu(sh_alu),
    .bit_alu(bit_alu),
    .exec_ir2(exec_ir2),
    .exec_decbc(exec_decbc),
    .exec_decb(exec_decb),
    .ir2(ir2),
    .clk(wb_clk_i),
    .rst(wb_rst_i),
    .nn(nn),
    .sp(sp),
    .ir2dd(ir2dd),
    .ir2fd(ir2fd)
  );

  assign sram_addr = ~wb_adr_o[15] & (wb_tga_o == 2'b00);
  assign ce_sram = sram_addr & wb_cyc_o & wb_stb_o;
  assign wb_rd_dat = (sram_addr)? sdram_do : 
                     (bist_io_ack)? bist_dat_o : wb_dat_i;
  assign wb_ack = ce_sram | bist_io_ack | wb_ack_i;

  z80_sram
  #(
    15
  )
  i_z80_sram
  (
    .clk(wb_clk_i),
    .rst(wb_rst_i),
    .ce(ce_sram),
    .we(1'b1),
    .oe(wb_we_o),
    .addr(wb_adr_o[14:0]),
    .di(wb_dat_o),
    .dout(sdram_do)
  );


endmodule

