

module VT163
(
  clk,
  clr_n,
  ent,
  enp,
  ld_n,
  d,
  q,
  rco
);

  parameter WID = 4;
  input clk;
  input clr_n;
  input ent;
  input enp;
  input ld_n;
  input [WID:1] d;
  output [WID:1] q;
  reg [WID:1] q;
  output rco;
  assign rco = &{ q[WID:2], ent };

  always @(posedge clk) begin
    if(!clr_n) q <= { WID{ 1'b0 } }; 
    else if(!ld_n) q <= d; 
    else if(enp & ent) q <= q + { { WID - 1{ 1'b0 } }, 1'b1 }; 
  end


endmodule

