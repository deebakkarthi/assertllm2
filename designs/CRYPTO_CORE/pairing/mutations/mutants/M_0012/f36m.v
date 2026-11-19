

module f36m_mult
(
  clk,
  reset,
  a,
  b,
  c,
  done
);

  input clk;input reset;
  input [12*97-1:0] a;input [12*97-1:0] b;
  output [12*97-1:0] c;reg [12*97-1:0] c;
  output done;reg done;
  reg [4*97-1:0] x0;reg [4*97-1:0] x1;reg [4*97-1:0] x2;reg [4*97-1:0] x3;reg [4*97-1:0] x4;reg [4*97-1:0] x5;
  wire [4*97-1:0] a0;wire [4*97-1:0] a1;wire [4*97-1:0] a2;wire [4*97-1:0] b0;wire [4*97-1:0] b1;wire [4*97-1:0] b2;wire [4*97-1:0] c0;wire [4*97-1:0] c1;wire [4*97-1:0] c2;wire [4*97-1:0] v1;wire [4*97-1:0] v2;wire [4*97-1:0] v3;wire [4*97-1:0] v4;wire [4*97-1:0] v5;wire [4*97-1:0] v6;wire [4*97-1:0] nx0;wire [4*97-1:0] nx2;wire [4*97-1:0] nx5;wire [4*97-1:0] d0;wire [4*97-1:0] d1;wire [4*97-1:0] d2;wire [4*97-1:0] d3;wire [4*97-1:0] d4;
  reg [6:0] K;
  wire e0;wire e1;wire e2;wire e3;wire e4;wire e5;wire mult_done;wire p;wire rst;
  wire [4*97-1:0] in0;wire [4*97-1:0] in1;
  wire [4*97-1:0] o;
  reg mult_reset;reg delay1;reg delay2;
  reg [4*97-1:0] in0d;reg [4*97-1:0] in1d;
  assign { e0, e1, e2, e3, e4, e5 } = K[6:1];
  assign { a2, a1, a0 } = a;
  assign { b2, b1, b0 } = b;
  assign d4 = x0;
  assign d0 = x5;
  assign rst = delay2;

  f32m_mux6
  ins1
  (
    a2,
    v1,
    a1,
    v3,
    v5,
    a0,
    e0,
    e1,
    e2,
    e3,
    e4,
    e5,
    in0
  ),
  ins2
  (
    b2,
    v2,
    b1,
    v4,
    v6,
    b0,
    e0,
    e1,
    e2,
    e3,
    e4,
    e5,
    in1
  );


  f32m_mult
  ins3
  (
    clk,
    mult_reset,
    in0d,
    in1d,
    o,
    mult_done
  );


  func6
  ins4
  (
    clk,
    reset,
    mult_done,
    p
  );


  f32m_add
  ins5
  (
    a1,
    a2,
    v1
  ),
  ins6
  (
    b1,
    b2,
    v2
  ),
  ins7
  (
    a0,
    a2,
    v3
  ),
  ins8
  (
    b0,
    b2,
    v4
  ),
  ins9
  (
    a0,
    a1,
    v5
  ),
  ins10
  (
    b0,
    b1,
    v6
  ),
  ins11
  (
    d0,
    d3,
    c0
  ),
  ins12
  (
    d2,
    d4,
    c2
  );


  f32m_neg
  ins13
  (
    x0,
    nx0
  ),
  ins14
  (
    x2,
    nx2
  ),
  ins15
  (
    x5,
    nx5
  );


  f32m_add3
  ins16
  (
    x1,
    nx0,
    nx2,
    d3
  ),
  ins17
  (
    x4,
    nx2,
    nx5,
    d1
  ),
  ins18
  (
    d1,
    d3,
    d4,
    c1
  );


  f32m_add4
  ins19
  (
    x3,
    x2,
    nx0,
    nx5,
    d2
  );


  always @(posedge clk) begin
    in0d <= in0;
    in1d <= in1;
  end


  always @(posedge clk) begin
    if(reset) K <= 7'b1000000; 
    else if(p | K[0]) K <= { 1'b0, K[6:1] }; 
  end


  always @(posedge clk) begin
    if(e0) x0 <= o; 
    if(e1) x1 <= o; 
    if(e2) x2 <= o; 
    if(e3) x3 <= o; 
    if(e4) x4 <= o; 
    if(e5) x5 <= o; 
  end


  always @(posedge clk) begin
    if(reset) done <= 0; 
    else if(K[0]) begin
      done <= 1;
      c <= { c2, c1, c0 };
    end 
  end


  always @(posedge clk) begin
    if(rst) mult_reset <= 1; 
    else if(mult_done) mult_reset <= 1; 
    else mult_reset <= 0;
  end


  always @(posedge clk) begin
    delay2 <= delay1;
    delay1 <= reset;
  end


endmodule



module f36m_cubic
(
  clk,
  a,
  c
);

  input clk;
  input [12*97-1:0] a;
  output [12*97-1:0] c;reg [12*97-1:0] c;
  wire [4*97-1:0] a0;wire [4*97-1:0] a1;wire [4*97-1:0] a2;wire [4*97-1:0] v0;wire [4*97-1:0] v1;wire [4*97-1:0] v2;wire [4*97-1:0] v3;wire [4*97-1:0] c0;wire [4*97-1:0] c1;wire [4*97-1:0] c2;
  assign { a2, a1, a0 } = a;
  assign c2 = v2;

  f32m_cubic
  ins1
  (
    clk,
    a0,
    v0
  ),
  ins2
  (
    clk,
    a1,
    v1
  ),
  ins3
  (
    clk,
    a2,
    v2
  );


  f32m_add
  ins4
  (
    v0,
    v1,
    v3
  ),
  ins5
  (
    v2,
    v3,
    c0
  );


  f32m_sub
  ins6
  (
    v1,
    v2,
    c1
  );


  always @(posedge clk) c <= { c2, c1, c0 };


endmodule



module second_part
(
  clk,
  reset,
  a,
  c,
  done
);

  input clk;input reset;
  input [12*97-1:0] a;
  output [12*97-1:0] c;reg [12*97-1:0] c;
  output done;reg done;
  reg [3:0] K;
  wire [2*97-1:0] d0;wire [2*97-1:0] d1;wire [2*97-1:0] d2;wire [2*97-1:0] d3;wire [2*97-1:0] d4;wire [2*97-1:0] d5;wire [2*97-1:0] c0;wire [2*97-1:0] c1;wire [2*97-1:0] c2;wire [2*97-1:0] c3;wire [2*97-1:0] c4;wire [2*97-1:0] c5;
  wire [6*97-1:0] a0;wire [6*97-1:0] a1;wire [6*97-1:0] b0;wire [6*97-1:0] b1;wire [6*97-1:0] v1;wire [6*97-1:0] v2;wire [6*97-1:0] v3;wire [6*97-1:0] v4;wire [6*97-1:0] v5;wire [6*97-1:0] v6;wire [6*97-1:0] v7;wire [6*97-1:0] v8;wire [6*97-1:0] nv6;
  wire [1:0] v9;wire [1:0] v10;
  wire rst1;wire rst2;wire rst3;wire done1;wire done2;wire done3;
  assign { d5, d4, d3, d2, d1, d0 } = a;
  assign { a1, a0 } = { d5, d3, d1, d4, d2, d0 };
  assign { b1, b0 } = { { v8[6*97-1:2], v10 }, { v7[6*97-1:2], v9 } };
  assign { c5, c3, c4, c1, c2, c0 } = { b1, b0 };
  assign rst1 = reset;

  f33m_mult2
  ins1
  (
    clk,
    rst1,
    a0,
    a0,
    v1,
    a1,
    a1,
    v2,
    done1
  );


  f33m_add
  ins2
  (
    v1,
    v2,
    v3
  ),
  ins3
  (
    a0,
    a1,
    v5
  );


  f33m_inv
  ins4
  (
    clk,
    rst2,
    v3,
    v4,
    done2
  );


  f33m_neg
  ins5
  (
    v6,
    nv6
  );


  f33m_mult3
  ins6
  (
    clk,
    rst3,
    v5,
    v5,
    v6,
    v2,
    v4,
    v7,
    nv6,
    v4,
    v8,
    done3
  );


  f3_add1
  ins7
  (
    v7[1:0],
    v9
  ),
  ins8
  (
    v8[1:0],
    v10
  );


  func6
  ins9
  (
    clk,
    reset,
    done1,
    rst2
  ),
  ins10
  (
    clk,
    reset,
    done2,
    rst3
  );


  always @(posedge clk) if(reset) K <= 4'b1000; 
  else if(K[3] & rst2 | K[2] & rst3 | K[1] & done3 | K[0]) K <= K >> 1; 


  always @(posedge clk) if(reset) done <= 0; 
  else if(K[0]) begin
    done <= 1;
    c <= { c5, c4, c3, c2, c1, c0 };
  end 


endmodule

