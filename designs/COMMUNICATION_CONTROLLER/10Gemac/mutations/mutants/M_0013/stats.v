

module stats
(
  stats_tx_pkts,
  stats_tx_octets,
  stats_rx_pkts,
  stats_rx_octets,
  wb_rst_i,
  wb_clk_i,
  txsfifo_wen,
  txsfifo_wdata,
  rxsfifo_wen,
  rxsfifo_wdata,
  reset_xgmii_tx_n,
  reset_xgmii_rx_n,
  clk_xgmii_tx,
  clk_xgmii_rx,
  clear_stats_tx_pkts,
  clear_stats_tx_octets,
  clear_stats_rx_pkts,
  clear_stats_rx_octets
);

  input clear_stats_rx_octets;
  input clear_stats_rx_pkts;
  input clear_stats_tx_octets;
  input clear_stats_tx_pkts;
  input clk_xgmii_rx;
  input clk_xgmii_tx;
  input reset_xgmii_rx_n;
  input reset_xgmii_tx_n;
  input [13:0] rxsfifo_wdata;
  input rxsfifo_wen;
  input [13:0] txsfifo_wdata;
  input txsfifo_wen;
  input wb_clk_i;
  input wb_rst_i;
  output [31:0] stats_rx_octets;
  output [31:0] stats_rx_pkts;
  output [31:0] stats_tx_octets;
  output [31:0] stats_tx_pkts;
  wire [13:0] rxsfifo_rdata;
  wire rxsfifo_rempty;
  wire [13:0] txsfifo_rdata;
  wire txsfifo_rempty;

  tx_stats_fifo
  tx_stats_fifo0
  (
    .txsfifo_rdata(txsfifo_rdata[13:0]),
    .txsfifo_rempty(txsfifo_rempty),
    .clk_xgmii_tx(clk_xgmii_tx),
    .reset_xgmii_tx_n(reset_xgmii_tx_n),
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .txsfifo_wdata(txsfifo_wdata[13:0]),
    .txsfifo_wen(txsfifo_wen)
  );


  rx_stats_fifo
  rx_stats_fifo0
  (
    .rxsfifo_rdata(rxsfifo_rdata[13:0]),
    .rxsfifo_rempty(rxsfifo_rempty),
    .clk_xgmii_rx(clk_xgmii_rx),
    .reset_xgmii_rx_n(reset_xgmii_rx_n),
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .rxsfifo_wdata(rxsfifo_wdata[13:0]),
    .rxsfifo_wen(rxsfifo_wen)
  );


  stats_sm
  stats_sm0
  (
    .stats_tx_octets(stats_tx_octets[31:0]),
    .stats_tx_pkts(stats_tx_pkts[31:0]),
    .stats_rx_octets(stats_rx_octets[0:0]),
    .stats_rx_pkts(stats_rx_pkts[31:0]),
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .txsfifo_rdata(txsfifo_rdata[13:0]),
    .txsfifo_rempty(txsfifo_rempty),
    .rxsfifo_rdata(rxsfifo_rdata[13:0]),
    .rxsfifo_rempty(rxsfifo_rempty),
    .clear_stats_tx_octets(clear_stats_tx_octets),
    .clear_stats_tx_pkts(clear_stats_tx_pkts),
    .clear_stats_rx_octets(clear_stats_rx_octets),
    .clear_stats_rx_pkts(clear_stats_rx_pkts)
  );


endmodule

