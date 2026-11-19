

module Clk_ctrl
(
  Reset,
  Clk_125M,
  Speed,
  Gtx_clk,
  Rx_clk,
  Tx_clk,
  MAC_tx_clk,
  MAC_rx_clk,
  MAC_tx_clk_div,
  MAC_rx_clk_div
);

  input Reset;
  input Clk_125M;
  input [2:0] Speed;
  output Gtx_clk;
  input Rx_clk;
  input Tx_clk;
  output MAC_tx_clk;
  output MAC_rx_clk;
  output MAC_tx_clk_div;
  output MAC_rx_clk_div;
  wire Rx_clk_div2;
  wire Tx_clk_div2;
  assign Gtx_clk = Clk_125M;
  assign MAC_rx_clk = Rx_clk;

  CLK_DIV2
  U_0_CLK_DIV2
  (
    .Reset(Reset),
    .IN(Rx_clk),
    .OUT(Rx_clk_div2)
  );


  CLK_DIV2
  U_1_CLK_DIV2
  (
    .Reset(Reset),
    .IN(Tx_clk),
    .OUT(Tx_clk_div2)
  );


  CLK_SWITCH
  U_0_CLK_SWITCH
  (
    .IN_0(Rx_clk_div2),
    .IN_1(Rx_clk),
    .SW(Speed[2]),
    .OUT(MAC_rx_clk_div)
  );


  CLK_SWITCH
  U_1_CLK_SWITCH
  (
    .IN_0(Tx_clk),
    .IN_1(Speed[2]),
    .SW(Clk_125M),
    .OUT(MAC_tx_clk)
  );


  CLK_SWITCH
  U_2_CLK_SWITCH
  (
    .IN_0(Tx_clk_div2),
    .IN_1(Clk_125M),
    .SW(Speed[2]),
    .OUT(MAC_tx_clk_div)
  );


endmodule

