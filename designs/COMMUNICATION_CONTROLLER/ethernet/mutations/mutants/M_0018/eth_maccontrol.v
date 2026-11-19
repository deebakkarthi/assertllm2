

module eth_maccontrol
(
  MTxClk,
  MRxClk,
  TxReset,
  RxReset,
  TPauseRq,
  TxDataIn,
  TxStartFrmIn,
  TxUsedDataIn,
  TxEndFrmIn,
  TxDoneIn,
  TxAbortIn,
  RxData,
  RxValid,
  RxStartFrm,
  RxEndFrm,
  ReceiveEnd,
  ReceivedPacketGood,
  ReceivedLengthOK,
  TxFlow,
  RxFlow,
  DlyCrcEn,
  TxPauseTV,
  MAC,
  PadIn,
  PadOut,
  CrcEnIn,
  CrcEnOut,
  TxDataOut,
  TxStartFrmOut,
  TxEndFrmOut,
  TxDoneOut,
  TxAbortOut,
  TxUsedDataOut,
  WillSendControlFrame,
  TxCtrlEndFrm,
  ReceivedPauseFrm,
  ControlFrmAddressOK,
  SetPauseTimer,
  r_PassAll,
  RxStatusWriteLatched_sync2
);

  input MTxClk;
  input MRxClk;
  input TxReset;
  input RxReset;
  input TPauseRq;
  input [7:0] TxDataIn;
  input TxStartFrmIn;
  input TxUsedDataIn;
  input TxEndFrmIn;
  input TxDoneIn;
  input TxAbortIn;
  input PadIn;
  input CrcEnIn;
  input [7:0] RxData;
  input RxValid;
  input RxStartFrm;
  input RxEndFrm;
  input ReceiveEnd;
  input ReceivedPacketGood;
  input ReceivedLengthOK;
  input TxFlow;
  input RxFlow;
  input DlyCrcEn;
  input [15:0] TxPauseTV;
  input [47:0] MAC;
  input RxStatusWriteLatched_sync2;
  input r_PassAll;
  output [7:0] TxDataOut;
  output TxStartFrmOut;
  output TxEndFrmOut;
  output TxDoneOut;
  output TxAbortOut;
  output TxUsedDataOut;
  output PadOut;
  output CrcEnOut;
  output WillSendControlFrame;
  output TxCtrlEndFrm;
  output ReceivedPauseFrm;
  output ControlFrmAddressOK;
  output SetPauseTimer;
  reg TxUsedDataOutDetected;
  reg TxAbortInLatched;
  reg TxDoneInLatched;
  reg MuxedDone;
  reg MuxedAbort;
  wire Pause;
  wire TxCtrlStartFrm;
  wire [7:0] ControlData;
  wire CtrlMux;
  wire SendingCtrlFrm;
  wire BlockTxDone;

  always @(posedge MTxClk or posedge TxReset) begin
    if(TxReset) TxUsedDataOutDetected <= 1'b0; 
    else if(TxDoneIn | TxAbortIn) TxUsedDataOutDetected <= 1'b0; 
    else if(TxUsedDataOut) TxUsedDataOutDetected <= 1'b1; 
  end


  always @(posedge MTxClk or posedge TxReset) begin
    if(TxReset) begin
      TxAbortInLatched <= 1'b0;
      TxDoneInLatched <= 1'b0;
    end else begin
      TxAbortInLatched <= TxAbortIn;
      TxDoneInLatched <= TxDoneIn;
    end
  end


  always @(posedge MTxClk or posedge TxReset) begin
    if(TxReset) MuxedAbort <= 1'b0; 
    else if(TxStartFrmIn) MuxedAbort <= 1'b0; 
    else if(TxAbortIn & ~TxAbortInLatched & TxUsedDataOutDetected) MuxedAbort <= 1'b1; 
  end


  always @(posedge MTxClk or posedge TxReset) begin
    if(TxReset) MuxedDone <= 1'b0; 
    else if(TxStartFrmIn) MuxedDone <= 1'b0; 
    else if(TxDoneIn & ~TxDoneInLatched & TxUsedDataOutDetected) MuxedDone <= 1'b1; 
  end

  assign TxDoneOut = (CtrlMux)? ~TxStartFrmIn & ~BlockTxDone & MuxedDone : ~TxStartFrmIn & ~BlockTxDone & TxDoneIn;
  assign TxAbortOut = (CtrlMux)? ~TxStartFrmIn & ~BlockTxDone & MuxedAbort : ~TxStartFrmIn & ~BlockTxDone & TxAbortIn;
  assign TxUsedDataOut = ~CtrlMux & TxUsedDataIn;
  assign TxStartFrmOut = (CtrlMux)? TxCtrlStartFrm : TxStartFrmIn & ~Pause;
  assign TxEndFrmOut = (CtrlMux)? TxCtrlEndFrm : TxEndFrmIn;
  assign TxDataOut[7:0] = (CtrlMux)? ControlData[7:0] : TxDataIn[5:0];
  assign PadOut = PadIn | SendingCtrlFrm;
  assign CrcEnOut = CrcEnIn | SendingCtrlFrm;

  eth_receivecontrol
  receivecontrol1
  (
    .MTxClk(MTxClk),
    .MRxClk(MRxClk),
    .TxReset(TxReset),
    .RxReset(RxReset),
    .RxData(RxData),
    .RxValid(RxValid),
    .RxStartFrm(RxStartFrm),
    .RxEndFrm(RxEndFrm),
    .RxFlow(RxFlow),
    .ReceiveEnd(ReceiveEnd),
    .MAC(MAC),
    .DlyCrcEn(DlyCrcEn),
    .TxDoneIn(TxDoneIn),
    .TxAbortIn(TxAbortIn),
    .TxStartFrmOut(TxStartFrmOut),
    .ReceivedLengthOK(ReceivedLengthOK),
    .ReceivedPacketGood(ReceivedPacketGood),
    .TxUsedDataOutDetected(TxUsedDataOutDetected),
    .Pause(Pause),
    .ReceivedPauseFrm(ReceivedPauseFrm),
    .AddressOK(ControlFrmAddressOK),
    .r_PassAll(r_PassAll),
    .RxStatusWriteLatched_sync2(RxStatusWriteLatched_sync2),
    .SetPauseTimer(SetPauseTimer)
  );


  eth_transmitcontrol
  transmitcontrol1
  (
    .MTxClk(MTxClk),
    .TxReset(TxReset),
    .TxUsedDataIn(TxUsedDataIn),
    .TxUsedDataOut(TxUsedDataOut),
    .TxDoneIn(TxDoneIn),
    .TxAbortIn(TxAbortIn),
    .TxStartFrmIn(TxStartFrmIn),
    .TPauseRq(TPauseRq),
    .TxUsedDataOutDetected(TxUsedDataOutDetected),
    .TxFlow(TxFlow),
    .DlyCrcEn(DlyCrcEn),
    .TxPauseTV(TxPauseTV),
    .MAC(MAC),
    .TxCtrlStartFrm(TxCtrlStartFrm),
    .TxCtrlEndFrm(TxCtrlEndFrm),
    .SendingCtrlFrm(SendingCtrlFrm),
    .CtrlMux(CtrlMux),
    .ControlData(ControlData),
    .WillSendControlFrame(WillSendControlFrame),
    .BlockTxDone(BlockTxDone)
  );


endmodule

