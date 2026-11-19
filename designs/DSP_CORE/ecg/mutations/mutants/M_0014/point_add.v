

module point_scalar_mult
(
  clk,
  reset,
  x1,
  y1,
  zero1,
  c,
  done,
  x3,
  y3,
  zero3
);

  input clk;input reset;
  input [2*97-1:0] x1;input [2*97-1:0] y1;
  input zero1;
  input [151-1:0] c;
  output done;reg done;
  output [2*97-1:0] x3;reg [2*97-1:0] x3;output [2*97-1:0] y3;reg [2*97-1:0] y3;
  output zero3;reg zero3;
  reg [2*97-1:0] x2;reg [2*97-1:0] y2;
  reg zero2;
  reg [2*97-1:0] x4;reg [2*97-1:0] y4;
  reg zero4;
  wire [2*97-1:0] x5;wire [2*97-1:0] y5;
  wire zero5;
  wire [2*97-1:0] x6;wire [2*97-1:0] y6;
  wire zero6;
  wire [2*97-1:0] x7;wire [2*97-1:0] y7;
  wire zero7;
  reg [151-1:0] k;
  wire fin;
  reg op;
  wire p;wire p2;wire rst;wire done1;wire lastbit;
  assign lastbit = k[0];
  assign fin = k == 0;
  assign x5 = (op)? x4 : x2;
  assign y5 = (op)? y4 : y2;
  assign zero5 = (op)? zero4 : zero2;
  assign { x6, y6 } = { x4, y4 };
  assign zero6 = (~op & ~lastbit)? 1 : zero4;
  assign rst = reset | p2;

  point_add
  ins1
  (
    clk,
    rst,
    x5,
    y5,
    zero5,
    x6,
    y6,
    zero6,
    done1,
    x7,
    y7,
    zero7
  );


  func6
  ins2
  (
    clk,
    reset,
    done1,
    p
  ),
  ins3
  (
    clk,
    reset,
    p,
    p2
  );


  always @(posedge clk) if(reset) k <= c; 
  else if(op & p) k <= k >> 1; 


  always @(posedge clk) if(reset) op <= 0; 
  else if(p) op <= ~op; 


  always @(posedge clk) if(reset) begin
    x2 <= 0;
    y2 <= 0;
    zero2 <= 1;
  end else if(~op & p) begin
    { x2, y2, zero2 } <= { x7, y7, zero7 };
  end 


  always @(posedge clk) if(reset) begin
    { x4, y4, zero4 } <= { x1, y1, zero1 };
  end else if(op & p) begin
    { x4, y4, zero4 } <= { x7, y7, zero7 };
  end 


  always @(posedge clk) if(reset) begin
    x3 <= 0;
    y3 <= 0;
    zero3 <= 1;
    done <= 0;
  end else if(fin) begin
    { x3, y3, zero3 } <= { x2, y2, zero2 };
    done <= 1;
  end 


endmodule



module point_add
(
  clk,
  reset,
  x1,
  y1,
  zero1,
  x2,
  y2,
  zero2,
  done,
  x3,
  y3,
  zero3
);

  input clk;input reset;
  input [2*97-1:0] x1;input [2*97-1:0] y1;
  input zero1;
  input [2*97-1:0] x2;input [2*97-1:0] y2;
  input zero2;
  output done;reg done;
  output [2*97-1:0] x3;reg [2*97-1:0] x3;output [2*97-1:0] y3;reg [2*97-1:0] y3;
  output zero3;reg zero3;
  wire [2*97-1:0] x3a;wire [2*97-1:0] x3b;wire [2*97-1:0] x3c;wire [2*97-1:0] y3a;wire [2*97-1:0] y3b;wire [2*97-1:0] y3c;wire [2*97-1:0] ny2;
  wire zero3a;wire done10;wire done11;
  reg use1;reg cond1;reg cond2;reg cond3;reg cond4;reg cond5;

  f3m_neg
  ins1
  (
    y2,
    ny2
  );


  func9
  ins9
  (
    x1,
    y1,
    zero1,
    x2,
    y2,
    zero2,
    x3a,
    y3a,
    zero3a
  );


  func10
  ins10
  (
    clk,
    reset,
    x1,
    y1,
    done10,
    x3b,
    y3b
  );


  func11
  ins11
  (
    clk,
    reset,
    x1,
    y1,
    x2,
    y2,
    done11,
    x3c,
    y3c
  );


  always @(posedge clk) if(reset) begin
    use1 <= 0;
    cond1 <= 0;
    cond2 <= 0;
    cond3 <= 0;
    cond4 <= 0;
    cond5 <= 0;
  end else begin
    use1 <= zero1 | zero2;
    cond1 <= ~use1 && cond2 && cond4;
    cond2 <= x1 == x2;
    cond3 <= y1 == y2;
    cond4 <= y1 == ny2;
    cond5 <= ~use1 && cond2 && cond3;
  end


  always @(posedge clk) if(reset) zero3 <= 0; 
  else zero3 <= use1 & zero3a | cond1;


  always @(posedge clk) if(reset) done <= 0; 
  else done <= (use1 | cond1)? 1 : 
          (cond5)? done10 : done11;


  always @(posedge clk) if(reset) begin
    x3 <= 0;
    y3 <= 0;
  end else begin
    x3 <= (use1)? x3a : 
          (cond5)? x3b : x3c;
    y3 <= (use1)? y3a : 
          (cond5)? y3b : y3c;
  end


