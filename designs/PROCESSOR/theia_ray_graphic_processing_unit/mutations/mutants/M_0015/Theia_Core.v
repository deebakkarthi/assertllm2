

module THEIACORE
(
  input wire CLK_I,
  input wire RST_I,
  input wire MST_I,
  input wire [32-1:0] DAT_I,
  output wire [32-1:0] DAT_O,
  input wire ACK_I,
  output wire ACK_O,
  output wire [32-1:0] ADR_O,
  input wire [32-1:0] ADR_I,
  output wire WE_O,
  input wire WE_I,
  output wire STB_O,
  input wire STB_I,
  output wire CYC_O,
  input wire CYC_I,
  output wire [1:0] TGC_O,
  input wire [1:0] TGA_I,
  output wire [1:0] TGA_O,
  input wire [1:0] TGC_I,
  input wire GNT_I,
  input wire RENDREN_I,
  output wire HDL_O,
  input wire HDLACK_I,
  input wire STDONE_I,
  input wire HDA_I,
  output wire RCOMMIT_O,
  output wire [32-1:0] OMEM_DAT_O,
  output wire [32-1:0] OMEM_ADR_O,
  output wire OMEM_WE_O,
  input wire TMEM_ACK_I,
  input wire [32-1:0] TMEM_DAT_I,
  output wire [32-1:0] TMEM_ADR_O,
  output wire TMEM_WE_O,
  output wire TMEM_STB_O,
  output wire TMEM_CYC_O,
  input wire TMEM_GNT_I,
  input wire [15:0] CREG_I,
  output wire DONE_O
);

  wire Clock;wire Reset;
  assign Clock = CLK_I;
  assign Reset = RST_I;
  wire wIO_Busy;
  wire [96-1:0] wEXE_2__MEM_WriteData;
  wire [96-1:0] wUCODE_RAMBus;
  wire [16-1:0] wEXE_2__MEM_wDataWriteAddress;
  wire w2IO__AddrIsImm;
  wire [16-1:0] wUCODE_RAMAddress;
  wire [16-1:0] w2IO__Adr_O_Pointer;
  wire [16-1:0] wGEO2_IO__Adr_O_Pointer;
  wire wEXE_2__DataWriteEnable;
  wire wUCODE_RAMWriteEnable;
  wire wCU2__MicrocodeExecutionDone;
  wire [16-1:0] InitialCodeAddress;
  wire [16-1:0] wInstructionPointer1;wire [16-1:0] wInstructionPointer2;
  wire [64-1:0] wEncodedInstruction1;wire [64-1:0] wEncodedInstruction2;wire [64-1:0] wIO2_MEM__ExternalInstruction;
  wire wCU2__ExecuteMicroCode;
  wire [16-1:0] wIO2_MEM__InstructionWriteAddr;
  wire [95:0] wMEM_2__EXE_DataRead0;wire [95:0] wMEM_2__EXE_DataRead1;wire [95:0] wMEM_2__IO_DataRead0;wire [95:0] wMEM_2__IO_DataRead1;
  wire [16-1:0] wEXE_2__MEM_DataReadAddress0;wire [16-1:0] wEXE_2__MEM_DataReadAddress1;
  wire [16-1:0] wUCODE_RAMReadAddress0;wire [16-1:0] wUCODE_RAMReadAddress1;
  wire [32-1:0] w2IO__AddressOffset;
  wire [16-1:0] w2IO__DataWriteAddress;
  wire w2IO__Store;
  wire w2IO__EnableWBMaster;
  wire [16-1:0] wIO2_MEM__DataWriteAddress;
  wire [16-1:0] wIO_2_MEM__DataReadAddress0;
  wire [96-1:0] wIO2_MEM__Bus;
  wire [32-1:0] wIO2_MEM__Data;
  wire [32-1:0] wIO2_WBM__Address;
  wire wIO2_MEM__DataWriteEnable;
  wire wIO2__Done;
  wire wCU2_GEO__GeometryFetchEnable;
  wire wIFU2__MicroCodeReturnValue;
  wire wCU2_BCU__ACK;
  wire wGEO2_CU__RequestAABBIU;
  wire wGEO2_CU__RequestBIU;
  wire wGEO2_CU__RequestTCC;
  wire wGEO2_CU__GeometryUnitDone;
  wire wGEO2_CU__Sync;
  wire wEXE2__uCodeDone;
  wire wEXE2_IFU__EXEBusy;
  wire [16-1:0] wEXE2_IDU_DataFordward_LastDestination;
  wire wALU2_EXE__BranchTaken;
  wire wALU2_IFU_BranchNotTaken;
  wire w2IO__SetAddress;
  wire wIDU2_IFU__IDUBusy;
  wire [15:0] wCR2_ControlRegister;
  wire wCR2_TextureMappingEnabled;
  wire wGEO2_CU__TFFDone;
  wire wCU2_GEO__TriggerTFF;
  wire wIO2_MEM_InstructionWriteEnable;
  wire wCU2_IO__WritePixel;
  wire wGEO2_IO__AddrIsImm;
  wire [31:0] wGEO2_IO__AddressOffset;
  wire wGEO2_IO__EnableWBMaster;
  wire wGEO2_IO__SetAddress;
  wire [32-1:0] wGEO2__CurrentPitch;wire [32-1:0] wCU2_GEO_Pitch;
  wire wCU2_GEO__SetPitch;wire wCU2_GEO__IncPicth;
  wire [96-1:0] wEXE_2__IO_WriteAddress;
  wire [96-1:0] wEXE_2__IO_WriteData;
  wire wEXE_2__IO_OMEMWriteEnable;
  wire [96-1:0] wEXE_2__IO_TMEMAddress;
  wire [96-1:0] wIO_2_EXE__TMEMData;
  wire wIO_2_EXE__DataAvailable;
  wire wEXE_2_IO__DataRequest;
  wire wCU2_FlipMem;
  wire wCU2_FlipMemEnabled;
  wire w2MEM_FlipMemory;
  wire wGEO2__RequestingTextures;
  wire w2IO_WriteBack_Set;
  wire [16-1:0] wIO_2_MEM__DataReadAddress1;
  assign HDL_O = wCU2_FlipMem;
  assign wCR2_TextureMappingEnabled = wCR2_ControlRegister[1];

  ControlUnit
  CU
  (
    .Clock(Clock),
    .Reset(Reset),
    .oFlipMemEnabled(wCU2_FlipMemEnabled),
    .oFlipMem(wCU2_FlipMem),
    .iControlRegister(wCR2_ControlRegister),
    .oGFUEnable(wCU2_GEO__GeometryFetchEnable),
    .iTriggerAABBIURequest(wGEO2_CU__RequestAABBIU),
    .iTriggerBIURequest(wGEO2_CU__RequestBIU),
    .iTriggertTCCRequest(wGEO2_CU__RequestTCC),
    .oUCodeEnable(wCU2__ExecuteMicroCode),
    .oCodeInstructioPointer(InitialCodeAddress),
    .iUCodeDone(wCU2__MicrocodeExecutionDone),
    .iIODone(wIO2__Done),
    .oIOWritePixel(wCU2_IO__WritePixel),
    .iUCodeReturnValue(wIFU2__MicroCodeReturnValue),
    .iGEOSync(wGEO2_CU__Sync),
    .iTFFDone(wGEO2_CU__TFFDone),
    .oTriggerTFF(wCU2_GEO__TriggerTFF),
    .MST_I(MST_I),
    .oSetCurrentPitch(wCU2_GEO__SetPitch),
    .iGFUDone(wGEO2_CU__GeometryUnitDone),
    .iRenderEnable(RENDREN_I),
    .iSceneTraverseComplete(STDONE_I),
    .oResultCommited(RCOMMIT_O),
    .iHostDataAvailable(HDA_I),
    .iHostAckDataRead(HDLACK_I),
    .oDone(DONE_O)
  );

  assign w2MEM_FlipMemory = wCU2_FlipMem & wCU2_FlipMemEnabled;

  MemoryUnit
  MEM
  (
    .Clock(Clock),
    .Reset(Reset),
    .iFlipMemory(wIO2_MEM__DataWriteEnable),
    .iDataReadAddress1_EXE(wEXE_2__MEM_DataReadAddress0),
    .iDataReadAddress2_EXE(wEXE_2__MEM_DataReadAddress1),
    .oData1_EXE(wMEM_2__EXE_DataRead0),
    .oData2_EXE(wMEM_2__EXE_DataRead1),
    .iDataWriteEnable_EXE(wIO2_MEM_InstructionWriteEnable),
    .iDataWriteAddress_EXE(wEXE_2__MEM_wDataWriteAddress),
    .iData_EXE(wEXE_2__MEM_WriteData),
    .iDataReadAddress1_IO(wIO_2_MEM__DataReadAddress0),
    .iDataReadAddress2_IO(wIO_2_MEM__DataReadAddress1),
    .oData1_IO(wMEM_2__IO_DataRead0),
    .oData2_IO(wMEM_2__IO_DataRead1),
    .iDataWriteEnable_IO(w2MEM_FlipMemory),
    .iDataWriteAddress_IO(wIO2_MEM__DataWriteAddress),
    .iData_IO(wIO2_MEM__Bus),
    .iInstructionReadAddress1(wInstructionPointer1),
    .iInstructionReadAddress2(wInstructionPointer2),
    .oInstruction1(wEncodedInstruction1),
    .oInstruction2(wEncodedInstruction2),
    .iInstructionWriteEnable(wEXE_2__DataWriteEnable),
    .iInstructionWriteAddress(wIO2_MEM__InstructionWriteAddr),
    .iInstruction(wIO2_MEM__ExternalInstruction),
    .iControlRegister(CREG_I),
    .oControlRegister(wCR2_ControlRegister)
  );


  ExecutionUnit
  EXE
  (
    .Clock(Clock),
    .Reset(Reset),
    .iInitialCodeAddress(InitialCodeAddress),
    .iInstruction1(wEncodedInstruction1),
    .iInstruction2(wEncodedInstruction2),
    .oInstructionPointer1(wInstructionPointer1),
    .oInstructionPointer2(wInstructionPointer2),
    .iDataRead0(wMEM_2__EXE_DataRead0),
    .iDataRead1(wMEM_2__EXE_DataRead1),
    .iTrigger(wCU2__ExecuteMicroCode),
    .oDataReadAddress0(wEXE_2__MEM_DataReadAddress0),
    .oDataReadAddress1(wEXE_2__MEM_DataReadAddress1),
    .oDataWriteEnable(wEXE_2__DataWriteEnable),
    .oDataWriteAddress(wEXE_2__MEM_wDataWriteAddress),
    .oDataBus(wEXE_2__MEM_WriteData),
    .oReturnCode(wIFU2__MicroCodeReturnValue),
    .oOMEMWriteAddress(wEXE_2__IO_WriteAddress),
    .oOMEMWriteData(wEXE_2__IO_WriteData),
    .oOMEMWriteEnable(wEXE_2__IO_OMEMWriteEnable),
    .oTMEMReadAddress(wEXE_2__IO_TMEMAddress),
    .iTMEMReadData(wIO_2_EXE__TMEMData),
    .iTMEMDataAvailable(wIO_2_EXE__DataAvailable),
    .oTMEMDataRequest(wEXE_2_IO__DataRequest),
    .oDone(wCU2__MicrocodeExecutionDone)
  );

  assign TGA_O = (wGEO2__RequestingTextures)? 2'b1 : 2'b0;
  assign w2IO__EnableWBMaster = (wCU2_IO__WritePixel == 0)? wGEO2_IO__EnableWBMaster : wCU2_IO__WritePixel;
  assign w2IO__AddrIsImm = 0;
  assign w2IO__AddressOffset = 0;
  assign w2IO__Adr_O_Pointer = (wCU2_IO__WritePixel == 0)? wGEO2_IO__Adr_O_Pointer : 16'd131;
  wire w2IO_MasterCycleType;
  assign w2IO_MasterCycleType = (wCU2_IO__WritePixel)? 1 : 0;
  assign w2IO__SetAddress = (wCU2_IO__WritePixel == 0)? wGEO2_IO__SetAddress : wCU2_GEO__SetPitch;

  IO_Unit
  IO
  (
    .Clock(Clock),
    .Reset(Reset),
    .iEnable(1'b0),
    .iBusCyc_Type(w2IO_MasterCycleType),
    .iStore(1'b1),
    .iAdr_DataWriteBack(w2IO__DataWriteAddress),
    .iAdr_O_Set(w2IO__SetAddress),
    .iAdr_O_Imm(w2IO__AddressOffset),
    .iAdr_O_Type(w2IO__AddrIsImm),
    .iAdr_O_Pointer(w2IO__Adr_O_Pointer),
    .iReadDataBus(wMEM_2__IO_DataRead0),
    .iReadDataBus2(wMEM_2__IO_DataRead1),
    .iDat_O_Pointer(16'd128),
    .oDataReadAddress(wIO_2_MEM__DataReadAddress0),
    .oDataReadAddress2(wIO_2_MEM__DataReadAddress1),
    .oDataWriteAddress(wIO2_MEM__DataWriteAddress),
    .oDataBus(wIO2_MEM__Bus),
    .oInstructionBus(wIO2_MEM__ExternalInstruction),
    .oDataWriteEnable(wIO2_MEM__DataWriteEnable),
    .oData(wIO2_MEM__Data),
    .oInstructionWriteEnable(wIO2_MEM_InstructionWriteEnable),
    .oInstructionWriteAddress(wIO2_MEM__InstructionWriteAddr),
    .iWriteBack_Set(w2IO_WriteBack_Set),
    .oBusy(wIO_Busy),
    .oDone(wIO2__Done),
    .iOMEM_WriteAddress(wEXE_2__IO_WriteAddress),
    .iOMEM_WriteData(wEXE_2__IO_WriteData),
    .iOMEM_WriteEnable(wEXE_2__IO_OMEMWriteEnable),
    .OMEM_DAT_O(OMEM_DAT_O),
    .OMEM_ADR_O(OMEM_ADR_O),
    .OMEM_WE_O(OMEM_WE_O),
    .oTMEMReadData(wIO_2_EXE__TMEMData),
    .iTMEMDataRequest(wEXE_2_IO__DataRequest),
    .iTMEMReadAddress(wEXE_2__IO_TMEMAddress),
    .oTMEMDataAvailable(wIO_2_EXE__DataAvailable),
    .TMEM_ACK_I(TMEM_ACK_I),
    .TMEM_DAT_I(TMEM_DAT_I),
    .TMEM_ADR_O(TMEM_ADR_O),
    .TMEM_WE_O(TMEM_WE_O),
    .TMEM_STB_O(TMEM_STB_O),
    .TMEM_CYC_O(TMEM_CYC_O),
    .TMEM_GNT_I(TMEM_GNT_I),
    .MST_I(MST_I),
    .DAT_I(DAT_I),
    .DAT_O(DAT_O),
    .ACK_I(ACK_I & GNT_I),
    .ACK_O(ACK_O),
    .ADR_O(ADR_O),
    .ADR_I(ADR_I),
    .WE_O(WE_O),
    .WE_I(WE_I),
    .STB_O(STB_O),
    .STB_I(STB_I),
    .CYC_O(CYC_O),
    .TGA_I(TGA_I),
    .CYC_I(CYC_I),
    .GNT_I(GNT_I),
    .TGC_O(TGC_O)
  );


endmodule

