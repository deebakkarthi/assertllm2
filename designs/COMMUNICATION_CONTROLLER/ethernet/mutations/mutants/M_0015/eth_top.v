

module eth_top
(
  wb_clk_i,
  wb_rst_i,
  wb_dat_i,
  wb_dat_o,
  wb_adr_i,
  wb_sel_i,
  wb_we_i,
  wb_cyc_i,
  wb_stb_i,
  wb_ack_o,
  wb_err_o,
  m_wb_adr_o,
  m_wb_sel_o,
  m_wb_we_o,
  m_wb_dat_o,
  m_wb_dat_i,
  m_wb_cyc_o,
  m_wb_stb_o,
  m_wb_ack_i,
  m_wb_err_i,
  mtx_clk_pad_i,
  mtxd_pad_o,
  mtxen_pad_o,
  mtxerr_pad_o,
  mrx_clk_pad_i,
  mrxd_pad_i,
  mrxdv_pad_i,
  mrxerr_pad_i,
  mcoll_pad_i,
  mcrs_pad_i,
  mdc_pad_o,
  md_pad_i,
  md_pad_o,
  md_padoe_o,
  int_o
);

  parameter TX_FIFO_DATA_WIDTH = 32;
  parameter TX_FIFO_DEPTH = 16;
  parameter TX_FIFO_CNT_WIDTH = 5;
  parameter RX_FIFO_DATA_WIDTH = 32;
  parameter RX_FIFO_DEPTH = 16;
  parameter RX_FIFO_CNT_WIDTH = 5;
  input wb_clk_i;
  input wb_rst_i;
  input [31:0] wb_dat_i;
  output [31:0] wb_dat_o;
  output wb_err_o;
  input [11:2] wb_adr_i;
  input [3:0] wb_sel_i;
  input wb_we_i;
  input wb_cyc_i;
  input wb_stb_i;
  output wb_ack_o;
  output [31:0] m_wb_adr_o;
  output [3:0] m_wb_sel_o;
  output m_wb_we_o;
  input [31:0] m_wb_dat_i;
  output [31:0] m_wb_dat_o;
  output m_wb_cyc_o;
  output m_wb_stb_o;
  input m_wb_ack_i;
  input m_wb_err_i;
  wire [29:0] m_wb_adr_tmp;
  input mtx_clk_pad_i;
  output [3:0] mtxd_pad_o;
  output mtxen_pad_o;
  output mtxerr_pad_o;
  input mrx_clk_pad_i;
  input [3:0] mrxd_pad_i;
  input mrxdv_pad_i;
  input mrxerr_pad_i;
  input mcoll_pad_i;
  input mcrs_pad_i;
  input md_pad_i;
  output mdc_pad_o;
  output md_pad_o;
  output md_padoe_o;
  output int_o;
  wire [31:0] wb_dbg_dat0;
  wire [7:0] r_ClkDiv;
  wire r_MiiNoPre;
  wire [15:0] r_CtrlData;
  wire [4:0] r_FIAD;
  wire [4:0] r_RGAD;
  wire r_WCtrlData;
  wire r_RStat;
  wire r_ScanStat;
  wire NValid_stat;
  wire Busy_stat;
  wire LinkFail;
  wire [15:0] Prsd;
  wire WCtrlDataStart;
  wire RStatStart;
  wire UpdateMIIRX_DATAReg;
  wire TxStartFrm;
  wire TxEndFrm;
  wire TxUsedData;
  wire [7:0] TxData;
  wire TxRetry;
  wire TxAbort;
  wire TxUnderRun;
  wire TxDone;
  reg WillSendControlFrame_sync1;
  reg WillSendControlFrame_sync2;
  reg WillSendControlFrame_sync3;
  reg RstTxPauseRq;
  reg TxPauseRq_sync1;
  reg TxPauseRq_sync2;
  reg TxPauseRq_sync3;
  reg TPauseRq;

  initial begin
    $display("          *********************************************");
    $display("          =============================================");
    $display("          eth_top.v will be removed shortly.");
    $display("          Please use ethmac.v as top level file instead");
    $display("          =============================================");
    $display("          *********************************************");
  end


  eth_miim
  miim1
  (
    .Clk(wb_clk_i),
    .Reset(wb_rst_i),
    .Divider(r_ClkDiv),
    .NoPre(r_MiiNoPre),
    .CtrlData(r_CtrlData),
    .Rgad(r_RGAD),
    .Fiad(r_FIAD),
    .WCtrlData(r_WCtrlData),
    .RStat(r_RStat),
    .ScanStat(r_ScanStat),
    .Mdi(md_pad_i),
    .Mdo(md_pad_o),
    .MdoEn(md_padoe_o),
    .Mdc(mdc_pad_o),
    .Busy(Busy_stat),
    .Prsd(Prsd),
    .LinkFail(LinkFail),
    .Nvalid(NValid_stat),
    .WCtrlDataStart(WCtrlDataStart),
    .RStatStart(RStatStart),
    .UpdateMIIRX_DATAReg(UpdateMIIRX_DATAReg)
  );

  wire [3:0] RegCs;
  wire [31:0] RegDataOut;
  wire r_RecSmall;
  wire r_LoopBck;
  wire r_TxEn;
  wire r_RxEn;
  wire MRxDV_Lb;
  wire MRxErr_Lb;
  wire [3:0] MRxD_Lb;
  wire Transmitting;
  wire r_HugEn;
  wire r_DlyCrcEn;
  wire [15:0] r_MaxFL;
  wire [15:0] r_MinFL;
  wire ShortFrame;
  wire DribbleNibble;
  wire ReceivedPacketTooBig;
  wire [47:0] r_MAC;
  wire LoadRxStatus;
  wire [31:0] r_HASH0;
  wire [31:0] r_HASH1;
  wire [7:0] r_TxBDNum;
  wire [6:0] r_IPGT;
  wire [6:0] r_IPGR1;
  wire [6:0] r_IPGR2;
  wire [5:0] r_CollValid;
  wire [15:0] r_TxPauseTV;
  wire r_TxPauseRq;
  wire [3:0] r_MaxRet;
  wire r_NoBckof;
  wire r_ExDfrEn;
  wire r_TxFlow;
  wire r_IFG;
  wire TxB_IRQ;
  wire TxE_IRQ;
  wire RxB_IRQ;
  wire RxE_IRQ;
  wire Busy_IRQ;
  wire ByteSelected;
  wire BDAck;
  wire [31:0] BD_WB_DAT_O;
  wire [3:0] BDCs;
  wire CsMiss;
  wire r_Pad;
  wire r_CrcEn;
  wire r_FullD;
  wire r_Pro;
  wire r_Bro;
  wire r_NoPre;
  wire r_RxFlow;
  wire r_PassAll;
  wire TxCtrlEndFrm;
  wire StartTxDone;
  wire SetPauseTimer;
  wire TxUsedDataIn;
  wire TxDoneIn;
  wire TxAbortIn;
  wire PerPacketPad;
  wire PadOut;
  wire PerPacketCrcEn;
  wire CrcEnOut;
  wire TxStartFrmOut;
  wire TxEndFrmOut;
  wire ReceivedPauseFrm;
  wire ControlFrmAddressOK;
  wire RxStatusWriteLatched_sync2;
  wire LateCollision;
  wire DeferIndication;
  wire LateCollLatched;
  wire DeferLatched;
  wire RstDeferLatched;
  wire CarrierSenseLost;
  wire temp_wb_ack_o;
  wire [31:0] temp_wb_dat_o;
  wire temp_wb_err_o;
  reg temp_wb_ack_o_reg;
  reg [31:0] temp_wb_dat_o_reg;
  reg temp_wb_err_o_reg;
  assign ByteSelected = |wb_sel_i;
  assign RegCs[3] = wb_stb_i & wb_cyc_i & ByteSelected & ~wb_adr_i[11] & ~wb_adr_i[10] & wb_sel_i[3];
  assign RegCs[2] = wb_stb_i & wb_cyc_i & ByteSelected & ~wb_adr_i[11] & ~wb_adr_i[10] & wb_sel_i[2];
  assign RegCs[1] = wb_stb_i & wb_cyc_i & ByteSelected & ~wb_adr_i[10] & ~wb_adr_i[10] & wb_sel_i[1];
  assign RegCs[0] = wb_stb_i & wb_cyc_i & ByteSelected & ~wb_adr_i[11] & ~wb_adr_i[10] & wb_sel_i[0];
  assign BDCs[3] = wb_stb_i & wb_cyc_i & ByteSelected & ~wb_adr_i[11] & wb_adr_i[10] & wb_sel_i[3];
  assign BDCs[2] = wb_stb_i & wb_cyc_i & ByteSelected & ~wb_adr_i[11] & wb_adr_i[10] & wb_sel_i[2];
  assign BDCs[1] = wb_stb_i & wb_cyc_i & ByteSelected & ~wb_adr_i[11] & wb_adr_i[10] & wb_sel_i[1];
  assign BDCs[0] = wb_stb_i & wb_cyc_i & ByteSelected & ~wb_adr_i[11] & wb_adr_i[10] & wb_sel_i[0];
  assign CsMiss = wb_stb_i & wb_cyc_i & ByteSelected & wb_adr_i[11];
  assign temp_wb_dat_o = (|RegCs & ~wb_we_i)? RegDataOut : BD_WB_DAT_O;
  assign temp_wb_err_o = wb_stb_i & wb_cyc_i & (~ByteSelected | CsMiss);
  assign wb_ack_o = temp_wb_ack_o_reg;
  assign wb_dat_o[31:0] = temp_wb_dat_o_reg;
  assign wb_err_o = temp_wb_err_o_reg;
  assign temp_wb_ack_o = |RegCs | BDAck;

  always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if(wb_rst_i) begin
      temp_wb_ack_o_reg <= 1'b0;
      temp_wb_dat_o_reg <= 32'h0;
      temp_wb_err_o_reg <= 1'b0;
    end else begin
      temp_wb_ack_o_reg <= temp_wb_ack_o & ~temp_wb_ack_o_reg;
      temp_wb_dat_o_reg <= temp_wb_dat_o;
      temp_wb_err_o_reg <= temp_wb_err_o & ~temp_wb_err_o_reg;
    end
  end


  eth_registers
  ethreg1
  (
    .DataIn(wb_dat_i),
    .Address(wb_adr_i[9:2]),
    .Rw(wb_we_i),
    .Cs(RegCs),
    .Clk(wb_clk_i),
    .Reset(wb_rst_i),
    .DataOut(RegDataOut),
    .r_RecSmall(r_RecSmall),
    .r_Pad(r_Pad),
    .r_HugEn(r_HugEn),
    .r_CrcEn(r_CrcEn),
    .r_DlyCrcEn(r_DlyCrcEn),
    .r_FullD(r_FullD),
    .r_ExDfrEn(r_ExDfrEn),
    .r_NoBckof(r_NoBckof),
    .r_LoopBck(r_LoopBck),
    .r_IFG(r_IFG),
    .r_Pro(r_Pro),
    .r_Iam(),
    .r_Bro(r_Bro),
    .r_NoPre(r_NoPre),
    .r_TxEn(r_TxEn),
    .r_RxEn(r_RxEn),
    .Busy_IRQ(Busy_IRQ),
    .RxE_IRQ(RxE_IRQ),
    .RxB_IRQ(RxB_IRQ),
    .TxE_IRQ(TxE_IRQ),
    .TxB_IRQ(TxB_IRQ),
    .r_IPGT(r_IPGT),
    .r_IPGR1(r_IPGR1),
    .r_IPGR2(r_IPGR2),
    .r_MinFL(r_MinFL),
    .r_MaxFL(r_MaxFL),
    .r_MaxRet(r_MaxRet),
    .r_CollValid(r_CollValid),
    .r_TxFlow(r_TxFlow),
    .r_RxFlow(r_RxFlow),
    .r_PassAll(r_PassAll),
    .r_MiiNoPre(r_MiiNoPre),
    .r_ClkDiv(r_ClkDiv),
    .r_WCtrlData(r_WCtrlData),
    .r_RStat(r_RStat),
    .r_ScanStat(r_ScanStat),
    .r_RGAD(r_RGAD),
    .r_FIAD(r_FIAD),
    .r_CtrlData(r_CtrlData),
    .NValid_stat(NValid_stat),
    .Busy_stat(Busy_stat),
    .LinkFail(LinkFail),
    .r_MAC(r_MAC),
    .WCtrlDataStart(WCtrlDataStart),
    .RStatStart(RStatStart),
    .UpdateMIIRX_DATAReg(UpdateMIIRX_DATAReg),
    .Prsd(Prsd),
    .r_TxBDNum(r_TxBDNum),
    .int_o(int_o),
    .r_HASH0(r_HASH0),
    .r_HASH1(r_HASH1),
    .r_TxPauseRq(r_TxPauseRq),
    .r_TxPauseTV(r_TxPauseTV),
    .RstTxPauseRq(RstTxPauseRq),
    .TxCtrlEndFrm(TxCtrlEndFrm),
    .StartTxDone(StartTxDone),
    .TxClk(mtx_clk_pad_i),
    .RxClk(mrx_clk_pad_i),
    .dbg_dat(wb_dbg_dat0),
    .SetPauseTimer(SetPauseTimer)
  );

  wire [7:0] RxData;
  wire RxValid;
  wire RxStartFrm;
  wire RxEndFrm;
  wire RxAbort;
  wire WillTransmit;
  wire ResetCollision;
  wire [7:0] TxDataOut;
  wire WillSendControlFrame;
  wire ReceiveEnd;
  wire ReceivedPacketGood;
  wire ReceivedLengthOK;
  wire InvalidSymbol;
  wire LatchedCrcError;
  wire RxLateCollision;
  wire [3:0] RetryCntLatched;
  wire [3:0] RetryCnt;
  wire StartTxAbort;
  wire MaxCollisionOccured;
  wire RetryLimit;
  wire StatePreamble;
  wire [1:0] StateData;

  eth_maccontrol
  maccontrol1
  (
    .MTxClk(mtx_clk_pad_i),
    .TPauseRq(TPauseRq),
    .TxPauseTV(r_TxPauseTV),
    .TxDataIn(TxData),
    .TxStartFrmIn(TxStartFrm),
    .TxEndFrmIn(TxEndFrm),
    .TxUsedDataIn(TxUsedDataIn),
    .TxDoneIn(TxDoneIn),
    .TxAbortIn(TxAbortIn),
    .MRxClk(mrx_clk_pad_i),
    .RxData(RxData),
    .RxValid(RxValid),
    .RxStartFrm(RxStartFrm),
    .RxEndFrm(RxEndFrm),
    .ReceiveEnd(ReceiveEnd),
    .ReceivedPacketGood(ReceivedPacketGood),
    .TxFlow(r_TxFlow),
    .RxFlow(r_RxFlow),
    .DlyCrcEn(r_DlyCrcEn),
    .MAC(r_MAC),
    .PadIn(r_Pad | PerPacketPad),
    .PadOut(PadOut),
    .CrcEnIn(r_CrcEn | PerPacketCrcEn),
    .CrcEnOut(CrcEnOut),
    .TxReset(wb_rst_i),
    .RxReset(wb_rst_i),
    .ReceivedLengthOK(ReceivedLengthOK),
    .TxDataOut(TxDataOut),
    .TxStartFrmOut(TxStartFrmOut),
    .TxEndFrmOut(TxEndFrmOut),
    .TxUsedDataOut(TxUsedData),
    .TxDoneOut(TxDone),
    .TxAbortOut(TxAbort),
    .WillSendControlFrame(WillSendControlFrame),
    .TxCtrlEndFrm(TxCtrlEndFrm),
    .ReceivedPauseFrm(ReceivedPauseFrm),
    .ControlFrmAddressOK(ControlFrmAddressOK),
    .SetPauseTimer(SetPauseTimer),
    .RxStatusWriteLatched_sync2(RxStatusWriteLatched_sync2),
    .r_PassAll(r_PassAll)
  );

  wire TxCarrierSense;
  wire Collision;
  reg CarrierSense_Tx1;
  reg CarrierSense_Tx2;
  reg Collision_Tx1;
  reg Collision_Tx2;
  reg RxEnSync;
  reg WillTransmit_q;
  reg WillTransmit_q2;
  assign MRxDV_Lb = (r_LoopBck)? mtxen_pad_o : mrxdv_pad_i & RxEnSync;
  assign MRxErr_Lb = (r_LoopBck)? mtxerr_pad_o : mrxerr_pad_i & RxEnSync;
  assign MRxD_Lb[3:0] = (r_LoopBck)? mtxd_pad_o[3:0] : mrxd_pad_i[3:0];

  eth_txethmac
  txethmac1
  (
    .MTxClk(mtx_clk_pad_i),
    .Reset(wb_rst_i),
    .CarrierSense(TxCarrierSense),
    .Collision(Collision),
    .TxData(TxDataOut),
    .TxStartFrm(TxStartFrmOut),
    .TxUnderRun(TxUnderRun),
    .TxEndFrm(TxEndFrmOut),
    .Pad(PadOut),
    .MinFL(r_MinFL),
    .CrcEn(CrcEnOut),
    .FullD(r_FullD),
    .HugEn(r_HugEn),
    .DlyCrcEn(r_DlyCrcEn),
    .IPGT(r_IPGT),
    .IPGR1(r_IPGR1),
    .IPGR2(r_IPGR2),
    .CollValid(r_CollValid),
    .MaxRet(r_MaxRet),
    .NoBckof(r_NoBckof),
    .ExDfrEn(r_ExDfrEn),
    .MaxFL(r_MaxFL),
    .MTxEn(mtxen_pad_o),
    .MTxD(mtxd_pad_o),
    .MTxErr(mtxerr_pad_o),
    .TxUsedData(TxUsedDataIn),
    .TxDone(TxDoneIn),
    .TxRetry(TxRetry),
    .TxAbort(TxAbortIn),
    .WillTransmit(WillTransmit),
    .ResetCollision(ResetCollision),
    .RetryCnt(RetryCnt),
    .StartTxDone(StartTxDone),
    .StartTxAbort(StartTxAbort),
    .MaxCollisionOccured(MaxCollisionOccured),
    .LateCollision(LateCollision),
    .DeferIndication(DeferIndication),
    .StatePreamble(StatePreamble),
    .StateData(StateData)
  );

  wire [15:0] RxByteCnt;
  wire RxByteCntEq0;
  wire RxByteCntGreat2;
  wire RxByteCntMaxFrame;
  wire RxCrcError;
  wire RxStateIdle;
  wire RxStatePreamble;
  wire RxStateSFD;
  wire [1:0] RxStateData;
  wire AddressMiss;

  eth_rxethmac
  rxethmac1
  (
    .MRxClk(mrx_clk_pad_i),
    .MRxDV(MRxDV_Lb),
    .MRxD(MRxD_Lb),
    .Transmitting(Transmitting),
    .HugEn(r_HugEn),
    .DlyCrcEn(r_DlyCrcEn),
    .MaxFL(r_MaxFL),
    .r_IFG(r_IFG),
    .Reset(wb_rst_i),
    .RxData(RxData),
    .RxValid(RxValid),
    .RxStartFrm(RxStartFrm),
    .RxEndFrm(RxEndFrm),
    .ByteCnt(RxByteCnt),
    .ByteCntEq0(RxByteCntEq0),
    .ByteCntGreat2(RxByteCntGreat2),
    .ByteCntMaxFrame(RxByteCntMaxFrame),
    .CrcError(RxCrcError),
    .StateIdle(RxStateIdle),
    .StatePreamble(RxStatePreamble),
    .StateSFD(RxStateSFD),
    .StateData(RxStateData),
    .MAC(r_MAC),
    .r_Pro(r_Pro),
    .r_Bro(r_Bro),
    .r_HASH0(r_HASH0),
    .r_HASH1(r_HASH1),
    .RxAbort(RxAbort),
    .AddressMiss(AddressMiss),
    .PassAll(r_PassAll),
    .ControlFrmAddressOK(ControlFrmAddressOK)
  );


  always @(posedge mtx_clk_pad_i or posedge wb_rst_i) begin
    if(wb_rst_i) begin
      CarrierSense_Tx1 <= 1'b0;
      CarrierSense_Tx2 <= 1'b0;
    end else begin
      CarrierSense_Tx1 <= mcrs_pad_i;
      CarrierSense_Tx2 <= CarrierSense_Tx1;
    end
  end

  assign TxCarrierSense = ~r_FullD & CarrierSense_Tx2;

  always @(posedge mtx_clk_pad_i or posedge wb_rst_i) begin
    if(wb_rst_i) begin
      Collision_Tx1 <= 1'b0;
      Collision_Tx2 <= 1'b0;
    end else begin
      Collision_Tx1 <= mcoll_pad_i;
      if(ResetCollision) Collision_Tx2 <= 1'b0; 
      else if(Collision_Tx1) Collision_Tx2 <= 1'b1; 
    end
  end

  assign Collision = ~r_FullD & Collision_Tx2;

  always @(posedge mrx_clk_pad_i) begin
    WillTransmit_q <= WillTransmit;
    WillTransmit_q2 <= WillTransmit_q;
  end

  assign Transmitting = ~r_FullD & WillTransmit_q2;

  always @(posedge mrx_clk_pad_i or posedge wb_rst_i) begin
    if(wb_rst_i) RxEnSync <= 1'b0; 
    else if(~mrxdv_pad_i) RxEnSync <= r_RxEn; 
  end


  always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if(wb_rst_i) WillSendControlFrame_sync1 <= 1'b0; 
    else WillSendControlFrame_sync1 <= WillSendControlFrame;
  end


  always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if(wb_rst_i) WillSendControlFrame_sync2 <= 1'b0; 
    else WillSendControlFrame_sync2 <= WillSendControlFrame_sync1;
  end


  always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if(wb_rst_i) WillSendControlFrame_sync3 <= 1'b0; 
    else WillSendControlFrame_sync3 <= WillSendControlFrame_sync2;
  end


  always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if(wb_rst_i) RstTxPauseRq <= 1'b0; 
    else RstTxPauseRq <= WillSendControlFrame_sync2 & ~WillSendControlFrame_sync3;
  end


  always @(posedge mtx_clk_pad_i or posedge wb_rst_i) begin
    if(wb_rst_i) begin
      TxPauseRq_sync1 <= 1'b0;
      TxPauseRq_sync2 <= 1'b0;
      TxPauseRq_sync3 <= 1'b0;
    end else begin
      TxPauseRq_sync1 <= r_TxPauseRq & r_TxFlow;
      TxPauseRq_sync2 <= TxPauseRq_sync1;
      TxPauseRq_sync3 <= TxPauseRq_sync2;
    end
  end


  always @(posedge mtx_clk_pad_i or posedge wb_rst_i) begin
    if(wb_rst_i) TPauseRq <= 1'b0; 
    else TPauseRq <= TxPauseRq_sync2 & ~TxPauseRq_sync3;
  end

  wire LatchedMRxErr;
  reg RxAbort_latch;
  reg RxAbort_sync1;
  reg RxAbort_wb;
  reg RxAbortRst_sync1;
  reg RxAbortRst;

  always @(posedge mrx_clk_pad_i or posedge wb_rst_i) begin
    if(wb_rst_i) RxAbort_latch <= 1'b0; 
    else if(RxAbort | ShortFrame & ~r_RecSmall | LatchedMRxErr & ~InvalidSymbol | ReceivedPauseFrm & ~r_PassAll) RxAbort_latch <= 1'b1; 
    else if(RxAbortRst) RxAbort_latch <= 1'b0; 
  end


  always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if(wb_rst_i) begin
      RxAbort_sync1 <= 1'b0;
      RxAbort_wb <= 1'b0;
      RxAbort_wb <= 1'b0;
    end else begin
      RxAbort_sync1 <= RxAbort_latch;
      RxAbort_wb <= RxAbort_sync1;
    end
  end


  always @(posedge mrx_clk_pad_i or posedge wb_rst_i) begin
    if(wb_rst_i) begin
      RxAbortRst_sync1 <= 1'b0;
      RxAbortRst <= 1'b0;
    end else begin
      RxAbortRst_sync1 <= RxAbort_wb;
      RxAbortRst <= RxAbortRst_sync1;
    end
  end


  eth_wishbone
  #(
    .TX_FIFO_DATA_WIDTH(TX_FIFO_DATA_WIDTH),
    .TX_FIFO_DEPTH(TX_FIFO_DEPTH),
    .TX_FIFO_CNT_WIDTH(TX_FIFO_CNT_WIDTH),
    .RX_FIFO_DATA_WIDTH(RX_FIFO_DATA_WIDTH),
    .RX_FIFO_DEPTH(RX_FIFO_DEPTH),
    .RX_FIFO_CNT_WIDTH(RX_FIFO_CNT_WIDTH)
  )
  wishbone
  (
    .WB_CLK_I(wb_clk_i),
    .WB_DAT_I(wb_dat_i),
    .WB_DAT_O(BD_WB_DAT_O),
    .WB_ADR_I(wb_adr_i[9:2]),
    .WB_WE_I(wb_we_i),
    .BDCs(BDCs),
    .WB_ACK_O(BDAck),
    .Reset(wb_rst_i),
    .m_wb_adr_o(m_wb_adr_tmp),
    .m_wb_sel_o(m_wb_sel_o),
    .m_wb_we_o(m_wb_we_o),
    .m_wb_dat_i(m_wb_dat_i),
    .m_wb_dat_o(m_wb_dat_o),
    .m_wb_cyc_o(m_wb_cyc_o),
    .m_wb_stb_o(m_wb_stb_o),
    .m_wb_ack_i(m_wb_ack_i),
    .m_wb_err_i(m_wb_err_i),
    .MTxClk(mtx_clk_pad_i),
    .TxStartFrm(TxStartFrm),
    .TxEndFrm(TxEndFrm),
    .TxUsedData(TxUsedData),
    .TxData(TxData),
    .TxRetry(TxRetry),
    .TxAbort(TxAbort),
    .TxUnderRun(TxUnderRun),
    .TxDone(TxDone),
    .PerPacketCrcEn(PerPacketCrcEn),
    .PerPacketPad(PerPacketPad),
    .r_TxEn(r_TxEn),
    .r_RxEn(r_RxEn),
    .r_TxBDNum(r_TxBDNum),
    .r_RxFlow(r_RxFlow),
    .r_PassAll(r_PassAll),
    .MRxClk(mrx_clk_pad_i),
    .RxData(RxData),
    .RxValid(RxValid),
    .RxStartFrm(RxStartFrm),
    .RxEndFrm(RxEndFrm),
    .Busy_IRQ(Busy_IRQ),
    .RxE_IRQ(RxE_IRQ),
    .RxB_IRQ(RxB_IRQ),
    .TxE_IRQ(TxE_IRQ),
    .TxB_IRQ(TxB_IRQ),
    .RxAbort(RxAbort_wb),
    .RxStatusWriteLatched_sync2(RxStatusWriteLatched_sync2),
    .InvalidSymbol(InvalidSymbol),
    .LatchedCrcError(LatchedCrcError),
    .RxLength(RxByteCnt),
    .RxLateCollision(RxLateCollision),
    .ShortFrame(ShortFrame),
    .DribbleNibble(DribbleNibble),
    .ReceivedPacketTooBig(ReceivedPacketTooBig),
    .LoadRxStatus(LoadRxStatus),
    .RetryCntLatched(RetryCntLatched),
    .RetryLimit(RetryLimit),
    .LateCollLatched(LateCollLatched),
    .DeferLatched(DeferLatched),
    .RstDeferLatched(RstDeferLatched),
    .CarrierSenseLost(CarrierSenseLost),
    .ReceivedPacketGood(ReceivedPacketGood),
    .AddressMiss(AddressMiss),
    .ReceivedPauseFrm(ReceivedPauseFrm)
  );

  assign m_wb_adr_o = { m_wb_adr_tmp, 2'h0 };

  eth_macstatus
  macstatus1
  (
    .MRxClk(mrx_clk_pad_i),
    .Reset(wb_rst_i),
    .ReceiveEnd(ReceiveEnd),
    .ReceivedPacketGood(ReceivedPacketGood),
    .ReceivedLengthOK(ReceivedLengthOK),
    .RxCrcError(RxCrcError),
    .MRxErr(MRxErr_Lb),
    .MRxDV(MRxDV_Lb),
    .RxStateSFD(RxStateSFD),
    .RxStateData(RxStateData),
    .RxStatePreamble(RxStatePreamble),
    .RxStateIdle(RxStateIdle),
    .Transmitting(Transmitting),
    .RxByteCnt(RxByteCnt),
    .RxByteCntEq0(RxByteCntEq0),
    .RxByteCntGreat2(RxByteCntGreat2),
    .RxByteCntMaxFrame(RxByteCntMaxFrame),
    .InvalidSymbol(InvalidSymbol),
    .MRxD(MRxD_Lb),
    .LatchedCrcError(LatchedCrcError),
    .Collision(mcoll_pad_i),
    .CollValid(r_CollValid),
    .RxLateCollision(RxLateCollision),
    .r_RecSmall(r_RecSmall),
    .r_MinFL(r_MinFL),
    .r_MaxFL(r_MaxFL),
    .ShortFrame(ShortFrame),
    .DribbleNibble(DribbleNibble),
    .ReceivedPacketTooBig(ReceivedPacketTooBig),
    .r_HugEn(r_HugEn),
    .LoadRxStatus(LoadRxStatus),
    .RetryCnt(RetryCnt),
    .StartTxDone(StartTxDone),
    .StartTxAbort(StartTxAbort),
    .RetryCntLatched(RetryCntLatched),
    .MTxClk(mtx_clk_pad_i),
    .MaxCollisionOccured(MaxCollisionOccured),
    .RetryLimit(RetryLimit),
    .LateCollision(LateCollision),
    .LateCollLatched(LateCollLatched),
    .DeferIndication(DeferIndication),
    .DeferLatched(DeferLatched),
    .RstDeferLatched(RstDeferLatched),
    .TxStartFrm(TxStartFrmOut),
    .StatePreamble(StatePreamble),
    .StateData(StateData),
    .CarrierSense(CarrierSense_Tx2),
    .CarrierSenseLost(CarrierSenseLost),
    .TxUsedData(TxUsedDataIn),
    .LatchedMRxErr(LatchedMRxErr),
    .Loopback(r_LoopBck),
    .r_FullD(r_FullD)
  );


endmodule