endmodule



module func9
(
  x1,
  y1,
  zero1,
  x2,
  y2,
  zero2,
  x3,
  y3,
  zero3
);

  input [2*97-1:0] x1;input [2*97-1:0] y1;input [2*97-1:0] x2;input [2*97-1:0] y2;
  input zero1;
  input zero2;
  output [2*97-1:0] x3;output [2*97-1:0] y3;
  output zero3;
  assign zero3 = zero1 & zero2;
  genvar i;

  generate for(i=0; i<=2*97-1; i=i+1) begin : label
    assign x3[i] = x2[i] & zero1 | x1[i] & zero2;
    assign y3[i] = y2[i] & zero1 | y1[i] & zero2;
  end
  endgenerate


endmodule



module func10
(
  clk,
  reset,
  x1,
  y1,
  done,
  x3,
  y3
);

  input clk;input reset;
  input [2*97-1:0] x1;input [2*97-1:0] y1;
  output done;reg done;
  output [2*97-1:0] x3;reg [2*97-1:0] x3;output [2*97-1:0] y3;reg [2*97-1:0] y3;
  wire [2*97-1:0] v1;wire [2*97-1:0] v2;wire [2*97-1:0] v3;wire [2*97-1:0] v4;wire [2*97-1:0] v5;wire [2*97-1:0] v6;
  wire rst2;wire done1;wire done2;
  reg [2:0] K;

  f3m_inv
  ins1
  (
    clk,
    reset,
    y1,
    v1,
    done1
  );


  f3m_mult
  ins2
  (
    clk,
    rst2,
    v1,
    v1,
    v2,
    done2
  );


  f3m_cubic
  ins3
  (
    v1,
    v3
  );


  f3m_add
  ins4
  (
    x1,
    v2,
    v4
  ),
  ins5
  (
    y1,
    v3,
    v5
  );


  f3m_neg
  ins6
  (
    v5,
    v6
  );


  func6
  ins7
  (
    clk,
    reset,
    done1,
    rst2
  );


  always @(posedge clk) if(reset) K <= 3'b100; 
  else if(K[2] & rst2 | K[1] & done2 | K[0]) K <= K >> 1; 


  always @(posedge clk) if(reset) begin
    done <= 1;
    x3 <= 1;
    y3 <= 1;
  end else if(K[0]) begin
    done <= 1;
    x3 <= v4;
    y3 <= v6;
  end 


endmodule



module func11
(
  clk,
  reset,
  x1,
  y1,
  x2,
  y2,
  done,
  x3,
  y3
);

  input clk;input reset;
  input [2*97-1:0] x1;input [2*97-1:0] y1;input [2*97-1:0] x2;input [2*97-1:0] y2;
  output done;reg done;
  output [2*97-1:0] x3;reg [2*97-1:0] x3;output [2*97-1:0] y3;reg [2*97-1:0] y3;
  wire [2*97-1:0] v1;wire [2*97-1:0] v2;wire [2*97-1:0] v3;wire [2*97-1:0] v4;wire [2*97-1:0] v5;wire [2*97-1:0] v6;wire [2*97-1:0] v7;wire [2*97-1:0] v8;wire [2*97-1:0] v9;wire [2*97-1:0] v10;
  wire rst2;wire rst3;wire done1;wire done2;wire done3;
  reg [3:0] K;

  f3m_sub
  ins1
  (
    x2,
    x1,
    v1
  ),
  ins2
  (
    y2,
    y1,
    v2
  );


  f3m_inv
  ins3
  (
    clk,
    reset,
    v1,
    v3,
    done1
  );


  f3m_mult
  ins4
  (
    clk,
    rst2,
    v2,
    v3,
    v4,
    done2
  ),
  ins5
  (
    clk,
    rst3,
    v4,
    v4,
    v5,
    done3
  );


  f3m_cubic
  ins6
  (
    v4,
    v6
  );


  f3m_add
  ins7
  (
    x1,
    x2,
    v7
  ),
  ins8
  (
    y1,
    y2,
    v8
  );


  f3m_sub
  ins9
  (
    v5,
    v7,
    v9
  ),
  ins10
  (
    v8,
    v6,
    v10
  );


  func6
  ins11
  (
    clk,
    reset,
    done1,
    rst2
  ),
  ins12
  (
    clk,
    reset,
    done2,
    rst3
  );


  always @(posedge clk) if(reset) K <= 4'b1000; 
  else if(K[3] & rst2 | K[2] & rst3 | K[1] & done3 | K[0]) K <= K >> 1; 


  always @(posedge clk) if(reset) begin
    done <= 0;
    x3 <= 0;
    y3 <= 0;
  end else if(K[0]) begin
    done <= 1;
    x3 <= v9;
    y3 <= v10;
  end 


endmodule

