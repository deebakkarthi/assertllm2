

module sport_top
(
  DTxPRI,
  DTxSEC,
  TSCLKx,
  TFSx,
  DRxPRI,
  DRxSEC,
  RSCLKx,
  RFSx,
  rx_int,
  rxclk,
  txclk,
  wb_clk_i,
  wb_rst_i,
  wb_dat_i,
  wb_dat_o,
  wb_cyc_i,
  wb_stb_i,
  wb_we_i,
  wb_adr_i,
  wb_ack_o,
  wb_err_o,
  wb_rty_o
);

  output DTxPRI;
  output DTxSEC;
  output TSCLKx;
  output TFSx;
  input DRxPRI;
  input DRxSEC;
  output RSCLKx;
  output RFSx;
  input wb_clk_i;
  input wb_rst_i;
  input [32-1:0] wb_dat_i;
  output [32-1:0] wb_dat_o;
  input wb_cyc_i;
  input wb_stb_i;
  input wb_we_i;
  input [6-1:0] wb_adr_i;
  output wb_ack_o;
  output wb_err_o;
  output wb_rty_o;
  output rx_int;
  input rxclk;
  input txclk;
  wire rst;
  reg [32:0] data;
  reg [2:0] state;reg [2:0] next_state;
  reg [2:0] rxstate;reg [2:0] next_rxstate;
  wire clk;
  reg lock_cfg;
  reg [31:0] rxPri;reg [31:0] rxSec;
  wire [4:0] rxsampleCnt;
  wire [10-1:0] rxpacketCnt;
  wire [4:0] txsampleCnt;
  wire [10-1:0] txpacketCnt;
  wire [31:0] word_in;
  wire [31:0] word_out;
  wire rxsecEn;
  wire rxlateFS_earlyFSn;
  wire txsecEn;
  wire txlateFS_earlyFSn;
  wire tx_actHi;
  wire rx_actHi;
  wire msbFirst;
  wire tx_start;wire rx_start;
  reg [4:0] rxsampleCnt_rxint;
  reg [10-1:0] rxpacketCnt_rxint;
  reg [4:0] txsampleCnt_txint;
  reg [10-1:0] txpacketCnt_txint;
  reg rxsecEn_rxint;
  reg rxlateFS_earlyFSn_rxint;
  reg txsecEn_txint;
  reg txlateFS_earlyFSn_txint;
  reg tx_actHi_txint;
  reg rx_actHi_rxint;
  reg msbFirst_txint;
  reg tx_start_txint;reg rx_start_rxint;
  reg [4:0] rxsampleCnt_rx;
  reg [10-1:0] rxpacketCnt_rx;
  reg [4:0] txsampleCnt_tx;
  reg [10-1:0] txpacketCnt_tx;
  reg rxsecEn_rx;
  reg rxlateFS_earlyFSn_rx;
  reg txsecEn_tx;
  reg txlateFS_earlyFSn_tx;
  reg tx_actHi_tx;
  reg rx_actHi_rx;
  reg msbFirst_tx;
  reg tx_start_tx;reg rx_start_rx;
  reg rxidle;
  reg rx;
  reg rxFS;
  reg txidle;
  reg tx;
  reg txFS;
  reg [31:0] word_outM;reg [31:0] word_outL;
  reg txfs;reg rxfs;
  wire [31:0] data_out;
  assign RSCLKx = rxclk;
  assign RFSx = (rx_actHi_rxint)? rxFS : ~rxFS;

  always @(posedge rxclk or posedge rst) begin
    if(rst) rxstate <= 3'h0; 
    else rxstate <= next_rxstate;
  end


  always @(*) begin
    next_rxstate = 3'h1;
    rxidle = 1'b0;
    rx = 1'b0;
    rxfs = 1'b0;
    case(state)
      3'h0: begin
        next_rxstate = 3'h1;
      end
      3'h1: begin
        rxidle = 1'b1;
        if(rx_start_rxint) next_rxstate = 3'h3; 
        else next_rxstate = 3'h1;
      end
      3'h3: begin
        rxfs = 1'b1;
        next_rxstate = 3'h2;
      end
      3'h2: begin
        rx = 1'b1;
        if(rxsampleCnt_rx == rxsampleCnt_rxint) next_rxstate = 3'h1; 
        else if(rxpacketCnt_rx == rxpacketCnt_rxint) next_rxstate = 3'h3; 
        else next_rxstate = 3'h2;
      end
      default: next_rxstate = 3'h1;
    endcase
  end


  always @(posedge rxclk or posedge rst) begin
    if(rst) begin
      rxPri <= 32'h0;
      rxSec <= 32'h0;
    end else begin
      rxPri <= { rxPri[30:0], DRxPRI };
      rxSec <= { rxSec[30:0], DRxSEC };
    end
  end


  always @(posedge rxclk or posedge rst) begin
    if(rst) rxsampleCnt_rx <= 5'h0; 
    else if(rx) begin
      if(rxsecEn_rxint) rxsampleCnt_rx <= rxsampleCnt_rx + 2; 
      else rxsampleCnt_rx <= rxsampleCnt_rx + 1;
    end else rxsampleCnt_rx <= 5'h0;
  end


  always @(posedge rxclk or posedge rst) begin
    if(rst) rxpacketCnt_rx <= 5'h0; 
    else if(rx) begin
      if(rxsecEn_rxint) rxpacketCnt_rx <= rxpacketCnt_rx + 2; 
      else rxpacketCnt_rx <= rxpacketCnt_rx + 1;
    end else rxpacketCnt_rx <= 5'h0;
  end


  always @(posedge rxclk or posedge rst) begin
    if(rst) rxFS <= 1'b0; 
    else rxFS <= (rxlateFS_earlyFSn_rxint)? rx : rxfs;
  end

  assign TSCLKx = txclk;
  assign TFSx = (tx_actHi_txint)? txFS : ~txFS;

  always @(posedge txclk or posedge rst) begin
    if(rst) state <= 3'h0; 
    else state <= next_state;
  end


  always @(*) begin
    next_state = 3'h1;
    txidle = 1'b0;
    tx = 1'b0;
    txfs = 1'b0;
    case(state)
      3'h0: begin
        next_state = 3'h1;
      end
      3'h1: begin
        txidle = 1'b1;
        if(tx_start_txint) next_state = 3'h3; 
        else next_state = 3'h1;
      end
      3'h3: begin
        txfs = 1'b1;
        next_state = 3'h2;
      end
      3'h2: begin
        tx = 1'b1;
        if(txsampleCnt_tx == txsampleCnt_txint) next_state = 3'h1; 
        else if(txpacketCnt_tx == txpacketCnt_txint) next_state = 3'h3; 
        else next_state = 3'h2;
      end
      default: next_state = 3'h1;
    endcase
  end


  always @(posedge txclk or posedge rst) begin
    if(rst) txsampleCnt_tx <= 5'h0; 
    else if(tx) begin
      if(txsecEn_txint) txsampleCnt_tx <= txsampleCnt_tx + 2; 
      else txsampleCnt_tx <= txsampleCnt_tx + 1;
    end else txsampleCnt_tx <= 5'h0;
  end


  always @(posedge txclk or posedge rst) begin
    if(rst) txpacketCnt_tx <= 5'h0; 
    else if(tx) begin
      if(txsecEn_txint) txpacketCnt_tx <= txpacketCnt_tx + 2; 
      else txpacketCnt_tx <= txpacketCnt_tx + 1;
    end else txpacketCnt_tx <= 5'h0;
  end

  assign DTxPRI = (msbFirst)? word_outM[31] : word_outL[31];
  assign DTxSEC = (txsecEn_tx)? (msbFirst)? word_outM[16] : word_outL[17] : 1'b0;

  always @(posedge txclk or posedge rst) begin
    if(rst) word_outM <= 32'h0; 
    else if(tx) word_outM <= { word_outM[30:0], 1'b0 }; 
    else if(txfs) word_outM <= data_out; 
  end


  always @(posedge txclk or posedge rst) begin
    if(rst) word_outL <= 32'h0; 
    else if(tx) word_outL <= { word_outL[30:0], 1'b0 }; 
    else if(txfs) word_outL <= { data_out[0], data_out[1], data_out[2], data_out[3], data_out[4], data_out[5], data_out[6], data_out[7], data_out[8], data_out[9], data_out[10], data_out[11], data_out[12], data_out[13], data_out[14], data_out[15], data_out[16], data_out[17], data_out[18], data_out[19], data_out[20], data_out[21], data_out[22], data_out[23], data_out[24], data_out[25], data_out[26], data_out[27], data_out[28], data_out[29], data_out[30], data_out[31] }; 
  end


  always @(posedge txclk or posedge rst) begin
    if(rst) txFS <= 1'b0; 
    else txFS <= (txlateFS_earlyFSn_txint)? tx : txfs;
  end


  fifo_sport
  datafifowrite
  (
    clk,
    txclk,
    wb_data_i,
    data_out,
    rst,
    wb_wr_en,
    wei_rd_en,
    fullwrite,
    emptywrite
  );


  fifo_sport
  datafiforead
  (
    rxclk,
    clk,
    wb_data_i,
    data_o,
    rst,
    wb_wr_en,
    wei_rd_en,
    fullread,
    emptyread
  );


  always @(posedge rxclk or posedge rst) begin
    if(rst) rxsampleCnt_rxint <= 5'h0; 
    else rxsampleCnt_rxint <= rxsampleCnt;
  end


  always @(posedge rxclk or posedge rst) begin
    if(rst) rxpacketCnt_rxint <= 10'h0; 
    else rxpacketCnt_rxint <= rxpacketCnt;
  end


  always @(posedge txclk or posedge rst) begin
    if(rst) txsampleCnt_txint <= 5'h0; 
    else txsampleCnt_txint <= txsampleCnt;
  end


  always @(posedge txclk or posedge rst) begin
    if(rst) txpacketCnt_txint <= 10'h0; 
    else txpacketCnt_txint <= txpacketCnt;
  end


  always @(posedge rxclk or posedge rst) begin
    if(rst) rxsecEn_rxint <= 1'b0; 
    else rxsecEn_rxint <= rxsecEn;
  end


  always @(posedge rxclk or posedge rst) begin
    if(rst) rxlateFS_earlyFSn_rxint <= 1'b0; 
    else rxlateFS_earlyFSn_rxint <= rxlateFS_earlyFSn;
  end


  always @(posedge txclk or posedge rst) begin
    if(rst) txlateFS_earlyFSn_txint <= 1'b0; 
    else txlateFS_earlyFSn_txint <= txlateFS_earlyFSn;
  end


  always @(posedge txclk or posedge rst) begin
    if(rst) txsecEn_txint <= 1'b0; 
    else txsecEn_txint <= txsecEn;
  end


  always @(posedge txclk or posedge rst) begin
    if(rst) txlateFS_earlyFSn_txint <= 1'b0; 
    else txlateFS_earlyFSn_txint <= txlateFS_earlyFSn;
  end


  always @(posedge txclk or posedge rst) begin
    if(rst) tx_actHi_txint <= 1'b0; 
    else tx_actHi_txint <= tx_actHi;
  end


  always @(posedge rxclk or posedge rst) begin
    if(rst) rx_actHi_rxint <= 1'b0; 
    else rx_actHi_rxint <= rx_actHi;
  end


  always @(posedge txclk or posedge rst) begin
    if(rst) msbFirst_txint <= 1'b0; 
    else msbFirst_txint <= msbFirst;
  end


  always @(posedge txclk or posedge rst) begin
    if(rst) tx_start_txint <= 1'b0; 
    else tx_start_txint <= tx_start;
  end


  always @(posedge rxclk or posedge rst) begin
    if(rst) rx_start_rxint <= 1'b0; 
    else rx_start_rxint <= rx_start;
  end


  wb_interface_sport
  wb_interface
  (
    wb_rst_i,
    wb_clk_i,
    wb_stb_i,
    wb_ack_o,
    wb_adr_i,
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
    word_in,
    word_out,
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


endmodule

