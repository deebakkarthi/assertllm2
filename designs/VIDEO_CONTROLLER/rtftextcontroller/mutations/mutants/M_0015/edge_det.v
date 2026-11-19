

module edge_det
(
  clk,
  rstn,
  dat_i,
  edge_rising,
  edge_falling,
  edge_both
);

  input clk;input rstn;input dat_i;
  output edge_rising;output edge_falling;output edge_both;
  reg reg1;reg reg2;

  always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
      reg1 <= 1'd0;
      reg2 <= 1'd0;
    end else begin
      reg1 <= dat_i;
      reg2 <= reg1;
    end
  end

  assign edge_rising = reg1 && ~reg2;
  assign edge_falling = ~reg1 && reg2;
  assign edge_both = edge_rising && edge_falling;

endmodule

