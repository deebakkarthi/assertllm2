

module i2cSlaveTop
(
  clk,
  rst,
  sda,
  scl,
  myReg0
);

  input clk;
  input rst;
  inout sda;
  input scl;
  output [7:0] myReg0;

  i2cSlave
  u_i2cSlave
  (
    .clk(clk),
    .rst(rst),
    .sda(sda),
    .scl(scl),
    .myReg0(myReg0),
    .myReg1(),
    .myReg2(),
    .myReg3(),
    .myReg4(8'h13),
    .myReg5(8'h34),
    .myReg6(8'h56),
    .myReg7(8'h78)
  );


endmodule

