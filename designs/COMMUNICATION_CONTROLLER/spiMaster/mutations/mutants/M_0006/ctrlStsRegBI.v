

module ctrlStsRegBI
(
  busClk,
  rstFromWire,
  dataIn,
  dataOut,
  address,
  writeEn,
  strobe_i,
  spiSysClk,
  spiTransType,
  spiTransCtrl,
  spiTransStatus,
  spiDirectAccessTxData,
  spiDirectAccessRxData,
  ctrlStsRegSel,
  rstSyncToBusClkOut,
  rstSyncToSpiClkOut,
  SDWriteError,
  SDReadError,
  SDInitError,
  SDAddr,
  spiClkDelay
);

  input [7:0] dataIn;
  input [7:0] address;
  input writeEn;
  input strobe_i;
  input busClk;
  input spiSysClk;
  output [7:0] dataOut;
  input ctrlStsRegSel;
  output [1:0] spiTransType;
  output spiTransCtrl;
  input spiTransStatus;
  output [7:0] spiDirectAccessTxData;
  reg [7:0] spiDirectAccessTxData;
  input [7:0] spiDirectAccessRxData;
  input rstFromWire;
  output rstSyncToBusClkOut;
  output rstSyncToSpiClkOut;
  input [1:0] SDWriteError;
  input [1:0] SDReadError;
  input [1:0] SDInitError;
  output [31:0] SDAddr;
  reg [31:0] SDAddr;
  output [7:0] spiClkDelay;
  reg [7:0] spiClkDelay;
  wire [7:0] dataIn;
  wire [7:0] address;
  wire writeEn;
  wire strobe_i;
  wire clk;
  reg [7:0] dataOut;
  reg [1:0] spiTransType;
  reg spiTransCtrl;
  wire ctrlStsRegSel;
  wire rstFromWire;
  reg rstSyncToBusClkOut;
  reg rstSyncToSpiClkOut;
  reg [5:0] rstShift;
  reg rstFromBus;
  reg [7:0] spiDirectAccessTxDataSTB;
  reg [7:0] spiDirectAccessRxDataSTB;
  reg [1:0] spiTransTypeSTB;
  reg spiTransCtrlSTB;
  reg spiTransStatusSTB;
  reg rstSyncToSpiClkFirst;
  reg [5:0] spiTransCtrlShift;
  reg spiTransStatusReg1;
  reg spiTransStatusReg2;
  reg spiTransStatusReg3;
  reg [1:0] SDWriteErrorSTB;
  reg [1:0] SDReadErrorSTB;
  reg [1:0] SDInitErrorSTB;
  reg spiTransCtrl_reg1;
  reg spiTransCtrl_reg2;
  reg spiTransCtrl_reg3;

  always @(posedge busClk) begin
    if(rstSyncToBusClkOut == 1'b1) begin
      spiTransTypeSTB <= 2'b00;
      spiTransCtrlSTB <= 1'b0;
      spiDirectAccessTxDataSTB <= 8'h00;
      spiClkDelay <= 8'h00;
    end else begin
      if((writeEn == 1'b1) && (ctrlStsRegSel == 1'b1) && (strobe_i == 1'b1) && (address == 8'h01) && (dataIn[0] == 1'b1)) rstFromBus <= 1'b1; 
      else rstFromBus <= 1'b0;
      if((writeEn == 1'b1) && (ctrlStsRegSel == 1'b1) && (strobe_i == 1'b1) && (address == 8'h03) && (dataIn[0] == 1'b1)) spiTransCtrlSTB <= 1'b1; 
      else spiTransCtrlSTB <= 1'b0;
      if((writeEn == 1'b1) && (ctrlStsRegSel == 1'b1) && (strobe_i == 1'b1)) begin
        case(address)
          8'h02: spiTransTypeSTB <= dataIn[0:0];
          8'h07: SDAddr[7:0] <= dataIn;
          8'h08: SDAddr[15:8] <= dataIn;
          8'h09: SDAddr[23:16] <= dataIn;
          8'h0a: SDAddr[31:24] <= dataIn;
          8'h0b: spiClkDelay <= dataIn;
          8'h06: spiDirectAccessTxDataSTB <= dataIn;
        endcase
      end 
    end
  end


  always @(address or spiTransTypeSTB or spiTransCtrlSTB or spiTransStatusSTB or spiDirectAccessRxDataSTB or SDAddr or SDInitErrorSTB or SDReadErrorSTB or SDWriteErrorSTB or spiClkDelay) begin
    case(address)
      8'h00: dataOut <= 8'h12;
      8'h02: dataOut <= { 6'b000000, spiTransTypeSTB };
      8'h03: dataOut <= { 7'b0000000, spiTransCtrlSTB };
      8'h04: dataOut <= { 7'b0000000, spiTransStatusSTB };
      8'h05: dataOut <= { 2'b00, SDWriteErrorSTB, SDReadErrorSTB, SDInitErrorSTB };
      8'h07: dataOut <= SDAddr[7:0];
      8'h08: dataOut <= SDAddr[15:8];
      8'h09: dataOut <= SDAddr[23:16];
      8'h0a: dataOut <= SDAddr[31:24];
      8'h0b: dataOut <= spiClkDelay;
      8'h06: dataOut <= spiDirectAccessRxDataSTB;
      default: dataOut <= 8'h00;
    endcase
  end


  always @(posedge busClk) begin
    if((rstFromWire == 1'b1) || (rstFromBus == 1'b1)) rstShift <= 6'b111111; 
    else rstShift <= { 1'b0, rstShift[5:1] };
  end


  always @(rstShift) rstSyncToBusClkOut <= rstShift[0];


  always @(posedge spiSysClk) begin
    rstSyncToSpiClkFirst <= rstSyncToBusClkOut;
    rstSyncToSpiClkOut <= rstSyncToSpiClkFirst;
  end


  always @(posedge busClk) begin
    if(rstSyncToBusClkOut == 1'b1) spiTransCtrlShift <= 6'b000000; 
    else if(spiTransCtrlSTB == 1'b1) spiTransCtrlShift <= 6'b111111; 
    else spiTransCtrlShift <= { 1'b0, spiTransCtrlShift[5:1] };
  end


  always @(posedge spiSysClk) begin
    if(rstSyncToSpiClkOut == 1'b1) begin
      spiTransCtrl_reg1 <= 1'b0;
      spiTransCtrl_reg2 <= 1'b0;
      spiTransCtrl_reg3 <= 1'b0;
    end else begin
      spiTransCtrl_reg1 <= spiTransCtrlShift[0];
      spiTransCtrl_reg2 <= spiTransCtrl_reg1;
      spiTransCtrl_reg3 <= spiTransCtrl_reg2;
      if((spiTransCtrl_reg3 == 1'b0) && (spiTransCtrl_reg2 == 1'b1)) spiTransCtrl <= 1'b1; 
      else spiTransCtrl <= 1'b0;
    end
  end


  always @(posedge spiSysClk) begin
    if(rstSyncToSpiClkOut == 1'b1) begin
      spiTransType <= 2'b00;
      spiDirectAccessTxData <= 8'h00;
    end else begin
      spiDirectAccessTxData <= spiDirectAccessTxDataSTB;
      spiTransType <= spiTransTypeSTB;
    end
  end


  always @(posedge busClk) begin
    if(rstSyncToBusClkOut == 1'b1) begin
      spiTransStatusSTB <= 1'b0;
      spiTransStatusReg1 <= 1'b0;
      spiTransStatusReg2 <= 1'b0;
      spiTransStatusReg3 <= 1'b0;
    end else begin
      spiTransStatusReg1 <= spiTransStatus;
      spiTransStatusReg2 <= spiTransStatusReg1;
      spiTransStatusReg3 <= spiTransStatusReg2;
      if(spiTransCtrlSTB == 1'b1) spiTransStatusSTB <= 1'b1; 
      else if((spiTransStatusReg3 == 1'b1) && (spiTransStatusReg2 == 1'b0)) spiTransStatusSTB <= 1'b0; 
    end
    spiDirectAccessRxDataSTB <= spiDirectAccessRxData;
    SDWriteErrorSTB <= SDWriteError;
    SDReadErrorSTB <= SDReadError;
    SDInitErrorSTB <= SDInitError;
  end


endmodule

