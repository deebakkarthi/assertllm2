

module pairing
(
  clk,
  reset,
  sel,
  addr,
  w,
  update,
  ready,
  i,
  o,
  done
);

  input clk;
  input reset;
  input sel;
  input [5:0] addr;
  input w;
  input update;
  input ready;
  input i;
  output o;
  output done;
  reg [197:0] reg_in;reg [197:0] reg_out;
  wire [197:0] out;
  assign o = reg_out[0];

  tiny
  tiny0
  (
    clk,
    reset,
    sel,
    addr,
    w,
    reg_in,
    out,
    done
  );


  always @(posedge clk) if(update) reg_in <= 0; 
  else if(ready) reg_in <= { i, reg_in[197:1] }; 


  always @(posedge clk) if(update) reg_out <= out; 


endmodule

