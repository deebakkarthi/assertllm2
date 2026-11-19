

module ParallelToSerial
(
  rst,
  clk,
  ce,
  ld,
  qin,
  d,
  qh
);

  parameter WID = 8;
  input rst;
  input clk;
  input ce;
  input ld;
  input qin;
  input [WID:1] d;
  output qh;
  reg [WID:1] q;

  always @(posedge clk) if(rst) q <= 0; 
  else if(ce) begin
    if(ld) q <= d; 
    else q <= { q[WID-1:2], qin };
  end 

  assign qh = q[WID];

endmodule

