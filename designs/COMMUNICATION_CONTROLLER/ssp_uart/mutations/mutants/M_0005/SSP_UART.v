

module SSP_UART #
(
  parameter pPS_Default = 4'h1,
  parameter pDiv_Default = 8'hEF,
  parameter pRTOChrDlyCnt = 3,
  parameter pTF_Depth = 2,
  parameter pRF_Depth = 2,
  parameter pTF_Init = "Src/UART_TF.coe",
  parameter pRF_Init = "Src/UART_RF.coe"
)
(
  input Rst,
  input Clk,
  input SSP_SSEL,
  input SSP_SCK,
  input [2:0] SSP_RA,
  input SSP_WnR,
  input SSP_En,
  input SSP_EOC,
  input [11:0] SSP_DI,
  output reg [11:0] SSP_DO,
  output TxD_232,
  input RxD_232,
  output reg xRTS,
  input xCTS,
  output TxD_485,
  input RxD_485,
  output xDE,
  output reg IRQ,
  output TxIdle,
  output RxIdle
);

  localparam pVersion = 8'h23;
  localparam pUCR = 0;
  localparam pUSR = 1;
  localparam pTDR = 2;
  localparam pRDR = 3;
  localparam pSPR = 4;
  localparam pTFC = 11;
  localparam pRFC = 10;
  localparam pHLD = 9;
  localparam pRev = 1;
  localparam pLen = 2;
  localparam pFThr = 3;
  localparam pTHR = 4;
  localparam pRHR = 5;
  localparam pTFCnt = 6;
  localparam pRFCnt = 7;
  localparam pWidth = 8;
  localparam pxFThr = 8;
  wire SCK;
  wire [2:0] RSel;
  wire Sel_TDR;
  wire Sel_RDR;
  wire Sel_UCR;
  wire Sel_SPR;
  wire [7:0] TD;wire [7:0] THR;
  wire TFC;
  reg HLD;
  reg TxHold;
  wire RE_THR;
  wire WE_THR;wire ClrTHR;
  wire TF_FF;wire TF_EF;wire TF_HF;
  wire [8:0] RD;wire [8:0] RHR;
  wire RFC;
  wire WE_RHR;
  wire RE_RHR;wire ClrRHR;
  wire RF_FF;wire RF_EF;wire RF_HF;
  wire [pTF_Depth+4:0] TFCnt;
  wire [pRF_Depth+4:0] RFCnt;
  reg [7:0] TDR;
  reg [11:0] RDR;
  reg [11:0] UCR;reg [11:0] USR;reg [11:0] SPR;
  reg [7:0] RTFThr;
  wire [1:0] MD;
  wire RTSo;wire IE;
  wire [3:0] FMT;
  reg Len;reg NumStop;reg ParEn;
  reg [1:0] Par;
  reg [3:0] PS;
  reg [7:0] Div;
  reg [3:0] CCntVal;
  wire [3:0] RTOVal;
  wire RTSi;wire CTSi;
  reg [1:0] RS;reg [1:0] TS;
  wire iRTO;
  wire iRHF;
  wire iTHE;
  wire iTFE;
  reg En;
  wire Clr_Int;
  wire WE_SPR;
  wire WE_RTFThr;
  reg [11:0] SPR_DO;
  wire TxD;
  reg RxD;
  wire TRDY;
  wire RRDY;
  wire RTO;
  wire RERR;
  wire RcvTimeout;
  wire [7:0] Version;assign Version = pVersion;
  wire [3:0] TFLen;assign TFLen = pTF_Depth;
  wire [3:0] RFLen;assign RFLen = pRF_Depth;
  wire [3:0] TFThr;assign TFThr = pxFThr;
  wire [3:0] RFThr;assign RFThr = pxFThr;
  assign SCK = SSP_SCK;
  assign SSP_WE = SSP_SSEL & SSP_WnR & SSP_EOC;
  assign SSP_RE = SSP_SSEL & ~SSP_WnR & SSP_EOC;
  assign RSel = SSP_RA;
  assign Sel_TDR = RSel == pTDR;
  assign Sel_RDR = RSel == pRDR;
  assign Sel_USR = RSel == pUSR;
  assign Sel_UCR = RSel == pUCR;
  assign Sel_SPR = RSel == pSPR;

  always @(*) begin
    case(SPR[11:9])
      pRev: SPR_DO <= { 4'b0, Version[7:0] };
      pLen: SPR_DO <= { 4'b0, pRF_Depth[3:0], pTF_Depth[3:0] };
      pFThr: SPR_DO <= { 4'b0, RTFThr };
      pTHR: SPR_DO <= { 4'b0, THR };
      pRHR: SPR_DO <= { 3'b0, RHR };
      pTFCnt: SPR_DO <= { 1'b0, TFCnt[pTF_Depth+4:0] };
      pRFCnt: SPR_DO <= { 1'b0, RFCnt[pRF_Depth+4:0] };
      default: SPR_DO <= SPR;
    endcase
  end


  always @(*) begin
    case(RSel)
      pUCR: SSP_DO <= (SSP_SSEL)? UCR : 0;
      pUSR: SSP_DO <= (SSP_SSEL)? USR : 0;
      pTDR: SSP_DO <= (SSP_SSEL)? TDR : 0;
      pRDR: SSP_DO <= (SSP_SSEL)? RDR : 0;
      pSPR: SSP_DO <= (SSP_SSEL)? SPR_DO : 0;
      default: SSP_DO <= (SSP_SSEL)? { 1'b0, RFCnt[pRF_Depth+4:0] } : 0;
    endcase
  end

  assign Rst_IRQ = Rst | Clr_Int;

  always @(posedge Clk) begin
    if(Rst_IRQ) IRQ <= 0; 
    else if(~IRQ) IRQ <= #1 IE & (iTFE | iTHE | iRHF | iRTO); 
  end


  always @(negedge SCK or posedge Rst) begin
    if(Rst) UCR <= #1 0; 
    else if(Sel_UCR) UCR <= #1 (SSP_WE)? SSP_DI : USR; 
  end

  assign MD = UCR[11:10];
  assign RTSo = UCR[9];
  assign IE = UCR[8];
  assign FMT = UCR[7:4];

  always @(FMT) case(FMT)
    4'b0000: { Len, NumStop, ParEn, Par } <= { 1'b0, 1'b0, 1'b0, 2'b00 };
    4'b0001: { Len, NumStop, ParEn, Par } <= { 1'b0, 1'b0, 1'b0, 2'b00 };
    4'b0010: { Len, NumStop, ParEn, Par } <= { 1'b0, 1'b0, 1'b1, 2'b00 };
    4'b0011: { Len, NumStop, ParEn, Par } <= { 1'b0, 1'b0, 1'b1, 2'b01 };
    4'b0100: { Len, NumStop, ParEn, Par } <= { 1'b0, 1'b0, 1'b1, 2'b10 };
    4'b0101: { Len, NumStop, ParEn, Par } <= { 1'b0, 1'b0, 1'b1, 2'b11 };
    4'b0110: { Len, NumStop, ParEn, Par } <= { 1'b0, 1'b0, 1'b0, 2'b00 };
    4'b0111: { Len, NumStop, ParEn, Par } <= { 1'b0, 1'b1, 1'b0, 2'b00 };
    4'b1000: { Len, NumStop, ParEn, Par } <= { 1'b0, 1'b1, 1'b1, 2'b00 };
    4'b1001: { Len, NumStop, ParEn, Par } <= { 1'b0, 1'b1, 1'b1, 2'b01 };
    4'b1010: { Len, NumStop, ParEn, Par } <= { 1'b0, 1'b1, 1'b1, 2'b10 };
    4'b1011: { Len, NumStop, ParEn, Par } <= { 1'b0, 1'b1, 1'b1, 2'b11 };
    4'b1100: { Len, NumStop, ParEn, Par } <= { 1'b1, 1'b0, 1'b1, 2'b00 };
    4'b1101: { Len, NumStop, ParEn, Par } <= { 1'b1, 1'b0, 1'b1, 2'b01 };
    4'b1110: { Len, NumStop, ParEn, Par } <= { 1'b1, 1'b1, 1'b1, 2'b00 };
    4'b1111: { Len, NumStop, ParEn, Par } <= { 1'b1, 1'b1, 1'b1, 2'b01 };
  endcase


  always @(FMT) case(FMT)
    4'b0000: CCntVal <= 4'h9;
    4'b0001: CCntVal <= 4'h9;
    4'b0010: CCntVal <= 4'hA;
    4'b0011: CCntVal <= 4'hA;
    4'b0100: CCntVal <= 4'hA;
    4'b0101: CCntVal <= 4'hA;
    4'b0110: CCntVal <= 4'h9;
    4'b0111: CCntVal <= 4'hA;
    4'b1000: CCntVal <= 4'hB;
    4'b1001: CCntVal <= 4'hB;
    4'b1010: CCntVal <= 4'hB;
    4'b1011: CCntVal <= 4'hB;
    4'b1100: CCntVal <= 4'h9;
    4'b1101: CCntVal <= 4'h9;
    4'b1110: CCntVal <= 4'h9;
    4'b1111: CCntVal <= 4'h9;
  endcase

  assign RTOVal = pRTOChrDlyCnt - 1;

  always @(*) begin
    case({ RF_FF, RF_HF, RF_EF })
      3'b000: RS <= 2'b01;
      3'b001: RS <= 2'b00;
      3'b010: RS <= 2'b10;
      3'b011: RS <= 2'b00;
      3'b100: RS <= 2'b00;
      3'b101: RS <= 2'b00;
      3'b110: RS <= 2'b11;
      3'b111: RS <= 2'b00;
    endcase
  end


  always @(*) begin
    case({ TF_FF, TF_HF, TxIdle })
      3'b000: TS <= 2'b01;
      3'b001: TS <= 2'b00;
      3'b010: TS <= 2'b10;
      3'b011: TS <= 2'b00;
      3'b100: TS <= 2'b00;
      3'b101: TS <= 2'b00;
      3'b110: TS <= 2'b11;
      3'b111: TS <= 2'b00;
    endcase
  end


  always @(posedge SCK or posedge Rst) begin
    if(Rst) USR <= #1 0; 
    else USR <= #1 { MD, RTSi, CTSi, RS, TS, iRTO, iRHF, iTHE, iTFE };
  end


  always @(posedge SCK or posedge Rst) begin
    if(Rst) En <= #1 0; 
    else En <= #1 SSP_En;
  end


  re1ce
  RED1
  (
    .den(Sel_USR & (SSP_En & ~En) & |USR[3:0]),
    .din(SCK),
    .clk(Clk),
    .rst(Rst),
    .trg(),
    .pls(Clr_Int)
  );


  always @(posedge SCK or posedge Rst) begin
    if(Rst) { PS, Div } <= #1 { pPS_Default, pDiv_Default }; 
    else if(Sel_USR) { PS, Div } <= #1 (SSP_WE)? SSP_DI : { PS, Div }; 
  end

  assign WE_TDR = SSP_WE & Sel_TDR & TRDY;

  always @(posedge SCK or posedge Rst) begin
    if(Rst) TDR <= #1 8'b0; 
    else if(WE_TDR) TDR <= #1 SSP_DI[7:0]; 
  end

  assign TD = TDR;
  assign TFC = SSP_DI[pTFC] & WE_TDR;

  re1ce
  RED2
  (
    .den(TFC),
    .din(SCK),
    .clk(Clk),
    .rst(Rst),
    .trg(),
    .pls(ClrTHR)
  );

  assign RFC = SSP_DI[pRFC] & WE_TDR;

  re1ce
  RED3
  (
    .den(RFC),
    .din(SCK),
    .clk(Clk),
    .rst(Rst),
    .trg(),
    .pls(ClrRHR)
  );


  always @(posedge SCK or posedge Rst) begin
    if(Rst) HLD <= #1 0; 
    else if(WE_TDR) HLD <= #1 SSP_DI[pHLD]; 
  end


  re1ce
  RED4
  (
    .den(WE_TDR),
    .din(SCK),
    .clk(Clk),
    .rst(Rst),
    .trg(),
    .pls(WE_THR)
  );


  always @(posedge Clk) begin
    if(Rst) TxHold <= #1 0; 
    else if(WE_THR) TxHold <= #1 HLD; 
  end

  assign TRDY = ~TF_FF;
  assign RRDY = ~RF_EF;
  assign RTO = RcvTimeout;
  assign RERR = RHR[8];

  always @(posedge SCK or posedge Rst) begin
    if(Rst) RDR <= #1 0; 
    else if(~SSP_En) RDR <= #1 { TRDY, RRDY, RTO, RERR, RHR[7:0] }; 
  end

  assign RE_RDR = Sel_RDR & ~SSP_WnR & (SSP_En & ~En) & RDR[10];

  re1ce
  RED5
  (
    .den(RE_RDR),
    .din(SCK),
    .clk(Clk),
    .rst(Rst),
    .trg(),
    .pls(RE_RHR)
  );

  assign WE_SPR = SSP_WE & Sel_SPR;

  always @(posedge SCK or posedge Rst) begin
    if(Rst) SPR <= #1 0; 
    else if(WE_SPR) SPR <= #1 SSP_DI; 
  end

  assign WE_RTFThr = SSP_WE & Sel_SPR & (SSP_DI[11:9] == pFThr) & SSP_DI[8];

  always @(posedge SCK or posedge Rst) begin
    if(Rst) RTFThr <= #1 { RFThr, TFThr }; 
    else if(WE_RTFThr) RTFThr <= #1 SSP_DI; 
  end


  DPSFnmCE
  #(
    .addr(pTF_Depth + 4),
    .width(pWidth),
    .init(pTF_Init)
  )
  TF1
  (
    .Rst(Rst | ClrTHR),
    .Clk(Clk),
    .WE(WE_THR),
    .RE(RE_THR),
    .DI(TD),
    .DO(THR),
    .FF(TF_FF),
    .HF(TF_HF),
    .EF(TF_EF),
    .Cnt(TFCnt)
  );


  DPSFnmCE
  #(
    .addr(pRF_Depth + 4),
    .width(pWidth + 1),
    .init(pRF_Init)
  )
  RF1
  (
    .Rst(Rst | ClrRHR),
    .Clk(Clk),
    .WE(WE_RHR),
    .RE(RE_RHR),
    .DI(RD),
    .DO(RHR),
    .FF(RF_FF),
    .HF(RF_HF),
    .EF(RF_EF),
    .Cnt(RFCnt)
  );

  assign RS232 = ~MD[1];
  assign RS485 = MD[1];
  assign TxD_232 = (RS232)? TxD : 1;
  assign TxD_485 = (RS485)? TxD : 1;
  assign xDE = (RS485)? ~TxIdle : 0;

  always @(posedge Clk or posedge Rst) begin
    if(Rst) RxD <= #1 1; 
    else case(MD)
      2'b00: RxD <= #1 RxD_232;
      2'b10: RxD <= #1 RxD_232;
      2'b01: RxD <= #1 (TxIdle)? RxD_485 : 1;
      2'b11: RxD <= #1 RxD_485;
    endcase
  end


  always @(*) begin
    case(MD)
      2'b00: xRTS <= RTSo;
      2'b01: xRTS <= ~RF_HF;
      2'b10: xRTS <= 0;
      2'b11: xRTS <= 0;
    endcase
  end

  assign RTSi = (RS232)? xRTS : xDE;
  assign CTSi = (MD == 1)? xCTS : 1;

  UART_BRG
  BRG
  (
    .Rst(Rst),
    .Clk(Clk),
    .PS(PS),
    .Div(Div),
    .CE_16x(CE_16x)
  );


  UART_TXSM
  XMT
  (
    .Rst(Rst),
    .Clk(Clk),
    .CE_16x(CE_16x),
    .Len(Len),
    .NumStop(NumStop),
    .ParEn(ParEn),
    .Par(Par),
    .TF_RE(RE_THR),
    .THR(THR),
    .TF_EF(TF_EF | TxHold),
    .TxD(TxD),
    .CTSi(CTSi),
    .TxIdle(TxIdle),
    .TxStart(),
    .TxShift(),
    .TxStop()
  );


  UART_RXSM
  RCV
  (
    .Rst(Rst),
    .Clk(Clk),
    .CE_16x(CE_16x),
    .Len(Len),
    .NumStop(NumStop),
    .ParEn(ParEn),
    .Par(Par),
    .RxD(RxD),
    .RD(RD),
    .WE_RHR(WE_RHR),
    .RxWait(),
    .RxIdle(RxIdle),
    .RxStart(),
    .RxShift(),
    .RxParity(),
    .RxStop(),
    .RxError()
  );


  UART_RTO
  TMR
  (
    .Rst(Rst),
    .Clk(Clk),
    .CE_16x(CE_16x),
    .WE_RHR(WE_RHR),
    .RE_RHR(RE_RHR),
    .CCntVal(CCntVal),
    .RTOVal(RTOVal),
    .RcvTimeout(RcvTimeout)
  );


  UART_INT
  INT
  (
    .Rst(Rst),
    .Clk(Clk),
    .TF_HF(TF_HF),
    .TF_EF(TF_EF),
    .RF_HF(RF_HF),
    .RF_EF(RF_EF),
    .RTO(RTO),
    .Clr_Int(Clr_Int),
    .USR(USR[3:0]),
    .iTFE(iTFE),
    .iTHE(iTHE),
    .iRHF(iRHF),
    .iRTO(iRTO)
  );


endmodule

