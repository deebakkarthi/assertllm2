

module aes_128
(
  clk,
  state,
  key,
  out
);

  input clk;
  input [127:0] state;input [127:0] key;
  output [127:0] out;
  reg [127:0] s0;reg [127:0] k0;
  wire [127:0] s1;wire [127:0] s2;wire [127:0] s3;wire [127:0] s4;wire [127:0] s5;wire [127:0] s6;wire [127:0] s7;wire [127:0] s8;wire [127:0] s9;wire [127:0] k1;wire [127:0] k2;wire [127:0] k3;wire [127:0] k4;wire [127:0] k5;wire [127:0] k6;wire [127:0] k7;wire [127:0] k8;wire [127:0] k9;wire [127:0] k0b;wire [127:0] k1b;wire [127:0] k2b;wire [127:0] k3b;wire [127:0] k4b;wire [127:0] k5b;wire [127:0] k6b;wire [127:0] k7b;wire [127:0] k8b;wire [127:0] k9b;
  wire dummy_nc;

  always @(posedge clk) begin
    s0 <= state ^ key;
    k0 <= key;
  end


  expand_key_128
  a1
  (
    clk,
    k0,
    k1,
    k0b,
    8'h1
  ),
  a2
  (
    clk,
    k1,
    k2,
    k1b,
    8'h2
  ),
  a3
  (
    clk,
    k2,
    k3,
    k2b,
    8'h4
  ),
  a4
  (
    clk,
    k3,
    k4,
    k3b,
    8'h8
  ),
  a5
  (
    clk,
    k4,
    k5,
    k4b,
    8'h10
  ),
  a6
  (
    clk,
    k5,
    k6,
    k5b,
    8'h20
  ),
  a7
  (
    clk,
    k6,
    k7,
    k6b,
    8'h40
  ),
  a8
  (
    clk,
    k7,
    k8,
    k7b,
    8'h80
  ),
  a9
  (
    clk,
    k8,
    k9,
    k8b,
    8'h1b
  ),
  a10
  (
    clk,
    k9,
    dummy_nc,
    k9b,
    8'h36
  );


  one_round
  r1
  (
    clk,
    s0,
    k0b,
    s1
  ),
  r2
  (
    clk,
    s1,
    k1b,
    s2
  ),
  r3
  (
    clk,
    s2,
    k2b,
    s3
  ),
  r4
  (
    clk,
    s3,
    k3b,
    s4
  ),
  r5
  (
    clk,
    s4,
    k4b,
    s5
  ),
  r6
  (
    clk,
    s5,
    k5b,
    s6
  ),
  r7
  (
    clk,
    s6,
    k6b,
    s7
  ),
  r8
  (
    clk,
    s7,
    k7b,
    s8
  ),
  r9
  (
    clk,
    s8,
    k8b,
    s9
  );


  final_round
  rf
  (
    clk,
    s9,
    k9b,
    out
  );


endmodule



module expand_key_128
(
  clk,
  in,
  out_1,
  out_2,
  rcon
);

  input clk;
  input [127:0] in;
  input [7:0] rcon;
  output [127:0] out_1;reg [127:0] out_1;
  output [127:0] out_2;
  wire [31:0] k0;wire [31:0] k1;wire [31:0] k2;wire [31:0] k3;wire [31:0] v0;wire [31:0] v1;wire [31:0] v2;wire [31:0] v3;
  reg [31:0] k0a;reg [31:0] k1a;reg [31:0] k2a;reg [31:0] k3a;
  wire [31:0] k0b;wire [31:0] k1b;wire [31:0] k2b;wire [31:0] k3b;wire [31:0] k4a;

  assign v0 = { k0[31:24] ^ rcon, k0[23:0] };
  assign v1 = v0 ^ k1;
  assign v2 = v1 ^ k2;
  assign v3 = v2 ^ k3;

  always @(posedge clk) { k0a, k1a, k2a, k3a } <= { v0, v1, v2, v3 };


  S4
  S4_0
  (
    clk,
    { k3[23:0], k3[31:24] },
    k4a
  );

  assign k0b = k0a ^ k4a;
  assign k1b = k1a ^ k4a;
  assign k2b = k2a ^ k4a;
  assign k3b = k3a ^ k4a;

  always @(posedge clk) out_1 <= { k0b, k1b, k2b, k3b };

  assign out_2 = { k0b, k1b, k2b, k3b };

endmodule

