

module one_round
(
  clk,
  state_in,
  key,
  state_out
);

  input clk;
  input [127:0] state_in;input [127:0] key;
  output [127:0] state_out;reg [127:0] state_out;
  wire [31:0] s0;wire [31:0] s1;wire [31:0] s2;wire [31:0] s3;wire [31:0] z0;wire [31:0] z1;wire [31:0] z2;wire [31:0] z3;wire [31:0] p00;wire [31:0] p01;wire [31:0] p02;wire [31:0] p03;wire [31:0] p10;wire [31:0] p11;wire [31:0] p12;wire [31:0] p13;wire [31:0] p20;wire [31:0] p21;wire [31:0] p22;wire [31:0] p23;wire [31:0] p30;wire [31:0] p31;wire [31:0] p32;wire [31:0] p33;wire [31:0] k0;wire [31:0] k1;wire [31:0] k2;wire [31:0] k3;
  assign { k0, k1, k2, k3 } = key;
  assign { s1, s0, s2, s3 } = state_in;

  table_lookup
  t0
  (
    clk,
    s0,
    p00,
    p01,
    p02,
    p03
  ),
  t1
  (
    clk,
    s1,
    p10,
    p11,
    p12,
    p13
  ),
  t2
  (
    clk,
    s2,
    p20,
    p21,
    p22,
    p23
  ),
  t3
  (
    clk,
    s3,
    p30,
    p31,
    p32,
    p33
  );

  assign z0 = p00 ^ p11 ^ p22 ^ p33 ^ k0;
  assign z1 = p03 ^ p10 ^ p21 ^ p32 ^ k1;
  assign z2 = p02 ^ p13 ^ p20 ^ p31 ^ k2;
  assign z3 = p01 ^ p12 ^ p23 ^ p30 ^ k3;

  always @(posedge clk) state_out <= { z0, z1, z2, z3 };


endmodule



module final_round
(
  clk,
  state_in,
  key_in,
  state_out
);

  input clk;
  input [127:0] state_in;
  input [127:0] key_in;
  output [127:0] state_out;reg [127:0] state_out;
  wire [31:0] s0;wire [31:0] s1;wire [31:0] s2;wire [31:0] s3;wire [31:0] z0;wire [31:0] z1;wire [31:0] z2;wire [31:0] z3;wire [31:0] k0;wire [31:0] k1;wire [31:0] k2;wire [31:0] k3;
  wire [7:0] p00;wire [7:0] p01;wire [7:0] p02;wire [7:0] p03;wire [7:0] p10;wire [7:0] p11;wire [7:0] p12;wire [7:0] p13;wire [7:0] p20;wire [7:0] p21;wire [7:0] p22;wire [7:0] p23;wire [7:0] p30;wire [7:0] p31;wire [7:0] p32;wire [7:0] p33;
  assign { k0, k1, k2, k3 } = key_in;
  assign { s0, s1, s2, s3 } = state_in;

  S4
  S4_1
  (
    clk,
    s0,
    { p00, p01, p02, p03 }
  ),
  S4_2
  (
    clk,
    s1,
    { p10, p11, p12, p13 }
  ),
  S4_3
  (
    clk,
    s2,
    { p20, p21, p22, p23 }
  ),
  S4_4
  (
    clk,
    s3,
    { p30, p31, p32, p33 }
  );

  assign z0 = { p00, p11, p22, p33 } ^ k0;
  assign z1 = { p10, p21, p32, p03 } ^ k1;
  assign z2 = { p20, p31, p02, p13 } ^ k2;
  assign z3 = { p30, p01, p12, p23 } ^ k3;

  always @(posedge clk) state_out <= { z0, z1, z2, z3 };


endmodule

