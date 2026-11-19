

module eth_miim
(
  Clk,
  Reset,
  Divider,
  NoPre,
  CtrlData,
  Rgad,
  Fiad,
  WCtrlData,
  RStat,
  ScanStat,
  Mdo,
  MdoEn,
  Mdi,
  Mdc,
  Busy,
  Prsd,
  LinkFail,
  Nvalid,
  WCtrlDataStart,
  RStatStart,
  UpdateMIIRX_DATAReg
);

  input Clk;
  input Reset;
  input [7:0] Divider;
  input [15:0] CtrlData;
  input [4:0] Rgad;
  input [4:0] Fiad;
  input NoPre;
  input WCtrlData;
  input RStat;
  input ScanStat;
  output Mdo;
  output MdoEn;
  input Mdi;
  output Mdc;
  output Busy;
  output LinkFail;
  output Nvalid;
  output [15:0] Prsd;
  output WCtrlDataStart;
  output RStatStart;
  output UpdateMIIRX_DATAReg;
  parameter Tp = 1;
  reg Nvalid;
  reg EndBusy_d;
  reg EndBusy;
  reg WCtrlData_q1;
  reg WCtrlData_q2;
  reg WCtrlData_q3;
  reg WCtrlDataStart;
  reg WCtrlDataStart_q;
  reg WCtrlDataStart_q1;
  reg WCtrlDataStart_q2;
  reg RStat_q1;
  reg RStat_q2;
  reg RStat_q3;
  reg RStatStart;
  reg RStatStart_q1;
  reg RStatStart_q2;
  reg ScanStat_q1;
  reg ScanStat_q2;
  reg SyncStatMdcEn;
  wire WriteDataOp;
  wire ReadStatusOp;
  wire ScanStatusOp;
  wire StartOp;
  wire EndOp;
  reg InProgress;
  reg InProgress_q1;
  reg InProgress_q2;
  reg InProgress_q3;
  reg WriteOp;
  reg [6:0] BitCounter;
  wire MdcFrame;
  wire [3:0] ByteSelect;
  wire MdcEn;
  wire ShiftedBit;
  wire LatchByte1_d2;
  wire LatchByte0_d2;
  reg LatchByte1_d;
  reg LatchByte0_d;
  reg [1:0] LatchByte;
  reg UpdateMIIRX_DATAReg;

  always @(posedge Clk or posedge Reset) begin
    if(Reset) begin
      EndBusy_d <= #Tp 1'b0;
      EndBusy <= #Tp 1'b0;
    end else begin
      EndBusy_d <= #Tp ~InProgress_q2 & InProgress_q3;
      EndBusy <= #Tp EndBusy_d;
    end
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) UpdateMIIRX_DATAReg <= #Tp 0; 
    else if(EndBusy & ~WCtrlDataStart_q) UpdateMIIRX_DATAReg <= #Tp 1; 
    else UpdateMIIRX_DATAReg <= #Tp 0;
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) begin
      WCtrlData_q1 <= #Tp 1'b0;
      WCtrlData_q2 <= #Tp 1'b0;
      WCtrlData_q3 <= #Tp 1'b0;
      RStat_q1 <= #Tp 1'b0;
      RStat_q2 <= #Tp 1'b0;
      RStat_q3 <= #Tp 1'b0;
      ScanStat_q1 <= #Tp 1'b0;
      ScanStat_q2 <= #Tp 1'b0;
      SyncStatMdcEn <= #Tp 1'b0;
    end else begin
      WCtrlData_q1 <= #Tp WCtrlData;
      WCtrlData_q2 <= #Tp WCtrlData_q1;
      WCtrlData_q3 <= #Tp WCtrlData_q2;
      RStat_q1 <= #Tp RStat;
      RStat_q2 <= #Tp RStat_q1;
      RStat_q3 <= #Tp RStat_q2;
      ScanStat_q1 <= #Tp ScanStat;
      ScanStat_q2 <= #Tp ScanStat_q1;
      if(MdcEn) SyncStatMdcEn <= #Tp ScanStat_q2; 
    end
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) begin
      WCtrlDataStart <= #Tp 1'b0;
      WCtrlDataStart_q <= #Tp 1'b0;
      RStatStart <= #Tp 1'b0;
    end else begin
      if(EndBusy) begin
        WCtrlDataStart <= #Tp 1'b0;
        RStatStart <= #Tp 1'b0;
      end else begin
        if(WCtrlData_q2 & ~WCtrlData_q3) WCtrlDataStart <= #Tp 1'b1; 
        if(RStat_q2 & ~RStat_q3) RStatStart <= #Tp 1'b1; 
        WCtrlDataStart_q <= #Tp WCtrlDataStart;
      end
    end
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) Nvalid <= #Tp 1'b0; 
    else begin
      if(~InProgress_q2 & InProgress_q3) begin
        Nvalid <= #Tp 1'b0;
      end else begin
        if(ScanStat_q2 & ~SyncStatMdcEn) Nvalid <= #Tp 1'b1; 
      end
    end
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) begin
      WCtrlDataStart_q1 <= #Tp 1'b0;
      WCtrlDataStart_q2 <= #Tp 1'b0;
      RStatStart_q1 <= #Tp 1'b0;
      RStatStart_q2 <= #Tp 1'b0;
      InProgress_q1 <= #Tp 1'b0;
      InProgress_q2 <= #Tp 1'b0;
      InProgress_q3 <= #Tp 1'b0;
      LatchByte0_d <= #Tp 1'b0;
      LatchByte1_d <= #Tp 1'b0;
      LatchByte <= #Tp 2'b00;
    end else begin
      if(MdcEn) begin
        WCtrlDataStart_q1 <= #Tp WCtrlDataStart;
        WCtrlDataStart_q2 <= #Tp WCtrlDataStart_q1;
        RStatStart_q1 <= #Tp RStatStart;
        RStatStart_q2 <= #Tp RStatStart_q1;
        LatchByte[0] <= #Tp LatchByte0_d;
        LatchByte[1] <= #Tp LatchByte1_d;
        LatchByte0_d <= #Tp LatchByte0_d2;
        LatchByte1_d <= #Tp LatchByte1_d2;
        InProgress_q1 <= #Tp InProgress;
        InProgress_q2 <= #Tp InProgress_q1;
        InProgress_q3 <= #Tp InProgress_q2;
      end 
    end
  end

  assign WriteDataOp = WCtrlDataStart_q1 & ~WCtrlDataStart_q2;
  assign ReadStatusOp = RStatStart_q1 & ~RStatStart_q2;
  assign ScanStatusOp = SyncStatMdcEn & ~InProgress & ~InProgress_q1 & ~InProgress_q2;
  assign StartOp = WriteDataOp | ReadStatusOp | ScanStatusOp;
  reg Busy;

  always @(posedge Clk or posedge Reset) if(Reset) Busy <= 0; 
  else if((WCtrlData | WCtrlDataStart | RStat | RStatStart | SyncStatMdcEn) & EndBusy | InProgress | InProgress_q3 | Nvalid) Busy <= 1; 
  else Busy <= 0;


  always @(posedge Clk or posedge Reset) begin
    if(Reset) begin
      InProgress <= #Tp 1'b0;
      WriteOp <= #Tp 1'b0;
    end else begin
      if(MdcEn) begin
        if(StartOp) begin
          if(~InProgress) WriteOp <= #Tp WriteDataOp; 
          InProgress <= #Tp 1'b1;
        end else begin
          if(EndOp) begin
            InProgress <= #Tp 1'b0;
            WriteOp <= #Tp 1'b0;
          end 
        end
      end 
    end
  end


  always @(posedge Clk or posedge Reset) begin
    if(Reset) BitCounter[6:0] <= #Tp 7'h0; 
    else begin
      if(MdcEn) begin
        if(InProgress) begin
          if(NoPre & (BitCounter == 7'h0)) BitCounter[6:0] <= #Tp 7'h21; 
          else BitCounter[6:0] <= #Tp BitCounter[6:0] + 1'b1;
        end else BitCounter[6:0] <= #Tp 7'h0;
      end 
    end
  end

  assign EndOp = BitCounter == 63;
  assign ByteSelect[0] = InProgress & (NoPre & (BitCounter == 7'h0) | ~NoPre & (BitCounter == 7'h20));
  assign ByteSelect[1] = InProgress & (BitCounter == 7'h28);
  assign ByteSelect[2] = InProgress & WriteOp & (BitCounter == 7'h30);
  assign ByteSelect[3] = InProgress & WriteOp & (BitCounter == 7'h38);
  assign LatchByte1_d2 = InProgress & ~WriteOp & (BitCounter == 7'h37);
  assign LatchByte0_d2 = InProgress & ~WriteOp & (BitCounter == 7'h3F);

  eth_clockgen
  clkgen
  (
    .Clk(Clk),
    .Reset(Reset),
    .Divider(Divider[7:0]),
    .MdcEn(MdcEn),
    .MdcEn_n(MdcEn_n),
    .Mdc(Mdc)
  );


  eth_shiftreg
  shftrg
  (
    .Clk(Clk),
    .Reset(Reset),
    .MdcEn_n(MdcEn_n),
    .Mdi(Mdi),
    .Fiad(Fiad),
    .Rgad(Rgad),
    .CtrlData(CtrlData),
    .WriteOp(WriteOp),
    .ByteSelect(ByteSelect),
    .LatchByte(LatchByte),
    .ShiftedBit(ShiftedBit),
    .Prsd(Prsd),
    .LinkFail(LinkFail)
  );


  eth_outputcontrol
  outctrl
  (
    .Clk(Clk),
    .Reset(Reset),
    .MdcEn_n(MdcEn_n),
    .InProgress(InProgress),
    .ShiftedBit(ShiftedBit),
    .BitCounter(BitCounter),
    .WriteOp(WriteOp),
    .NoPre(NoPre),
    .Mdo(Mdo),
    .MdoEn(MdoEn)
  );


endmodule

