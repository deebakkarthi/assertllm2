

module func6
(
  clk,
  reset,
  in,
  out
);

  input clk;input reset;input in;
  output out;
  reg reg1;reg reg2;

  always @(posedge clk) if(reset) begin
    reg1 <= 1;
    reg2 <= 1;
  end else begin
    reg2 <= reg1;
    reg1 <= in;
  end

  assign out = ({ reg2, reg1 } == 2'b01)? 1 : 0;

endmodule

