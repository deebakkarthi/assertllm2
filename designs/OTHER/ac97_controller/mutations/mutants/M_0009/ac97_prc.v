

module ac97_prc
(
  clk,
  rst,
  valid,
  in_valid,
  out_slt0,
  in_slt0,
  in_slt1,
  crac_valid,
  crac_wr,
  oc0_cfg,
  oc1_cfg,
  oc2_cfg,
  oc3_cfg,
  oc4_cfg,
  oc5_cfg,
  ic0_cfg,
  ic1_cfg,
  ic2_cfg,
  o3_empty,
  o4_empty,
  o6_empty,
  o7_empty,
  o8_empty,
  o9_empty,
  i3_full,
  i4_full,
  i6_full,
  o3_re,
  o4_re,
  o6_re,
  o7_re,
  o8_re,
  o9_re,
  i3_we,
  i4_we,
  i6_we
);

  input clk;input rst;
  input valid;
  input [2:0] in_valid;
  output [15:0] out_slt0;
  input [15:0] in_slt0;
  input [19:0] in_slt1;
  input crac_valid;
  input crac_wr;
  input [7:0] oc0_cfg;
  input [7:0] oc1_cfg;
  input [7:0] oc2_cfg;
  input [7:0] oc3_cfg;
  input [7:0] oc4_cfg;
  input [7:0] oc5_cfg;
  input [7:0] ic0_cfg;
  input [7:0] ic1_cfg;
  input [7:0] ic2_cfg;
  input o3_empty;
  input o4_empty;
  input o6_empty;
  input o7_empty;
  input o8_empty;
  input o9_empty;
  input i3_full;
  input i4_full;
  input i6_full;
  output o3_re;
  output o4_re;
  output o6_re;
  output o7_re;
  output o8_re;
  output o9_re;
  output i3_we;
  output i4_we;
  output i6_we;
  wire o3_re_l;
  wire o4_re_l;
  wire o6_re_l;
  wire o7_re_l;
  wire o8_re_l;
  wire o9_re_l;
  reg crac_valid_r;
  reg crac_wr_r;
  assign out_slt0[15] = |out_slt0[14:6];
  assign out_slt0[14] = crac_valid_r;
  assign out_slt0[13] = crac_wr_r;
  assign out_slt0[12] = o3_re_l;
  assign out_slt0[11] = o4_re_l;
  assign out_slt0[10] = 1'b0;
  assign out_slt0[09] = o6_re_l;
  assign out_slt0[08] = o7_re_l;
  assign out_slt0[07] = o8_re_l;
  assign out_slt0[06] = o9_re_l;
  assign out_slt0[5:0] = 6'h0;

  always @(posedge clk) if(valid) crac_valid_r <= #1 crac_valid; 


  always @(posedge clk) if(valid) crac_wr_r <= #1 crac_valid & crac_wr; 


  ac97_fifo_ctrl
  u0
  (
    .clk(clk),
    .valid(valid),
    .ch_en(oc0_cfg[0]),
    .srs(oc0_cfg[1]),
    .full_empty(o3_empty),
    .req(~in_slt1[11]),
    .crdy(in_slt0[15]),
    .en_out(o3_re),
    .en_out_l(o3_re_l)
  );


  ac97_fifo_ctrl
  u1
  (
    .clk(clk),
    .valid(valid),
    .ch_en(oc1_cfg[0]),
    .srs(oc1_cfg[1]),
    .full_empty(o4_empty),
    .req(~in_slt1[10]),
    .crdy(in_slt0[15]),
    .en_out(o4_re),
    .en_out_l(o4_re_l)
  );


  ac97_fifo_ctrl
  u2
  (
    .clk(clk),
    .valid(valid),
    .ch_en(oc2_cfg[0]),
    .srs(oc2_cfg[1]),
    .full_empty(o6_empty),
    .req(~in_slt1[8]),
    .crdy(in_slt0[15]),
    .en_out(o6_re),
    .en_out_l(o6_re_l)
  );


  ac97_fifo_ctrl
  u3
  (
    .clk(clk),
    .valid(valid),
    .ch_en(oc3_cfg[0]),
    .srs(oc3_cfg[1]),
    .full_empty(o7_empty),
    .req(~in_slt1[7]),
    .crdy(in_slt0[15]),
    .en_out(o7_re),
    .en_out_l(o7_re_l)
  );


  ac97_fifo_ctrl
  u4
  (
    .clk(clk),
    .valid(valid),
    .ch_en(oc4_cfg[0]),
    .srs(oc4_cfg[1]),
    .full_empty(o8_empty),
    .req(~in_slt1[6]),
    .crdy(in_slt0[15]),
    .en_out(o8_re),
    .en_out_l(o8_re_l)
  );


  ac97_fifo_ctrl
  u5
  (
    .clk(clk),
    .valid(valid),
    .ch_en(oc5_cfg[0]),
    .srs(oc5_cfg[1]),
    .full_empty(o9_empty),
    .req(~in_slt1[5]),
    .crdy(in_slt0[15]),
    .en_out(o9_re),
    .en_out_l(o9_re_l)
  );


  ac97_fifo_ctrl
  u6
  (
    .clk(clk),
    .valid(in_valid[0]),
    .ch_en(ic0_cfg[0]),
    .srs(ic0_cfg[1]),
    .full_empty(i3_full),
    .req(in_slt0[12]),
    .crdy(in_slt0[15]),
    .en_out(i3_we),
    .en_out_l()
  );


  ac97_fifo_ctrl
  u7
  (
    .clk(clk),
    .valid(in_valid[1]),
    .ch_en(ic1_cfg[4]),
    .srs(ic1_cfg[1]),
    .full_empty(i4_full),
    .req(in_slt0[11]),
    .crdy(in_slt0[15]),
    .en_out(i4_we),
    .en_out_l()
  );


  ac97_fifo_ctrl
  u8
  (
    .clk(clk),
    .valid(in_valid[2]),
    .ch_en(ic2_cfg[0]),
    .srs(ic2_cfg[1]),
    .full_empty(i6_full),
    .req(in_slt0[9]),
    .crdy(in_slt0[15]),
    .en_out(i6_we),
    .en_out_l()
  );


endmodule

