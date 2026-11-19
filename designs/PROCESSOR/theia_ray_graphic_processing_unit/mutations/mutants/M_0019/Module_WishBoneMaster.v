

module WishBoneMasterUnit
(
  input wire CLK_I,
  input wire RST_I,
  input wire ACK_I,
  input wire GNT_I,
  input wire [32-1:0] DAT_I,
  output wire [32-1:0] DAT_O,
  output wire [32-1:0] ADR_O,
  output wire WE_O,
  output wire STB_O,
  output wire CYC_O,
  output wire [1:0] TGC_O,
  input wire iEnable,
  input wire iBusCyc_Type,
  input wire [32-1:0] iAddress,
  input wire iAddress_Set,
  output wire oDataReady,
  input wire [32-1:0] iData,
  output wire [32-1:0] oData
);

  wire wReadOperation;
  wire wEnable;
  assign wEnable = iEnable & GNT_I;
  assign CYC_O = iEnable;
  assign wReadOperation = (iBusCyc_Type == 0)? 1 : 0;
  assign WE_O = ((iBusCyc_Type == 1) && wEnable)? 1 : 0;
  wire wEnable_Delayed;

  FFD_POSEDGE_SYNCRONOUS_RESET
  #(
    1
  )
  FFD88
  (
    .Clock(CLK_I),
    .Reset(RST_I),
    .Enable(1'b1),
    .D(wEnable),
    .Q(wEnable_Delayed)
  );

  assign STB_O = wEnable_Delayed & ~ACK_I & wEnable;
  assign DAT_O = (wReadOperation | ~wEnable)? 32'bz : iData;
  wire [32-1:0] wReadADR_O;wire [32-1:0] wWriteADR_O;
  assign ADR_O = (wReadOperation)? wReadADR_O : wWriteADR_O;

  UPCOUNTER_POSEDGE
  #(
    32
  )
  WBM_O_READ_ADDRESS
  (
    .Clock(CLK_I),
    .Reset(iAddress_Set),
    .Enable(ACK_I & GNT_I | iAddress_Set),
    .Initial(iAddress),
    .Q(wReadADR_O)
  );

  wire wDelayWE;

  FFD_POSEDGE_SYNCRONOUS_RESET
  #(
    1
  )
  FFD3
  (
    .Clock(CLK_I),
    .Reset(RST_I),
    .Enable(1'b1),
    .D(WE_O),
    .Q(wDelayWE)
  );


  UPCOUNTER_POSEDGE
  #(
    32
  )
  WBM_O_WRITE_ADDRESS
  (
    .Clock(CLK_I),
    .Reset(iAddress_Set),
    .Enable(wDelayWE | ACK_I | iAddress_Set),
    .Initial(iAddress),
    .Q(wWriteADR_O)
  );


  FFD_POSEDGE_SYNCRONOUS_RESET
  #(
    32
  )
  FFD1
  (
    .Clock(ACK_I),
    .Reset(~wEnable),
    .Enable(wReadOperation),
    .D(DAT_I),
    .Q(oData)
  );

  wire wDelayDataReady;

  FFD_POSEDGE_SYNCRONOUS_RESET
  #(
    1
  )
  FFD2
  (
    .Clock(CLK_I),
    .Reset(~wEnable),
    .Enable(wReadOperation),
    .D(ACK_I),
    .Q(wDelayDataReady)
  );

  assign oDataReady = wDelayDataReady & wEnable;

endmodule

