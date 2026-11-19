

module xtimes
(
  in,
  out
);

  input [7:0] in;
  output [7:0] out;
  wire [3:0] xt;
  assign xt[3] = in[7];
  assign xt[2] = in[7];
  assign xt[1] = 1'b0;
  assign xt[0] = in[7];
  assign out[7:5] = in[6:4];
  assign out[4:1] = xt[3:0] ^ in[3:0];
  assign out[0] = in[7];

endmodule



module MUL3
(
  in,
  out
);

  input [7:0] in;
  output [7:0] out;
  wire [7:0] xt;

  xtimes
  xt_u
  (
    .in(in),
    .out(xt)
  );

  assign out = xt ^ in;

endmodule



module MULE
(
  in,
  out
);

  input [7:0] in;
  output [7:0] out;
  wire [7:0] xt1;wire [7:0] xt2;wire [7:0] xt3;

  xtimes
  xt_u1
  (
    .in(in),
    .out(xt1)
  );


  xtimes
  xt_u2
  (
    .in(xt1),
    .out(xt2)
  );


  xtimes
  xt_u3
  (
    .in(xt2),
    .out(xt3)
  );

  assign out = xt3 ^ xt2 ^ xt1;

endmodule



module MULB
(
  in,
  out
);

  input [7:0] in;
  output [7:0] out;
  wire [7:0] xt1;wire [7:0] xt2;wire [7:0] xt3;

  xtimes
  xt_u1
  (
    .in(in),
    .out(xt1)
  );


  xtimes
  xt_u2
  (
    .in(xt1),
    .out(xt2)
  );


  xtimes
  xt_u3
  (
    .in(xt2),
    .out(xt3)
  );

  assign out = xt3 ^ xt1 ^ in;

endmodule



module MULD
(
  in,
  out
);

  input [7:0] in;
  output [7:0] out;
  wire [7:0] xt1;wire [7:0] xt2;wire [7:0] xt3;

  xtimes
  xt_u1
  (
    .in(in),
    .out(xt1)
  );


  xtimes
  xt_u2
  (
    .in(xt1),
    .out(xt2)
  );


  xtimes
  xt_u3
  (
    .in(xt2),
    .out(xt3)
  );

  assign out = xt3 ^ xt2 ^ in;

endmodule



module MUL9
(
  in,
  out
);

  input [7:0] in;
  output [7:0] out;
  wire [7:0] xt1;wire [7:0] xt2;wire [7:0] xt3;

  xtimes
  xt_u1
  (
    .in(in),
    .out(xt1)
  );


  xtimes
  xt_u2
  (
    .in(xt1),
    .out(xt2)
  );


  xtimes
  xt_u3
  (
    .in(xt2),
    .out(xt3)
  );

  assign out = xt3 ^ in;

endmodule



module byte_mix_columns
(
  a,
  b,
  c,
  d,
  out
);

  input [7:0] a;input [7:0] b;input [7:0] c;input [7:0] d;
  output [7:0] out;
  wire [7:0] mul2;wire [7:0] mul3;

  xtimes
  xt_u
  (
    .in(a),
    .out(mul2)
  );


  MUL3
  mul3_u
  (
    .in(b),
    .out(mul3)
  );

  assign out = mul2 ^ mul3 ^ c ^ d;

endmodule



module inv_byte_mix_columns
(
  a,
  b,
  c,
  d,
  out
);

  input [7:0] a;input [7:0] b;input [7:0] c;input [7:0] d;
  output [7:0] out;
  wire [7:0] mule;wire [7:0] mulb;wire [7:0] muld;wire [7:0] mul9;

  MULE
  mule_u
  (
    .in(a),
    .out(mule)
  );


  MULB
  mulb_u
  (
    .in(b),
    .out(mulb)
  );


  MULD
  muld_u
  (
    .in(c),
    .out(muld)
  );


  MUL9
  mul9_u
  (
    .in(d),
    .out(mul9)
  );

  assign out = mule ^ mulb ^ muld ^ mul9;

