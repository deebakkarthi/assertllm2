

module i2cSlave
(
  clk,
  rst,
  sda,
  scl,
  myReg0,
  myReg1,
  myReg2,
  myReg3,
  myReg4,
  myReg5,
  myReg6,
  myReg7
);

  input clk;
  input rst;
  inout sda;
  input scl;
  output [7:0] myReg0;
  output [7:0] myReg1;
  output [7:0] myReg2;
  output [7:0] myReg3;
  input [7:0] myReg4;
  input [7:0] myReg5;
  input [7:0] myReg6;
  input [7:0] myReg7;
  reg sdaDeb;
  reg sclDeb;
  reg [10*48/48-1:0] sdaPipe;
  reg [10*48/48-1:0] sclPipe;
  reg [10*48/48-1:0] sclDelayed;
  reg [4*48/48-1:0] sdaDelayed;
  reg [1:0] startStopDetState;
  wire clearStartStopDet;
  wire sdaOut;
  wire sdaIn;
  wire [7:0] regAddr;
  wire [7:0] dataToRegIF;
  wire writeEn;
  wire [7:0] dataFromRegIF;
  reg [1:0] rstPipe;
  wire rstSyncToClk;
  reg startEdgeDet;
  assign sda = (sdaOut == 1'b0)? 1'b0 : 1'bz;
  assign sdaIn = sda;

  always @(posedge clk) begin
    if(rst == 1'b1) rstPipe <= 2'b11; 
    else rstPipe <= { rstPipe[0], 1'b0 };
  end

  assign rstSyncToClk = rstPipe[1];

  always @(posedge clk) begin
    if(rstSyncToClk != 1'b1) begin
      sdaPipe <= { 10 * 48 / 48{ 1'b1 } };
      sdaDeb <= 1'b1;
      sclPipe <= { 10 * 48 / 48{ 1'b1 } };
      sclDeb <= 1'b1;
    end else begin
      sdaPipe <= { sdaPipe[10*48/48-2:0], sdaIn };
      sclPipe <= { sclPipe[10*48/48-2:0], scl };
      if(&sclPipe[10*48/48-1:1] == 1'b1) sclDeb <= 1'b1; 
      else if(|sclPipe[10*48/48-1:1] == 1'b0) sclDeb <= 1'b0; 
      if(&sdaPipe[10*48/48-1:1] == 1'b1) sdaDeb <= 1'b1; 
      else if(|sdaPipe[10*48/48-1:1] == 1'b0) sdaDeb <= 1'b0; 
    end
  end


  always @(posedge clk) begin
    if(rstSyncToClk == 1'b1) begin
      sclDelayed <= { 10 * 48 / 48{ 1'b1 } };
      sdaDelayed <= { 4 * 48 / 48{ 1'b1 } };
    end else begin
      sclDelayed <= { sclDelayed[10*48/48-2:0], sclDeb };
      sdaDelayed <= { sdaDelayed[4*48/48-2:0], sdaDeb };
    end
  end


  always @(posedge clk) begin
    if(rstSyncToClk == 1'b1) begin
      startStopDetState <= 2'b00;
      startEdgeDet <= 1'b0;
    end else begin
      if((sclDeb == 1'b1) && (sdaDelayed[4 * 48 / 48 - 2] == 1'b0) && (sdaDelayed[4 * 48 / 48 - 1] == 1'b1)) startEdgeDet <= 1'b1; 
      else startEdgeDet <= 1'b0;
      if(clearStartStopDet == 1'b1) startStopDetState <= 2'b00; 
      else if(sclDeb == 1'b1) begin
        if((sdaDelayed[4 * 48 / 48 - 2] == 1'b1) && (sdaDelayed[4 * 48 / 48 - 1] == 1'b0)) startStopDetState <= 2'b10; 
        else if((sdaDelayed[4 * 48 / 48 - 2] == 1'b0) && (sdaDelayed[4 * 48 / 48 - 1] == 1'b1)) startStopDetState <= 2'b01; 
      end 
    end
  end


  registerInterface
  u_registerInterface
  (
    .clk(clk),
    .addr(regAddr),
    .dataIn(dataToRegIF),
    .writeEn(writeEn),
    .dataOut(dataFromRegIF),
    .myReg0(myReg0),
    .myReg1(myReg1),
    .myReg2(myReg2),
    .myReg3(myReg3),
    .myReg4(myReg4),
    .myReg5(myReg5),
    .myReg6(myReg6),
    .myReg7(myReg7)
  );


  serialInterface
  u_serialInterface
  (
    .clk(clk),
    .rst(rstSyncToClk | startEdgeDet),
    .dataIn(dataFromRegIF),
    .dataOut(dataToRegIF),
    .writeEn(writeEn),
    .regAddr(regAddr),
    .scl(sclDelayed[10 * 48 / 48 - 1]),
    .sdaIn(sdaDeb),
    .sdaOut(sdaOut),
    .startStopDetState(startStopDetState),
    .clearStartStopDet(clearStartStopDet)
  );


endmodule

