

module wb_interface_sport
(
  wb_rst_i,
  wb_clk_i,
  wb_stb_i,
  wb_ack_o,
  wb_addr_i,
  wb_we_i,
  wb_dat_i,
  wb_sel_i,
  wb_dat_o,
  wb_cyc_i,
  wb_cti_i,
  wb_err_o,
  wb_rty_o,
  rxsampleCnt,
  rxpacketCnt,
  txsampleCnt,
  txpacketCnt,
  dat_i,
  dat_o,
  rxsecEn,
  rxlateFS_earlyFSn,
  txsecEn,
  txlateFS_earlyFSn,
  tx_actHi,
  rx_actHi,
  msbFirst,
  tx_start,
  rx_start,
  rx_int
);

  input wb_rst_i;
  input wb_clk_i;
  input wb_stb_i;
  output wb_ack_o;
  input [6-1:0] wb_addr_i;
  input wb_we_i;
  input [32-1:0] wb_dat_i;
  input [32/8-1:0] wb_sel_i;
  output [32-1:0] dat_o;
  input [32-1:0] dat_i;
  output [32-1:0] wb_dat_o;
  input wb_cyc_i;
  input [2:0] wb_cti_i;
  output wb_err_o;
  output wb_rty_o;
  output [4:0] rxsampleCnt;
  output [10-1:0] rxpacketCnt;
  output [4:0] txsampleCnt;
  output [10-1:0] txpacketCnt;
  output rxsecEn;
  output rxlateFS_earlyFSn;
  output txsecEn;
  output txlateFS_earlyFSn;
  output tx_actHi;
  output rx_actHi;
  output msbFirst;
  output tx_start;output rx_start;
  output rx_int;
  reg [32-1:0] rxreg;
  reg [32-1:0] txreg;
  wire err_int;
  wire rty_int;
  wire full;
  reg ack;reg err;reg rty;
  assign wb_ack_o = ack;
  assign wb_err_o = err;
  assign wb_rty_o = rty;
  assign rst_o = wb_rst_i;
  assign rst = wb_rst_i;
  assign dat_o = wb_dat_i;
  assign ack_o = ack;
  assign stb_o = wb_stb_i;
  assign cyc_o = wb_cyc_i;
  assign we_o = wb_we_i;

  always @(posedge wb_clk_i or posedge rst) begin
    if(rst) ack <= 1'b0; 
    else ack <= ~|(6'h20 & wb_addr_i) & wb_stb_i & wb_cyc_i & ~err_int & ~rty_int;
  end

  assign err_int = ~(wb_addr_i ^ 6'h01) & wb_stb_i & wb_cyc_i & wb_we_i & full;

  always @(posedge wb_clk_i or posedge rst) begin
    if(rst) err <= 1'b0; 
    else err <= err_int;
  end

  assign rty_int = ~|(6'h20 & wb_addr_i) & wb_stb_i & wb_cyc_i & wb_we_i;

  always @(posedge wb_clk_i or posedge rst) begin
    if(rst) rty <= 1'b0; 
    else rty <= rty_int;
  end

  assign clk_o = wb_clk_i;
  assign lock_cfg_rx = rxreg[10 + 10];
  assign lock_cfg_tx = txreg[10 + 10];
  assign rxsecEn = rxreg[10 + 9];
  assign rxlateFS_earlyFSn = rxreg[10 + 8];
  assign txsecEn = txreg[10 + 9];
  assign txlateFS_earlyFSn = txreg[10 + 6];
  assign tx_actHi = txreg[10 + 7];
  assign rx_actHi = rxreg[10 + 7];
  assign tx_start = txreg[10 + 6];
  assign msbFirst = txreg[10 + 5];
  assign rx_start = rxreg[10 + 6];
  assign rx_int = rxreg[10 + 5];
  assign rxsampleCnt = rxreg[10+4:10];
  assign rxpacketCnt = rxreg[10-1:0];
  assign txsampleCnt = txreg[10+4:10];
  assign txpacketCnt = txreg[10-1:0];

  always @(negedge wb_clk_i or posedge rst) begin
    if(rst) rxreg <= 32'hA; 
    else if((wb_addr_i == 6'h01 + 1) && wb_stb_i & wb_cyc_i & wb_we_i & ~lock_cfg_rx) rxreg <= wb_dat_i; 
  end


  always @(negedge wb_clk_i or posedge rst) begin
    if(rst) txreg <= 32'h0; 
    else if((wb_addr_i == 6'h01 + 2) && wb_stb_i & wb_cyc_i & wb_we_i & ~lock_cfg_tx) txreg <= wb_dat_i; 
  end

  assign wb_dat_rdbk = (wb_addr_i == 6'h01 + 1)? rxreg : txreg;
  assign wb_dat_o = (wb_stb_i & wb_cyc_i & ~wb_we_i)? wb_dat_rdbk : 32'hz;
  assign wb_wr_en = (wb_addr_i == 6'h01) && wb_stb_i & wb_cyc_i & wb_we_i & ~full;
  assign wb_rd_en = (wb_addr_i == 6'h01) && wb_stb_i & wb_cyc_i & ~wb_we_i;

endmodule