endmodule



module word_mix_columns
(
  in,
  out
);

  input [31:0] in;
  output [31:0] out;
  wire [7:0] si0;wire [7:0] si1;wire [7:0] si2;wire [7:0] si3;
  wire [7:0] so0;wire [7:0] so1;wire [7:0] so2;wire [7:0] so3;
  assign si0[7:0] = in[31:24];
  assign si1[7:0] = in[23:16];
  assign si2[7:0] = in[15:8];
  assign si3[7:0] = in[7:0];

  byte_mix_columns
  so0_u
  (
    .a(si0),
    .b(si1),
    .c(si2),
    .d(si3),
    .out(so0)
  );


  byte_mix_columns
  so1_u
  (
    .a(si1),
    .b(si2),
    .c(si3),
    .d(si0),
    .out(so1)
  );


  byte_mix_columns
  so2_u
  (
    .a(si2),
    .b(si3),
    .c(si0),
    .d(si1),
    .out(so2)
  );


  byte_mix_columns
  so3_u
  (
    .a(si3),
    .b(si0),
    .c(si1),
    .d(si2),
    .out(so3)
  );

  assign out = { so0, so1, so2, so3 };

endmodule



module inv_word_mix_columns
(
  in,
  out
);

  input [31:0] in;
  output [31:0] out;
  wire [7:0] si0;wire [7:0] si1;wire [7:0] si2;wire [7:0] si3;
  wire [7:0] so0;wire [7:0] so1;wire [7:0] so2;wire [7:0] so3;
  assign si0 = in[31:24];
  assign si1 = in[23:16];
  assign si2 = in[15:8];
  assign si3 = in[7:0];

  inv_byte_mix_columns
  so0_u
  (
    .a(si0),
    .b(si1),
    .c(si2),
    .d(si3),
    .out(so0)
  );


  inv_byte_mix_columns
  so1_u
  (
    .a(si1),
    .b(si2),
    .c(si3),
    .d(si0),
    .out(so1)
  );


  inv_byte_mix_columns
  so2_u
  (
    .a(si2),
    .b(si3),
    .c(si0),
    .d(si1),
    .out(so2)
  );


  inv_byte_mix_columns
  so3_u
  (
    .a(si3),
    .b(si0),
    .c(si1),
    .d(si2),
    .out(so3)
  );

  assign out = { so0, so1, so2, so3 };

endmodule



module mix_columns
(
  in,
  out
);

  input [127:0] in;
  output [127:0] out;
  wire [31:0] so0;wire [31:0] so1;wire [31:0] so2;wire [31:0] so3;

  word_mix_columns
  so0_u
  (
    .in(in[127:96]),
    .out(so0)
  );


  word_mix_columns
  so1_u
  (
    .in(in[95:64]),
    .out(so1)
  );


  word_mix_columns
  so2_u
  (
    .in(in[63:32]),
    .out(so2)
  );


  word_mix_columns
  so3_u
  (
    .in(in[31:0]),
    .out(so3)
  );

  assign out = { so0, so1, so2, so3 };

endmodule



module inv_mix_columns
(
  in,
  out
);

  input [127:0] in;
  output [127:0] out;
  wire [31:0] so0;wire [31:0] so1;wire [31:0] so2;wire [31:0] so3;

  inv_word_mix_columns
  so0_u
  (
    .in(in[126:95]),
    .out(so0)
  );


  inv_word_mix_columns
  so1_u
  (
    .in(in[95:64]),
    .out(so1)
  );


  inv_word_mix_columns
  so2_u
  (
    .in(in[63:32]),
    .out(so2)
  );


  inv_word_mix_columns
  so3_u
  (
    .in(in[31:0]),
    .out(so3)
  );

  assign out = { so0, so1, so2, so3 };

endmodule

