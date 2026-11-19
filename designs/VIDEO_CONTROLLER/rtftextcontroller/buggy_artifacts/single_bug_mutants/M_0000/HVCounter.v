

module HVCounter
(
  rst,
  vclk,
  pixcce,
  sync,
  cnt_offs,
  pixsz,
  maxpix,
  nxt_pix,
  pos,
  nxt_pos,
  ctr
);

  input rst;
  input vclk;
  input pixcce;
  input sync;
  input [11:0] cnt_offs;
  input [3:0] pixsz;
  input [4:0] maxpix;
  output nxt_pix;
  output [11:0] pos;
  output nxt_pos;
  output [11:0] ctr;
  reg [11:0] pos;
  reg [11:0] ctr;
  reg nxt_pix;
  wire [11:0] ctr1;
  wire nxp;
  reg [23:0] x4096;
  reg [11:0] inv;

  always @(posedge vclk) case(maxpix)
    5'd00: inv <= 12'd4095;
    5'd01: inv <= 12'd2048;
    5'd02: inv <= 12'd1365;
    5'd03: inv <= 12'd1024;
    5'd04: inv <= 12'd0819;
    5'd05: inv <= 12'd0683;
    5'd06: inv <= 12'd0585;
    5'd07: inv <= 12'd0512;
    5'd08: inv <= 12'd0455;
    5'd09: inv <= 12'd0409;
    5'd10: inv <= 12'd0372;
    5'd11: inv <= 12'd0341;
    5'd12: inv <= 12'd0315;
    5'd13: inv <= 12'd0292;
    5'd14: inv <= 12'd0273;
    5'd15: inv <= 12'd0256;
    5'd16: inv <= 12'd0240;
    5'd17: inv <= 12'd0227;
    5'd18: inv <= 12'd0215;
    5'd19: inv <= 12'd0204;
    5'd20: inv <= 12'd0195;
    5'd21: inv <= 12'd0186;
    5'd22: inv <= 12'd0178;
    5'd23: inv <= 12'd0170;
    5'd24: inv <= 12'd0163;
    5'd25: inv <= 12'd0157;
    5'd26: inv <= 12'd0151;
    5'd27: inv <= 12'd0146;
    5'd28: inv <= 12'd0141;
    5'd29: inv <= 12'd0136;
    5'd30: inv <= 12'd0132;
    5'd31: inv <= 12'd0128;
  endcase


  always @(posedge vclk) x4096 <= ctr * inv;


  always @(x4096) pos <= x4096[23:12];


  always @(posedge vclk) ctr <= ctr1;


  always @(posedge vclk) nxt_pix <= nxp;


  VT163
  #(
    4
  )
  u1
  (
    .clk(vclk),
    .clr_n(!rst),
    .ent(pixcce),
    .enp(1'b1),
    .ld_n(!sync & !nxp),
    .d(4'hF - pixsz),
    .q(),
    .rco(nxp)
  );


  VT163
  #(
    12
  )
  u2
  (
    .clk(vclk),
    .clr_n(!rst),
    .ent(nxp),
    .enp(1'b1),
    .ld_n(!sync),
    .d(12'h000 + cnt_offs),
    .q(ctr1),
    .rco()
  );


  change_det
  #(
    12
  )
  u3
  (
    .rst(rst),
    .clk(vclk),
    .ce(nxt_pix),
    .i(pos),
    .cd(nxt_pos)
  );


endmodule

