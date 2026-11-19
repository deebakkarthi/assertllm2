

module eth_registers
(
  DataIn,
  Address,
  Rw,
  Cs,
  Clk,
  Reset,
  DataOut,
  r_RecSmall,
  r_Pad,
  r_HugEn,
  r_CrcEn,
  r_DlyCrcEn,
  r_FullD,
  r_ExDfrEn,
  r_NoBckof,
  r_LoopBck,
  r_IFG,
  r_Pro,
  r_Iam,
  r_Bro,
  r_NoPre,
  r_TxEn,
  r_RxEn,
  TxB_IRQ,
  TxE_IRQ,
  RxB_IRQ,
  RxE_IRQ,
  Busy_IRQ,
  r_IPGT,
  r_IPGR1,
  r_IPGR2,
  r_MinFL,
  r_MaxFL,
  r_MaxRet,
  r_CollValid,
  r_TxFlow,
  r_RxFlow,
  r_PassAll,
  r_MiiNoPre,
  r_ClkDiv,
  r_WCtrlData,
  r_RStat,
  r_ScanStat,
  r_RGAD,
  r_FIAD,
  r_CtrlData,
  NValid_stat,
  Busy_stat,
  LinkFail,
  r_MAC,
  WCtrlDataStart,
  RStatStart,
  UpdateMIIRX_DATAReg,
  Prsd,
  r_TxBDNum,
  int_o,
  r_HASH0,
  r_HASH1,
  r_TxPauseTV,
  r_TxPauseRq,
  RstTxPauseRq,
  TxCtrlEndFrm,
  dbg_dat,
  StartTxDone,
  TxClk,
  RxClk,
  SetPauseTimer
);

  input [31:0] DataIn;
  input [7:0] Address;
  input Rw;
  input [3:0] Cs;
  input Clk;
  input Reset;
  input WCtrlDataStart;
  input RStatStart;
  input UpdateMIIRX_DATAReg;
  input [15:0] Prsd;
  output [31:0] DataOut;
  reg [31:0] DataOut;
  output r_RecSmall;
  output r_Pad;
  output r_HugEn;
  output r_CrcEn;
  output r_DlyCrcEn;
  output r_FullD;
  output r_ExDfrEn;
  output r_NoBckof;
  output r_LoopBck;
  output r_IFG;
  output r_Pro;
  output r_Iam;
  output r_Bro;
  output r_NoPre;
  output r_TxEn;
  output r_RxEn;
  output [31:0] r_HASH0;
  output [31:0] r_HASH1;
  input TxB_IRQ;
  input TxE_IRQ;
  input RxB_IRQ;
  input RxE_IRQ;
  input Busy_IRQ;
  output [6:0] r_IPGT;
  output [6:0] r_IPGR1;
  output [6:0] r_IPGR2;
  output [15:0] r_MinFL;
  output [15:0] r_MaxFL;
  output [3:0] r_MaxRet;
  output [5:0] r_CollValid;
  output r_TxFlow;
  output r_RxFlow;
  output r_PassAll;
  output r_MiiNoPre;
  output [7:0] r_ClkDiv;
  output r_WCtrlData;
  output r_RStat;
  output r_ScanStat;
  output [4:0] r_RGAD;
  output [4:0] r_FIAD;
  output [15:0] r_CtrlData;
  input NValid_stat;
  input Busy_stat;
  input LinkFail;
  output [47:0] r_MAC;
  output [7:0] r_TxBDNum;
  output int_o;
  output [15:0] r_TxPauseTV;
  output r_TxPauseRq;
  input RstTxPauseRq;
  input TxCtrlEndFrm;
  input StartTxDone;
  input TxClk;
  input RxClk;
  input SetPauseTimer;
  input [31:0] dbg_dat;
  reg irq_txb;
  reg irq_txe;
  reg irq_rxb;
  reg irq_rxe;
  reg irq_busy;
  reg irq_txc;
  reg irq_rxc;
  reg SetTxCIrq_txclk;
  reg SetTxCIrq_sync1;reg SetTxCIrq_sync2;reg SetTxCIrq_sync3;
  reg SetTxCIrq;
  reg ResetTxCIrq_sync1;reg ResetTxCIrq_sync2;
  reg SetRxCIrq_rxclk;
  reg SetRxCIrq_sync1;reg SetRxCIrq_sync2;reg SetRxCIrq_sync3;
  reg SetRxCIrq;
  reg ResetRxCIrq_sync1;
  reg ResetRxCIrq_sync2;
  reg ResetRxCIrq_sync3;
  wire [3:0] Write;assign Write = Cs & { 4{ Rw } };
  wire Read;assign Read = |Cs & ~Rw;
  wire MODER_Sel;assign MODER_Sel = Address == 8'h0;
  wire INT_SOURCE_Sel;assign INT_SOURCE_Sel = Address == 8'h1;
  wire INT_MASK_Sel;assign INT_MASK_Sel = Address == 8'h2;
  wire IPGT_Sel;assign IPGT_Sel = Address == 8'h3;
  wire IPGR1_Sel;assign IPGR1_Sel = Address == 8'h4;
  wire IPGR2_Sel;assign IPGR2_Sel = Address == 8'h5;
  wire PACKETLEN_Sel;assign PACKETLEN_Sel = Address == 8'h6;
  wire COLLCONF_Sel;assign COLLCONF_Sel = Address == 8'h7;
  wire CTRLMODER_Sel;assign CTRLMODER_Sel = Address == 8'h9;
  wire MIIMODER_Sel;assign MIIMODER_Sel = Address == 8'hA;
  wire MIICOMMAND_Sel;assign MIICOMMAND_Sel = Address == 8'hB;
  wire MIIADDRESS_Sel;assign MIIADDRESS_Sel = Address == 8'hC;
  wire MIITX_DATA_Sel;assign MIITX_DATA_Sel = Address == 8'hD;
  wire MAC_ADDR0_Sel;assign MAC_ADDR0_Sel = Address == 8'h10;
  wire MAC_ADDR1_Sel;assign MAC_ADDR1_Sel = Address == 8'h11;
  wire HASH0_Sel;assign HASH0_Sel = Address == 8'h12;
  wire HASH1_Sel;assign HASH1_Sel = Address == 8'h13;
  wire TXCTRL_Sel;assign TXCTRL_Sel = Address == 8'h14;
  wire RXCTRL_Sel;assign RXCTRL_Sel = Address == 8'h15;
  wire DBG_REG_Sel;assign DBG_REG_Sel = Address == 8'h16;
  wire TX_BD_NUM_Sel;assign TX_BD_NUM_Sel = Address == 8'h8;
  wire [2:0] MODER_Wr;
  wire [0:0] INT_SOURCE_Wr;
  wire [0:0] INT_MASK_Wr;
  wire [0:0] IPGT_Wr;
  wire [0:0] IPGR1_Wr;
  wire [0:0] IPGR2_Wr;
  wire [3:0] PACKETLEN_Wr;
  wire [2:0] COLLCONF_Wr;
  wire [0:0] CTRLMODER_Wr;
  wire [1:0] MIIMODER_Wr;
  wire [0:0] MIICOMMAND_Wr;
  wire [1:0] MIIADDRESS_Wr;
  wire [1:0] MIITX_DATA_Wr;
  wire MIIRX_DATA_Wr;
  wire [3:0] MAC_ADDR0_Wr;
  wire [1:0] MAC_ADDR1_Wr;
  wire [3:0] HASH0_Wr;
  wire [3:0] HASH1_Wr;
  wire [2:0] TXCTRL_Wr;
  wire [0:0] TX_BD_NUM_Wr;
  assign MODER_Wr[0] = Write[0] & MODER_Sel;
  assign MODER_Wr[1] = Write[1] & MODER_Sel;
  assign MODER_Wr[2] = Write[2] & MODER_Sel;
  assign INT_SOURCE_Wr[0] = Write[0] & INT_SOURCE_Sel;
  assign INT_MASK_Wr[0] = Write[0] & INT_MASK_Sel;
  assign IPGT_Wr[0] = Write[0] & IPGT_Sel;
  assign IPGR1_Wr[0] = Write[0] & IPGR1_Sel;
  assign IPGR2_Wr[0] = Write[0] & IPGR2_Sel;
  assign PACKETLEN_Wr[0] = Write[0] & PACKETLEN_Sel;
  assign PACKETLEN_Wr[1] = Write[1] & PACKETLEN_Sel;
  assign PACKETLEN_Wr[2] = Write[2] & PACKETLEN_Sel;
  assign PACKETLEN_Wr[3] = Write[3] & PACKETLEN_Sel;
  assign COLLCONF_Wr[0] = Write[0] & COLLCONF_Sel;
  assign COLLCONF_Wr[1] = 1'b0;
  assign COLLCONF_Wr[2] = Write[2] & COLLCONF_Sel;
  assign CTRLMODER_Wr[0] = Write[0] & CTRLMODER_Sel;
  assign MIIMODER_Wr[0] = Write[0] & MIIMODER_Sel;
  assign MIIMODER_Wr[1] = Write[1] & MIIMODER_Sel;
  assign MIICOMMAND_Wr[0] = Write[0] & MIICOMMAND_Sel;
  assign MIIADDRESS_Wr[0] = Write[0] & MIIADDRESS_Sel;
  assign MIIADDRESS_Wr[1] = Write[1] & MIIADDRESS_Sel;
  assign MIITX_DATA_Wr[0] = Write[0] & MIITX_DATA_Sel;
  assign MIITX_DATA_Wr[1] = Write[1] & MIITX_DATA_Sel;
  assign MIIRX_DATA_Wr = UpdateMIIRX_DATAReg;
  assign MAC_ADDR0_Wr[0] = Write[0] & MAC_ADDR0_Sel;
  assign MAC_ADDR0_Wr[1] = Write[1] & MAC_ADDR0_Sel;
  assign MAC_ADDR0_Wr[2] = Write[2] & MAC_ADDR0_Sel;
  assign MAC_ADDR0_Wr[3] = Write[3] & MAC_ADDR0_Sel;
  assign MAC_ADDR1_Wr[0] = Write[0] & MAC_ADDR1_Sel;
  assign MAC_ADDR1_Wr[1] = Write[1] & MAC_ADDR1_Sel;
  assign HASH0_Wr[0] = Write[0] & HASH0_Sel;
  assign HASH0_Wr[1] = Write[1] & HASH0_Sel;
  assign HASH0_Wr[2] = Write[2] & HASH0_Sel;
  assign HASH0_Wr[3] = Write[3] & HASH0_Sel;
  assign HASH1_Wr[0] = Write[0] & HASH1_Sel;
  assign HASH1_Wr[1] = Write[1] & HASH1_Sel;
  assign HASH1_Wr[2] = Write[2] & HASH1_Sel;
  assign HASH1_Wr[3] = Write[3] & HASH1_Sel;
  assign TXCTRL_Wr[0] = Write[0] & TXCTRL_Sel;
  assign TXCTRL_Wr[1] = Write[1] & TXCTRL_Sel;
  assign TXCTRL_Wr[2] = Write[2] & TXCTRL_Sel;
  assign TX_BD_NUM_Wr[0] = Write[0] & TX_BD_NUM_Sel & (DataIn <= 'h80);
  wire [31:0] MODEROut;
  wire [31:0] INT_SOURCEOut;
  wire [31:0] INT_MASKOut;
  wire [31:0] IPGTOut;
  wire [31:0] IPGR1Out;
  wire [31:0] IPGR2Out;
  wire [31:0] PACKETLENOut;
  wire [31:0] COLLCONFOut;
  wire [31:0] CTRLMODEROut;
  wire [31:0] MIIMODEROut;
  wire [31:0] MIICOMMANDOut;
  wire [31:0] MIIADDRESSOut;
  wire [31:0] MIITX_DATAOut;
  wire [31:0] MIIRX_DATAOut;
  wire [31:0] MIISTATUSOut;
  wire [31:0] MAC_ADDR0Out;
  wire [31:0] MAC_ADDR1Out;
  wire [31:0] TX_BD_NUMOut;
  wire [31:0] HASH0Out;
  wire [31:0] HASH1Out;
  wire [31:0] TXCTRLOut;
  wire [31:0] DBGOut;

  eth_register
  #(
    8,
    8'h00
  )
  MODER_0
  (
    .DataIn(DataIn[8-1:0]),
    .DataOut(MODEROut[8-1:0]),
    .Write(MODER_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'hA0
  )
  MODER_1
  (
    .DataIn(DataIn[8+7:8]),
    .DataOut(MODEROut[8+7:8]),
    .Write(MODER_Wr[1]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    1,
    1'h0
  )
  MODER_2
  (
    .DataIn(DataIn[1+15:16]),
    .DataOut(MODEROut[1+15:16]),
    .Write(MODER_Wr[2]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );

  assign MODEROut[31:1+16] = 0;

  eth_register
  #(
    7,
    7'h0
  )
  INT_MASK_0
  (
    .DataIn(DataIn[7-1:0]),
    .DataOut(INT_MASKOut[7-1:0]),
    .Write(INT_MASK_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );

  assign INT_MASKOut[31:7] = 0;

  eth_register
  #(
    7,
    7'h12
  )
  IPGT_0
  (
    .DataIn(DataIn[7-1:0]),
    .DataOut(IPGTOut[7-1:0]),
    .Write(IPGT_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );

  assign IPGTOut[31:7] = 0;

  eth_register
  #(
    7,
    7'h0C
  )
  IPGR1_0
  (
    .DataIn(DataIn[7-1:0]),
    .DataOut(IPGR1Out[7-1:0]),
    .Write(IPGR1_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );

  assign IPGR1Out[31:7] = 0;

  eth_register
  #(
    7,
    7'h12
  )
  IPGR2_0
  (
    .DataIn(DataIn[7-1:0]),
    .DataOut(IPGR2Out[7-1:0]),
    .Write(IPGR2_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );

  assign IPGR2Out[31:7] = 0;

  eth_register
  #(
    8,
    8'h00
  )
  PACKETLEN_0
  (
    .DataIn(DataIn[8-1:0]),
    .DataOut(PACKETLENOut[8-1:0]),
    .Write(PACKETLEN_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'h06
  )
  PACKETLEN_1
  (
    .DataIn(DataIn[8+7:8]),
    .DataOut(PACKETLENOut[8+7:8]),
    .Write(PACKETLEN_Wr[1]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'h40
  )
  PACKETLEN_2
  (
    .DataIn(DataIn[8+15:16]),
    .DataOut(PACKETLENOut[8+15:16]),
    .Write(PACKETLEN_Wr[2]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'h00
  )
  PACKETLEN_3
  (
    .DataIn(DataIn[8+23:24]),
    .DataOut(PACKETLENOut[8+23:24]),
    .Write(PACKETLEN_Wr[3]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    6,
    6'h3f
  )
  COLLCONF_0
  (
    .DataIn(DataIn[6-1:0]),
    .DataOut(COLLCONFOut[6-1:0]),
    .Write(COLLCONF_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    4,
    4'hF
  )
  COLLCONF_2
  (
    .DataIn(DataIn[4+15:16]),
    .DataOut(COLLCONFOut[4+15:16]),
    .Write(COLLCONF_Wr[2]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );

  assign COLLCONFOut[15:6] = 0;
  assign COLLCONFOut[31:4+16] = 0;

  eth_register
  #(
    8,
    8'h40
  )
  TX_BD_NUM_0
  (
    .DataIn(DataIn[8-1:0]),
    .DataOut(TX_BD_NUMOut[8-1:0]),
    .Write(TX_BD_NUM_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );

  assign TX_BD_NUMOut[31:8] = 0;

  eth_register
  #(
    3,
    3'h0
  )
  CTRLMODER_0
  (
    .DataIn(DataIn[3-1:0]),
    .DataOut(CTRLMODEROut[3-1:0]),
    .Write(CTRLMODER_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );

  assign CTRLMODEROut[31:3] = 0;

  eth_register
  #(
    8,
    8'h64
  )
  MIIMODER_0
  (
    .DataIn(DataIn[8-1:0]),
    .DataOut(MIIMODEROut[8-1:0]),
    .Write(MIIMODER_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    1,
    1'h0
  )
  MIIMODER_1
  (
    .DataIn(DataIn[1+7:8]),
    .DataOut(MIIMODEROut[1+7:8]),
    .Write(MIIMODER_Wr[1]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );

  assign MIIMODEROut[31:1+8] = 0;

  eth_register
  #(
    1,
    0
  )
  MIICOMMAND0
  (
    .DataIn(DataIn[0]),
    .DataOut(MIICOMMANDOut[0]),
    .Write(MIICOMMAND_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    1,
    0
  )
  MIICOMMAND1
  (
    .DataIn(DataIn[1]),
    .DataOut(MIICOMMANDOut[1]),
    .Write(MIICOMMAND_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(RStatStart)
  );


  eth_register
  #(
    1,
    0
  )
  MIICOMMAND2
  (
    .DataIn(DataIn[2]),
    .DataOut(MIICOMMANDOut[2]),
    .Write(MIICOMMAND_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(WCtrlDataStart)
  );

  assign MIICOMMANDOut[31:3] = 29'h0;

  eth_register
  #(
    5,
    5'h00
  )
  MIIADDRESS_0
  (
    .DataIn(DataIn[5-1:0]),
    .DataOut(MIIADDRESSOut[5-1:0]),
    .Write(MIIADDRESS_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    5,
    5'h00
  )
  MIIADDRESS_1
  (
    .DataIn(DataIn[5+7:8]),
    .DataOut(MIIADDRESSOut[5+7:8]),
    .Write(MIIADDRESS_Wr[1]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );

  assign MIIADDRESSOut[7:5] = 0;
  assign MIIADDRESSOut[31:5+8] = 0;

  eth_register
  #(
    8,
    8'h00
  )
  MIITX_DATA_0
  (
    .DataIn(DataIn[8-1:0]),
    .DataOut(MIITX_DATAOut[8-1:0]),
    .Write(MIITX_DATA_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'h00
  )
  MIITX_DATA_1
  (
    .DataIn(DataIn[8+7:8]),
    .DataOut(MIITX_DATAOut[8+7:8]),
    .Write(MIITX_DATA_Wr[1]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );

  assign MIITX_DATAOut[31:8+8] = 0;

  eth_register
  #(
    16,
    16'h0000
  )
  MIIRX_DATA
  (
    .DataIn(Prsd[16-1:0]),
    .DataOut(MIIRX_DATAOut[16-1:0]),
    .Write(MIIRX_DATA_Wr),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );

  assign MIIRX_DATAOut[31:16] = 0;

  eth_register
  #(
    8,
    8'h00
  )
  MAC_ADDR0_0
  (
    .DataIn(DataIn[8-1:0]),
    .DataOut(MAC_ADDR0Out[8-1:0]),
    .Write(MAC_ADDR0_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'h00
  )
  MAC_ADDR0_1
  (
    .DataIn(DataIn[8+7:8]),
    .DataOut(MAC_ADDR0Out[8+7:8]),
    .Write(MAC_ADDR0_Wr[1]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'h00
  )
  MAC_ADDR0_2
  (
    .DataIn(DataIn[8+15:16]),
    .DataOut(MAC_ADDR0Out[8+15:16]),
    .Write(MAC_ADDR0_Wr[2]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'h00
  )
  MAC_ADDR0_3
  (
    .DataIn(DataIn[8+23:24]),
    .DataOut(MAC_ADDR0Out[8+23:24]),
    .Write(MAC_ADDR0_Wr[3]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'h00
  )
  MAC_ADDR1_0
  (
    .DataIn(DataIn[8-1:0]),
    .DataOut(MAC_ADDR1Out[8-1:0]),
    .Write(MAC_ADDR1_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'h00
  )
  MAC_ADDR1_1
  (
    .DataIn(DataIn[8+7:8]),
    .DataOut(MAC_ADDR1Out[8+7:8]),
    .Write(1'b0),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(MAC_ADDR1_Wr[1])
  );

  assign MAC_ADDR1Out[31:8+8] = 0;

  eth_register
  #(
    8,
    8'h00
  )
  RXHASH0_0
  (
    .DataIn(DataIn[8-1:0]),
    .DataOut(HASH0Out[8-1:0]),
    .Write(HASH0_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'h00
  )
  RXHASH0_1
  (
    .DataIn(DataIn[8+7:8]),
    .DataOut(HASH0Out[8+7:8]),
    .Write(HASH0_Wr[1]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'h00
  )
  RXHASH0_2
  (
    .DataIn(DataIn[8+15:16]),
    .DataOut(HASH0Out[8+15:16]),
    .Write(HASH0_Wr[2]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'h00
  )
  RXHASH0_3
  (
    .DataIn(DataIn[8+23:24]),
    .DataOut(HASH0Out[8+23:24]),
    .Write(HASH0_Wr[3]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'h00
  )
  RXHASH1_0
  (
    .DataIn(DataIn[8-1:0]),
    .DataOut(HASH1Out[8-1:0]),
    .Write(HASH1_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'h00
  )
  RXHASH1_1
  (
    .DataIn(DataIn[8+7:8]),
    .DataOut(HASH1Out[8+7:8]),
    .Write(HASH1_Wr[1]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'h00
  )
  RXHASH1_2
  (
    .DataIn(DataIn[8+15:16]),
    .DataOut(HASH1Out[8+15:16]),
    .Write(HASH1_Wr[2]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'h00
  )
  RXHASH1_3
  (
    .DataIn(DataIn[8+23:24]),
    .DataOut(HASH1Out[8+23:24]),
    .Write(HASH1_Wr[3]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'h00
  )
  TXCTRL_0
  (
    .DataIn(DataIn[8-1:0]),
    .DataOut(TXCTRLOut[8-1:0]),
    .Write(TXCTRL_Wr[0]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    8,
    8'h00
  )
  TXCTRL_1
  (
    .DataIn(DataIn[8+7:8]),
    .DataOut(TXCTRLOut[8+7:8]),
    .Write(TXCTRL_Wr[1]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(1'b0)
  );


  eth_register
  #(
    1,
    1'h0
  )
  TXCTRL_2
  (
    .DataIn(DataIn[1+15:16]),
    .DataOut(TXCTRLOut[1+15:16]),
    .Write(TXCTRL_Wr[2]),
    .Clk(Clk),
    .Reset(Reset),
    .SyncReset(RstTxPauseRq)
  );

  assign TXCTRLOut[31:1+16] = 0;

  always @(Address or Read or MODEROut or INT_SOURCEOut or INT_MASKOut or IPGTOut or IPGR1Out or IPGR2Out or PACKETLENOut or COLLCONFOut or CTRLMODEROut or MIIMODEROut or MIICOMMANDOut or MIIADDRESSOut or MIITX_DATAOut or MIIRX_DATAOut or MIISTATUSOut or MAC_ADDR0Out or MAC_ADDR1Out or TX_BD_NUMOut or HASH0Out or HASH1Out or TXCTRLOut) begin
    if(Read) begin
      case(Address)
        8'h0: DataOut = MODEROut;
        8'h1: DataOut = INT_SOURCEOut;
        8'h2: DataOut = INT_MASKOut;
        8'h3: DataOut = IPGTOut;
        8'h4: DataOut = IPGR1Out;
        8'h5: DataOut = IPGR2Out;
        8'h6: DataOut = PACKETLENOut;
        8'h7: DataOut = COLLCONFOut;
        8'h9: DataOut = CTRLMODEROut;
        8'hA: DataOut = MIIMODEROut;
        8'hB: DataOut = MIICOMMANDOut;
        8'hC: DataOut = MIIADDRESSOut;
        8'hD: DataOut = MIITX_DATAOut;
        8'hE: DataOut = MIIRX_DATAOut;
        8'hF: DataOut = MIISTATUSOut;
        8'h10: DataOut = MAC_ADDR0Out;
        8'h11: DataOut = MAC_ADDR1Out;
        8'h8: DataOut = TX_BD_NUMOut;
        8'h12: DataOut = HASH0Out;
        8'h13: DataOut = HASH1Out;
        8'h14: DataOut = TXCTRLOut;
        8'h16: DataOut = dbg_dat;
        default: DataOut = 32'h0;
      endcase
    end else DataOut = 32'h0;
  end

  assign r_RecSmall = MODEROut[16];
  assign r_Pad = MODEROut[15];
  assign r_HugEn = MODEROut[14];
  assign r_CrcEn = MODEROut[13];
  assign r_DlyCrcEn = MODEROut[12];
  assign r_FullD = MODEROut[10];
  assign r_ExDfrEn = MODEROut[9];
  assign r_NoBckof = MODEROut[8];
  assign r_LoopBck = MODEROut[7];
  assign r_IFG = MODEROut[6];
  assign r_Pro = MODEROut[5];
  assign r_Iam = MODEROut[4];
  assign r_Bro = MODEROut[3];
  assign r_NoPre = MODEROut[2];
  assign r_TxEn = MODEROut[1] & (TX_BD_NUMOut > 0);
  assign r_RxEn = MODEROut[0] & (TX_BD_NUMOut < 'h80);
  assign r_IPGT[6:0] = IPGTOut[6:0];
  assign r_IPGR1[6:0] = IPGR1Out[6:0];
  assign r_IPGR2[6:0] = IPGR2Out[6:0];
  assign r_MinFL[15:0] = PACKETLENOut[31:16];
  assign r_MaxFL[15:0] = PACKETLENOut[15:0];
  assign r_MaxRet[3:0] = COLLCONFOut[19:16];
  assign r_CollValid[5:0] = COLLCONFOut[5:0];
  assign r_TxFlow = CTRLMODEROut[2];
  assign r_RxFlow = CTRLMODEROut[1];
  assign r_PassAll = CTRLMODEROut[0];
  assign r_MiiNoPre = MIIMODEROut[8];
  assign r_ClkDiv[7:0] = MIIMODEROut[7:0];
  assign r_WCtrlData = MIICOMMANDOut[2];
  assign r_RStat = MIICOMMANDOut[1];
  assign r_ScanStat = MIICOMMANDOut[0];
  assign r_RGAD[4:0] = MIIADDRESSOut[12:8];
  assign r_FIAD[4:0] = MIIADDRESSOut[4:0];
  assign r_CtrlData[15:0] = MIITX_DATAOut[15:0];
  assign MIISTATUSOut[31:3] = 0;
  assign MIISTATUSOut[2] = NValid_stat;
  assign MIISTATUSOut[1] = Busy_stat;
  assign MIISTATUSOut[0] = LinkFail;
  assign r_MAC[31:0] = MAC_ADDR0Out[31:0];
  assign r_MAC[47:32] = MAC_ADDR1Out[15:0];
  assign r_HASH1[31:0] = HASH1Out;
  assign r_HASH0[31:0] = HASH0Out;
  assign r_TxBDNum[7:0] = TX_BD_NUMOut[7:0];
  assign r_TxPauseTV[15:0] = TXCTRLOut[15:0];
  assign r_TxPauseRq = TXCTRLOut[16];

  always @(posedge TxClk or posedge Reset) begin
    if(Reset) SetTxCIrq_txclk <= 1'b0; 
    else if(TxCtrlEndFrm & StartTxDone & r_TxFlow) SetTxCIrq_txclk <= 1'b1; 
    else if(ResetTxCIrq_sync2) SetTxCIrq_txclk <= 1'b0; 
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) SetTxCIrq_sync1 <= 1'b0; 
    else SetTxCIrq_sync1 <= SetTxCIrq_txclk;
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) SetTxCIrq_sync2 <= 1'b0; 
    else SetTxCIrq_sync2 <= SetTxCIrq_sync1;
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) SetTxCIrq_sync3 <= 1'b0; 
    else SetTxCIrq_sync3 <= SetTxCIrq_sync2;
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) SetTxCIrq <= 1'b0; 
    else SetTxCIrq <= SetTxCIrq_sync2 & ~SetTxCIrq_sync3;
  end


  always @(posedge TxClk or posedge Reset) begin
    if(Reset) ResetTxCIrq_sync1 <= 1'b0; 
    else ResetTxCIrq_sync1 <= SetTxCIrq_sync2;
  end


  always @(posedge TxClk or posedge Reset) begin
    if(Reset) ResetTxCIrq_sync2 <= 1'b0; 
    else ResetTxCIrq_sync2 <= SetTxCIrq_sync1;
  end


  always @(posedge RxClk or posedge Reset) begin
    if(Reset) SetRxCIrq_rxclk <= 1'b0; 
    else if(SetPauseTimer & r_RxFlow) SetRxCIrq_rxclk <= 1'b1; 
    else if(ResetRxCIrq_sync2 & ~ResetRxCIrq_sync3) SetRxCIrq_rxclk <= 1'b0; 
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) SetRxCIrq_sync1 <= 1'b0; 
    else SetRxCIrq_sync1 <= SetRxCIrq_rxclk;
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) SetRxCIrq_sync2 <= 1'b0; 
    else SetRxCIrq_sync2 <= SetRxCIrq_sync1;
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) SetRxCIrq_sync3 <= 1'b0; 
    else SetRxCIrq_sync3 <= SetRxCIrq_sync2;
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) SetRxCIrq <= 1'b0; 
    else SetRxCIrq <= SetRxCIrq_sync2 & ~SetRxCIrq_sync3;
  end


  always @(posedge RxClk or posedge Reset) begin
    if(Reset) ResetRxCIrq_sync1 <= 1'b0; 
    else ResetRxCIrq_sync1 <= SetRxCIrq_sync2;
  end


  always @(posedge RxClk or posedge Reset) begin
    if(Reset) ResetRxCIrq_sync2 <= 1'b0; 
    else ResetRxCIrq_sync2 <= ResetRxCIrq_sync1;
  end


  always @(posedge RxClk or posedge Reset) begin
    if(Reset) ResetRxCIrq_sync3 <= 1'b0; 
    else ResetRxCIrq_sync3 <= ResetRxCIrq_sync2;
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) irq_txb <= 1'b0; 
    else if(TxB_IRQ) irq_txb <= 1'b1; 
    else if(INT_SOURCE_Wr[0] & DataIn[0]) irq_txb <= 1'b0; 
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) irq_txe <= 1'b0; 
    else if(TxE_IRQ) irq_txe <= 1'b1; 
    else if(INT_SOURCE_Wr[0] & DataIn[1]) irq_txe <= 1'b0; 
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) irq_rxb <= 1'b0; 
    else if(RxB_IRQ) irq_rxb <= 1'b1; 
    else if(INT_SOURCE_Wr[0] & DataIn[2]) irq_rxb <= 1'b0; 
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) irq_rxe <= 1'b0; 
    else if(RxE_IRQ) irq_rxe <= 1'b1; 
    else if(INT_SOURCE_Wr[0] & DataIn[3]) irq_rxe <= 1'b0; 
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) irq_busy <= 1'b0; 
    else if(Busy_IRQ) irq_busy <= 1'b1; 
    else if(INT_SOURCE_Wr[0] & DataIn[4]) irq_busy <= 1'b0; 
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) irq_txc <= 1'b0; 
    else if(SetTxCIrq) irq_txc <= 1'b1; 
    else if(INT_SOURCE_Wr[0] & DataIn[5]) irq_txc <= 1'b0; 
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) irq_rxc <= 1'b0; 
    else if(SetRxCIrq) irq_rxc <= 1'b1; 
    else if(INT_SOURCE_Wr[0] & DataIn[6]) irq_rxc <= 1'b0; 
  end

  assign int_o = irq_txb & INT_MASKOut[0] | irq_txe & INT_MASKOut[1] | irq_rxb & INT_MASKOut[2] | irq_rxe & INT_MASKOut[3] | irq_busy & INT_MASKOut[4] | irq_txc & INT_MASKOut[5] | irq_rxc & INT_MASKOut[6];
  assign INT_SOURCEOut = { { 32 - 7{ 1'b0 } }, irq_rxc, irq_txc, irq_busy, irq_rxe, irq_rxb, irq_txe, irq_txb };

endmodule

