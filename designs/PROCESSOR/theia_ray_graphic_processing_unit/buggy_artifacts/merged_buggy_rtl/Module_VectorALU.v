

module VectorALU
(
  input wire Clock,
  input wire Reset,
  input wire [16-1:0] iOperation,
  input wire [32-1:0] iChannel_Ax,
  input wire [32-1:0] iChannel_Bx,
  input wire [32-1:0] iChannel_Ay,
  input wire [32-1:0] iChannel_By,
  input wire [32-1:0] iChannel_Az,
  input wire [32-1:0] iChannel_Bz,
  output wire [32-1:0] oResultA,
  output wire [32-1:0] oResultB,
  output wire [32-1:0] oResultC,
  input wire iInputReady,
  output reg oBranchTaken,
  output reg oBranchNotTaken,
  output reg oReturnFromSub,
  input wire [16-1:0] iCurrentIP,
  output wire [96-1:0] oOMEMWriteAddress,
  output wire [96-1:0] oOMEMWriteData,
  output wire oOMEM_WriteEnable,
  output wire [96-1:0] oTMEMReadAddress,
  input wire [96-1:0] iTMEMReadData,
  input wire iTMEMDataAvailable,
  output wire oTMEMDataRequest,
  output reg OutputReady
);

  wire wMultiplcationUnscaled;
  assign wMultiplcationUnscaled = (iOperation == 16'b0_101_000)? 1'b1 : 1'b0;
  reg [7:0] InputReadyA;reg [7:0] InputReadyB;reg [7:0] InputReadyC;
  reg [32-1:0] wMultiplicationA_Ax;
  reg [32-1:0] wMultiplicationA_Bx;
  wire [64-1:0] wMultiplicationA_Result;
  wire wMultiplicationA_InputReady;
  wire wMultiplicationA_OutputReady;
  wire wMultiplicationOutputReady;wire wMultiplicationOutputReadyA;wire wMultiplicationOutputReadyB;wire wMultiplicationOutputReadyC;wire wMultiplicationOutputReadyD;
  wire wAddSubAOutputReady;wire wAddSubBOutputReady;wire wAddSubCOutputReady;
  wire [16-1:0] wOperation;
  wire [32-1:0] wSwizzleOutputX;wire [32-1:0] wSwizzleOutputY;wire [32-1:0] wSwizzleOutputZ;
  reg [32-1:0] ResultA;reg [32-1:0] ResultB;reg [32-1:0] ResultC;

  FFD32_POSEDGE
  ResultAFFD
  (
    .Clock(OutputReady),
    .D(ResultA),
    .Q(oResultA)
  );


  FFD32_POSEDGE
  ResultBFFD
  (
    .Clock(OutputReady),
    .D(ResultB),
    .Q(oResultB)
  );


  FFD32_POSEDGE
  ResultCFFD
  (
    .Clock(OutputReady),
    .D(ResultC),
    .Q(oResultC)
  );


  Swizzle3D
  Swizzle1
  (
    .Source0_X(iChannel_Bx),
    .Source0_Y(iChannel_By),
    .Source0_Z(iChannel_Bz),
    .iOperation(iChannel_Ax),
    .SwizzleX(wSwizzleOutputX),
    .SwizzleY(wSwizzleOutputY),
    .SwizzleZ(wSwizzleOutputZ)
  );

  wire [64-1:0] wModulus2N_ResultA;wire [64-1:0] wModulus2N_ResultB;wire [64-1:0] wModulus2N_ResultC;
  wire IOW_Operation;wire wOMEM_We;
  assign IOW_Operation = iOperation == 16'b0_101_111;

  always @(*) begin
    if(iOperation == 16'b1_011010) oReturnFromSub <= OutputReady;
    else oReturnFromSub <= 1'b0;
  end


  FFD_POSEDGE_SYNCRONOUS_RESET
  #(
    1
  )
  FFD1_AWE
  (
    .Clock(Clock),
    .Reset(Reset),
    .Enable(1'b1),
    .D(IOW_Operation),
    .Q(wOMEM_We)
  );

  assign oOMEM_WriteEnable = wOMEM_We & IOW_Operation;

  FFD_POSEDGE_SYNCRONOUS_RESET
  #(
    96
  )
  FFD1_A
  (
    .Clock(Clock),
    .Reset(Reset),
    .Enable(iInputReady),
    .D({ iChannel_Ax, iChannel_Ay, iChannel_Az }),
    .Q(oOMEMWriteAddress)
  );


  FFD_POSEDGE_SYNCRONOUS_RESET
  #(
    96
  )
  FFD2_B
  (
    .Clock(Clock),
    .Reset(Reset),
    .Enable(iInputReady),
    .D({ iChannel_Bx, iChannel_By, iChannel_Bz }),
    .Q(oOMEMWriteData)
  );

  wire wTMReadOutputReady;
  assign wTMReadOutputReady = iTMEMDataAvailable;
  wire wOpTRead;
  assign wOpTRead = (iOperation == 16'b0_110_000)? 1'b1 : 1'b0;
  wire wTMEMRequest;

  FFD_POSEDGE_SYNCRONOUS_RESET
  #(
    1
  )
  FFD1_ARE123
  (
    .Clock(Clock),
    .Reset(Reset),
    .Enable(1'b1),
    .D(wOpTRead),
    .Q(wTMEMRequest)
  );

  assign oTMEMDataRequest = wTMEMRequest & wOpTRead;

  FFD_POSEDGE_SYNCRONOUS_RESET
  #(
    96
  )
  FFD2_B445
  (
    .Clock(Clock),
    .Reset(Reset),
    .Enable(iInputReady & wOpTRead),
    .D({ iChannel_Ax, iChannel_Ay, iChannel_Az }),
    .Q(oTMEMReadAddress)
  );

  wire wArithmeticComparison_Result;
  wire ArithmeticComparison_InputReady;
  wire ArithmeticComparison_OutputReady;
  reg [32-1:0] ArithmeticComparison_A;reg [32-1:0] ArithmeticComparison_B;

  always @(*) begin
    case({ iOperation[4], iOperation[3] })
      2'b01: ArithmeticComparison_A = iChannel_Ax;
      2'b10: ArithmeticComparison_A = iChannel_Ay;
      2'b11: ArithmeticComparison_A = iChannel_Az;
      default: ArithmeticComparison_A = 0;
    endcase
  end


  always @(*) begin
    case({ iOperation[4], iOperation[3] })
      2'b01: ArithmeticComparison_B = iChannel_Bx;
      2'b10: ArithmeticComparison_B = iChannel_By;
      2'b11: ArithmeticComparison_B = iChannel_Bz;
      default: ArithmeticComparison_B = 0;
    endcase
  end

  assign ArithmeticComparison_InputReady = iInputReady;
  wire wArithmeticComparisonResult;

  ArithmeticComparison
  ArithmeticComparison_1
  (
    .Clock(Clock),
    .X(ArithmeticComparison_A),
    .Y(ArithmeticComparison_B),
    .iOperation(iOperation[2:0]),
    .iInputReady(ArithmeticComparison_InputReady),
    .OutputReady(ArithmeticComparison_OutputReady),
    .Result(wArithmeticComparisonResult)
  );

  assign wArithmeticComparison_Result = wArithmeticComparisonResult && OutputReady;

  RADIX_R_MUL_32_FULL_PARALLEL
  MultiplicationChannel_A
  (
    .Clock(Clock),
    .Reset(Reset),
    .A(wMultiplicationA_Ax),
    .B(wMultiplicationA_Bx),
    .R(wMultiplicationA_Result),
    .iUnscaled(wMultiplcationUnscaled),
    .iInputReady(wMultiplicationA_InputReady),
    .OutputReady(wMultiplicationA_OutputReady)
  );


  always @(*) begin
    case(iOperation)
      16'b0_010_110: wMultiplicationA_Ax = iChannel_Ay;
      16'b0_000101: wMultiplicationA_Ax = iChannel_Ax;
      16'b0_011_111: wMultiplicationA_Ax = iChannel_Ax;
      default: wMultiplicationA_Ax = iChannel_Ax;
    endcase
  end

  assign wMultiplicationA_InputReady = ((iOperation == 16'b0_010_110) || (iOperation == 16'b0_010_111) || (iOperation == 16'b0_000100) || (iOperation == 16'b0_101_000) || (iOperation == 16'b0_000101) || (iOperation == 16'b0_011_111))? iInputReady : 0;

  always @(*) begin
    case(iOperation)
      16'b0_000100, 16'b0_101_000: wMultiplicationA_Bx = iChannel_Bx;
      16'b0_000101: wMultiplicationA_Bx = iChannel_Ax;
      16'b0_010_111: wMultiplicationA_Bx = iChannel_Bx;
      16'b0_010_110: wMultiplicationA_Bx = iChannel_Bz;
      16'b0_011_111: wMultiplicationA_Bx = iChannel_Ay;
      default: wMultiplicationA_Bx = 32'b0;
    endcase
  end

  reg [32-1:0] wMultiplicationB_Ay;
  reg [32-1:0] wMultiplicationB_By;
  wire [64-1:0] wMultiplicationB_Result;
  wire wMultiplicationB_InputReady;
  wire wMultiplicationB_OutputReady;

  RADIX_R_MUL_32_FULL_PARALLEL
  MultiplicationChannel_B
  (
    .Clock(Clock),
    .Reset(Reset),
    .A(wMultiplicationB_Ay),
    .B(wMultiplicationB_By),
    .R(wMultiplicationB_Result),
    .iUnscaled(wMultiplcationUnscaled),
    .iInputReady(wMultiplicationB_InputReady),
    .OutputReady(wMultiplicationB_OutputReady)
  );


  always @(*) begin
    case(iOperation)
      16'b0_010_110: wMultiplicationB_Ay = iChannel_Az;
      16'b0_000101: wMultiplicationB_Ay = iChannel_Ay;
      default: wMultiplicationB_Ay = iChannel_Ay;
    endcase
  end

  assign wMultiplicationB_InputReady = ((iOperation == 16'b0_010_110) || (iOperation == 16'b0_010_111) || (iOperation == 16'b0_000100) || (iOperation == 16'b0_101_000) || (iOperation == 16'b0_000101))? iInputReady : 0;

  always @(*) begin
    case(iOperation)
      16'b0_000100, 16'b0_101_000: wMultiplicationB_By = iChannel_By;
      16'b0_000101: wMultiplicationB_By = iChannel_Ay;
      16'b0_010_111: wMultiplicationB_By = iChannel_By;
      16'b0_010_110: wMultiplicationB_By = iChannel_By;
      default: wMultiplicationB_By = 32'b0;
    endcase
  end

  reg [32-1:0] wMultiplicationC_Az;
  reg [32-1:0] wMultiplicationC_Bz;
  wire [64-1:0] wMultiplicationC_Result;
  wire wMultiplicationC_InputReady;
  wire wMultiplicationC_OutputReady;

  RADIX_R_MUL_32_FULL_PARALLEL
  MultiplicationChannel_C
  (
    .Clock(Clock),
    .Reset(Reset),
    .A(wMultiplicationC_Az),
    .B(wMultiplicationC_Bz),
    .R(wMultiplicationC_Result),
    .iUnscaled(wMultiplcationUnscaled),
    .iInputReady(wMultiplicationC_InputReady),
    .OutputReady(wMultiplicationC_OutputReady)
  );


  always @(*) begin
    case(iOperation)
      16'b0_010_110: wMultiplicationC_Az = iChannel_Az;
      16'b0_000101: wMultiplicationC_Az = iChannel_Az;
      default: wMultiplicationC_Az = iChannel_Az;
    endcase
  end

  assign wMultiplicationC_InputReady = ((iOperation == 16'b0_010_110) || (iOperation == 16'b0_010_111) || (iOperation == 16'b0_000100) || (iOperation == 16'b0_101_000) || (iOperation == 16'b0_000101))? iInputReady : 0;

  always @(*) begin
    case(iOperation)
      16'b0_000100, 16'b0_101_000: wMultiplicationC_Bz = iChannel_Bz;
      16'b0_000101: wMultiplicationC_Bz = iChannel_Az;
      16'b0_010_111: wMultiplicationC_Bz = iChannel_Bz;
      16'b0_010_110: wMultiplicationC_Bz = iChannel_Bx;
      default: wMultiplicationC_Bz = 32'b0;
    endcase
  end

  reg [32-1:0] wMultiplicationD_Aw;
  reg [32-1:0] wMultiplicationD_Bw;
  wire [64-1:0] wMultiplicationD_Result;
  wire wMultiplicationD_InputReady;
  wire wMultiplicationD_OutputReady;

  RADIX_R_MUL_32_FULL_PARALLEL
  MultiplicationChannel_D
  (
    .Clock(Clock),
    .Reset(Reset),
    .A(wMultiplicationD_Aw),
    .B(wMultiplicationD_Bw),
    .R(wMultiplicationD_Result),
    .iUnscaled(wMultiplcationUnscaled),
    .iInputReady(wMultiplicationD_InputReady),
    .OutputReady(wMultiplicationD_OutputReady)
  );

  assign wMultiplicationD_InputReady = ((iOperation == 16'b0_010_110)? 0 : iInputReady);

  always @(*) begin
    case(iOperation)
      16'b0_010_110: wMultiplicationD_Aw = iChannel_Ax;
      default: wMultiplicationD_Aw = 32'b0;
    endcase
  end


  always @(*) begin
    case(iOperation)
      16'b0_010_110: wMultiplicationD_Bw = iChannel_Bz;
      default: wMultiplicationD_Bw = 32'b0;
    endcase
  end

  reg [32-1:0] wMultiplicationE_Ak;
  reg [32-1:0] wMultiplicationE_Bk;
  wire [64-1:0] wMultiplicationE_Result;
  wire wMultiplicationE_InputReady;
  wire wMultiplicationE_OutputReady;

  RADIX_R_MUL_32_FULL_PARALLEL
  MultiplicationChannel_E
  (
    .Clock(Clock),
    .Reset(Reset),
    .A(wMultiplicationE_Ak),
    .B(wMultiplicationE_Bk),
    .R(wMultiplicationE_Result),
    .iUnscaled(wMultiplcationUnscaled),
    .iInputReady(wMultiplicationE_InputReady),
    .OutputReady(wMultiplicationE_OutputReady)
  );

  assign wMultiplicationE_InputReady = (iOperation == 16'b0_010_110)? 0 : iInputReady;

  always @(*) begin
    case(iOperation)
      16'b0_010_110: wMultiplicationE_Ak = iChannel_Ax;
      default: wMultiplicationE_Ak = 32'b0;
    endcase
  end


  always @(*) begin
    case(iOperation)
      16'b0_010_110: wMultiplicationE_Bk = iChannel_By;
      default: wMultiplicationE_Bk = 32'b0;
    endcase
  end

  reg [32-1:0] wMultiplicationF_Al;
  reg [32-1:0] wMultiplicationF_Bl;
  wire [64-1:0] wMultiplicationF_Result;
  wire wMultiplicationF_InputReady;
  wire wMultiplicationF_OutputReady;

  RADIX_R_MUL_32_FULL_PARALLEL
  MultiplicationChannel_F
  (
    .Clock(Clock),
    .Reset(Reset),
    .A(wMultiplicationF_Al),
    .B(wMultiplicationF_Bl),
    .R(wMultiplicationF_Result),
    .iUnscaled(wMultiplcationUnscaled),
    .iInputReady(wMultiplicationF_InputReady),
    .OutputReady(wMultiplicationF_OutputReady)
  );

  assign wMultiplicationF_InputReady = (iOperation == 16'b0_010_110)? iInputReady : 0;

  always @(*) begin
    case(iOperation)
      16'b0_010_110: wMultiplicationF_Al = iChannel_Ay;
      default: wMultiplicationF_Al = 32'b0;
    endcase
  end


  always @(*) begin
    case(iOperation)
      16'b0_010_110: wMultiplicationF_Bl = iChannel_Bx;
      default: wMultiplicationF_Bl = 32'b0;
    endcase
  end

  wire [32-1:0] wDivisionA_Result;
  wire wDivisionA_OutputReady;
  wire wDivisionA_InputReady;
  assign wDivisionA_InputReady = (iOperation == 16'b0_000011)? iInputReady : 0;

  SignedIntegerDivision
  DivisionChannel_A
  (
    .Clock(Clock),
    .Reset(Reset),
    .iDividend(iChannel_Ax),
    .iDivisor(iChannel_Bx),
    .xQuotient(wDivisionA_Result),
    .iInputReady(wDivisionA_InputReady),
    .OutputReady(wDivisionA_OutputReady)
  );

  wire [32-1:0] wDivisionB_Result;
  wire wDivisionB_OutputReady;
  wire wDivisionB_InputReady;
  assign wDivisionB_InputReady = (iOperation == 16'b0_000011)? iInputReady : 0;

  SignedIntegerDivision
  DivisionChannel_B
  (
    .Clock(Clock),
    .Reset(Reset),
    .iDividend(iChannel_Ay),
    .iDivisor(iChannel_By),
    .xQuotient(wDivisionB_Result),
    .iInputReady(wDivisionB_InputReady),
    .OutputReady(wDivisionB_OutputReady)
  );

  wire [32-1:0] wDivisionC_Result;
  wire wDivisionC_OutputReady;
  wire wDivisionC_InputReady;
  assign wDivisionC_InputReady = (iOperation == 16'b0_000011)? iInputReady : 0;

  SignedIntegerDivision
  DivisionChannel_C
  (
    .Clock(Clock),
    .Reset(Reset),
    .iDividend(iChannel_Az),
    .iDivisor(iChannel_Bz),
    .xQuotient(wDivisionC_Result),
    .iInputReady(wDivisionC_InputReady),
    .OutputReady(wDivisionC_OutputReady)
  );

  reg [64-1:0] wAddSubA_Ax;reg [64-1:0] wAddSubA_Bx;
  wire [64-1:0] wAddSubA_Result;
  wire wAddSubA_Operation;
  reg wAddSubA_InputReady;
  wire wAddSubA_OutputReady;
  assign wAddSubA_Operation = ((iOperation == 16'b0_000010) || (iOperation == 16'b0_010_110) || (iOperation == 16'b0_100_100) || (iOperation == 16'b0_100_000))? 1 : 0;

  FixedAddSub
  AddSubChannel_A
  (
    .Clock(Clock),
    .Reset(Reset),
    .A(wAddSubA_Ax),
    .B(wAddSubA_Bx),
    .R(wAddSubA_Result),
    .iOperation(wAddSubA_Operation),
    .iInputReady(wAddSubA_InputReady),
    .OutputReady(wAddSubA_OutputReady)
  );


  always @(*) begin
    case(iOperation)
      16'b0_000001: wAddSubA_InputReady = iInputReady;
      16'b0_000010: wAddSubA_InputReady = iInputReady;
      16'b0_001_110, 16'b0_101_011, 16'b0_101_100, 16'b0_101_101: wAddSubA_InputReady = iInputReady;
      16'b0_100_100: wAddSubA_InputReady = iInputReady;
      16'b0_100_000: wAddSubA_InputReady = iInputReady;
      16'b0_000101: wAddSubA_InputReady = wMultiplicationOutputReadyA && wMultiplicationOutputReadyB;
      16'b0_010_111: wAddSubA_InputReady = wMultiplicationOutputReadyA && wMultiplicationOutputReadyB;
      16'b0_010_110: wAddSubA_InputReady = wMultiplicationOutputReadyA && wMultiplicationOutputReadyB;
      default: wAddSubA_InputReady = 1'b0;
    endcase
  end


  always @(*) begin
    case(iOperation)
      16'b0_000001: wAddSubA_Ax = (iChannel_Ax[31] == 1'b1)? { 32'hFFFFFFFF, iChannel_Ax } : { 32'b0, iChannel_Ax };
      16'b0_000010: wAddSubA_Ax = (iChannel_Ax[31] == 1'b1)? { 32'hFFFFFFFF, iChannel_Ax } : { 32'b0, iChannel_Ax };
      16'b0_001_110, 16'b0_101_011, 16'b0_101_100, 16'b0_101_101: wAddSubA_Ax = (iChannel_Ax[31] == 1'b1)? { 32'hFFFFFFFF, iChannel_Ax } : { 32'b0, iChannel_Ax };
      16'b0_100_100: wAddSubA_Ax = (iChannel_Ax[31] == 1'b1)? { 32'hFFFFFFFF, iChannel_Ax } : { 32'b0, iChannel_Ax };
      16'b0_100_000: wAddSubA_Ax = (iChannel_Bx[31] == 1'b1)? { 32'hFFFFFFFF, iChannel_Bx } : { 32'b0, iChannel_Bx };
      16'b0_000101: wAddSubA_Ax = wMultiplicationA_Result;
      16'b0_010_111: wAddSubA_Ax = wMultiplicationA_Result;
      16'b0_010_110: wAddSubA_Ax = wMultiplicationA_Result;
      default: wAddSubA_Ax = 64'b0;
    endcase
  end


  always @(*) begin
    case(iOperation)
      16'b0_000001: wAddSubA_Bx = (iChannel_Bx[31] == 1'b1)? { 32'hFFFFFFFF, iChannel_Bx } : { 32'b0, iChannel_Bx };
      16'b0_000010: wAddSubA_Bx = (iChannel_Bx[31] == 1'b1)? { 32'hFFFFFFFF, iChannel_Bx } : { 32'b0, iChannel_Bx };
      16'b0_001_110, 16'b0_101_011: wAddSubA_Bx = 64'd1 << 17;
      16'b0_101_100, 16'b0_101_101: wAddSubA_Bx = 64'd0;
      16'b0_100_100: wAddSubA_Bx = 64'd1 << 17;
      16'b0_100_000: wAddSubA_Bx = 64'd1 << 17;
      16'b0_000101: wAddSubA_Bx = wMultiplicationB_Result;
      16'b0_010_111: wAddSubA_Bx = wMultiplicationB_Result;
      16'b0_010_110: wAddSubA_Bx = wMultiplicationB_Result;
      default: wAddSubA_Bx = 64'b0;
    endcase
  end

  wire [64-1:0] wAddSubB_Result;
  wire wAddSubB_Operation;
  reg wAddSubB_InputReady;
  wire wAddSubB_OutputReady;
  reg [64-1:0] wAddSubB_Ay;reg [64-1:0] wAddSubB_By;
  assign wAddSubB_Operation = ((iOperation == 16'b0_000010) || (iOperation == 16'b0_010_110) || (iOperation == 16'b0_100_100) || (iOperation == 16'b0_100_000))? 1 : 0;

  FixedAddSub
  AddSubChannel_B
  (
    .Clock(Clock),
    .Reset(Reset),
    .A(wAddSubB_Ay),
    .B(wAddSubB_By),
    .R(wAddSubB_Result),
    .iOperation(wAddSubB_Operation),
    .iInputReady(wAddSubB_InputReady),
    .OutputReady(wAddSubB_OutputReady)
  );

  wire wMultiplicationOutputReadyC_Dealy1;

  FFD_POSEDGE_ASYNC_RESET
  #(
    1
  )
  FFwMultiplicationOutputReadyC_Dealy1
  (
    .Clock(Clock),
    .Clear(Reset),
    .D(wMultiplicationOutputReadyC),
    .Q(wMultiplicationOutputReadyC_Dealy1)
  );


  always @(*) begin
    case(iOperation)
      16'b0_000001: wAddSubB_InputReady = iInputReady;
      16'b0_000010: wAddSubB_InputReady = iInputReady;
      16'b0_001_110, 16'b0_101_011, 16'b0_101_100, 16'b0_101_101: wAddSubB_InputReady = iInputReady;
      16'b0_100_100: wAddSubB_InputReady = iInputReady;
      16'b0_100_000: wAddSubB_InputReady = iInputReady;
      16'b0_000101: wAddSubB_InputReady = wAddSubAOutputReady && wMultiplicationOutputReadyC_Dealy1;
      16'b0_010_111: wAddSubB_InputReady = wAddSubAOutputReady && wMultiplicationOutputReadyC_Dealy1;
      16'b0_010_110: wAddSubB_InputReady = wMultiplicationOutputReadyC && wMultiplicationOutputReadyD;
      default: wAddSubB_InputReady = 1'b0;
    endcase
  end


  always @(*) begin
    case(iOperation)
      16'b0_000001: wAddSubB_Ay = (iChannel_Ay[31] == 1'b1)? { 32'hFFFFFFFF, iChannel_Ay } : { 32'b0, iChannel_Ay };
      16'b0_000010: wAddSubB_Ay = (iChannel_Ay[31] == 1'b1)? { 32'hFFFFFFFF, iChannel_Ay } : { 32'b0, iChannel_Ay };
      16'b0_001_110, 16'b0_101_011, 16'b0_101_100, 16'b0_101_101: wAddSubB_Ay = (iChannel_Ay[31] == 1'b1)? { 32'hFFFFFFFF, iChannel_Ay } : { 32'b0, iChannel_Ay };
      16'b0_100_100: wAddSubB_Ay = (iChannel_Ay[31] == 1'b1)? { 32'hFFFFFFFF, iChannel_Ay } : { 32'b0, iChannel_Ay };
      16'b0_100_000: wAddSubB_Ay = (iChannel_By[31] == 1'b1)? { 32'hFFFFFFFF, iChannel_By } : { 32'b0, iChannel_By };
      16'b0_000101: wAddSubB_Ay = wAddSubA_Result;
      16'b0_010_111: wAddSubB_Ay = wAddSubA_Result;
      16'b0_010_110: wAddSubB_Ay = wMultiplicationC_Result;
      default: wAddSubB_Ay = 64'b0;
    endcase
  end


  always @(*) begin
    case(iOperation)
      16'b0_000001: wAddSubB_By = (iChannel_By[31] == 1'b1)? { 32'hFFFFFFFF, iChannel_By } : { 32'b0, iChannel_By };
      16'b0_000010: wAddSubB_By = (iChannel_By[31] == 1'b1)? { 32'hFFFFFFFF, iChannel_By } : { 32'b0, iChannel_By };
      16'b0_001_110, 16'b0_101_100: wAddSubB_By = 64'd1 << 17;
      16'b0_101_011, 16'b0_101_101: wAddSubB_By = 64'd0;
      16'b0_100_100: wAddSubB_By = 64'd1 << 17;
      16'b0_100_000: wAddSubB_By = 64'd1 << 17;
      16'b0_000101: wAddSubB_By = wMultiplicationC_Result;
      16'b0_010_111: wAddSubB_By = wMultiplicationC_Result;
      16'b0_010_110: wAddSubB_By = wMultiplicationD_Result;
      default: wAddSubB_By = 32'b0;
    endcase
  end

  wire [64-1:0] wAddSubC_Result;
  reg [64-1:0] wAddSubC_Az;reg [64-1:0] wAddSubC_Bz;
  wire wAddSubC_Operation;
  reg wAddSubC_InputReady;
  wire wAddSubC_OutputReady;
  reg [64-1:0] AddSubC_Az;reg [64-1:0] AddSubB_Bz;

  always @(*) begin
    case(iOperation)
      16'b0_010_110: wAddSubC_Az = wMultiplicationE_Result;
      16'b0_100_000: wAddSubC_Az = (iChannel_Bz[31] == 1'b1)? { 32'hFFFFFFFF, iChannel_Bz } : { 32'b0, iChannel_Bz };
      default: wAddSubC_Az = (iChannel_Az[31] == 1'b1)? { 32'hFFFFFFFF, iChannel_Az } : { 32'b0, iChannel_Az };
    endcase
  end


  always @(*) begin
    case(iOperation)
      16'b0_010_110: wAddSubC_Bz = wMultiplicationF_Result;
      16'b0_001_110, 16'b0_101_101: wAddSubC_Bz = 64'd1 << 17;
      16'b0_101_011, 16'b0_101_100: wAddSubC_Bz = 64'd0;
      16'b0_100_100: wAddSubC_Bz = 64'd1 << 17;
      16'b0_100_000: wAddSubC_Bz = 64'd1 << 17;
      default: wAddSubC_Bz = (iChannel_Bz[31] == 1'b1)? { 32'hFFFFFFFF, iChannel_Bz } : { 32'b0, iChannel_Bz };
    endcase
  end

  assign wAddSubC_Operation = ((iOperation == 16'b0_000010) || (iOperation == 16'b0_010_110) || (iOperation == 16'b0_100_100) || (iOperation == 16'b0_100_000))? 1 : 0;

  FixedAddSub
  AddSubChannel_C
  (
    .Clock(Clock),
    .Reset(Reset),
    .A(wAddSubC_Az),
    .B(wAddSubC_Bz),
    .R(wAddSubC_Result),
    .iOperation(wAddSubC_Operation),
    .iInputReady(wAddSubC_InputReady),
    .OutputReady(wAddSubC_OutputReady)
  );


  always @(*) begin
    case(iOperation)
      16'b0_010_110: wAddSubC_InputReady = wMultiplicationE_OutputReady && wMultiplicationF_OutputReady;
      default: wAddSubC_InputReady = iInputReady;
    endcase
  end

  wire [32-1:0] wSquareRoot_Result;
  wire wSquareRoot_OutputReady;

  FixedPointSquareRoot
  SQROOT1
  (
    .Clock(Clock),
    .Reset(Reset),
    .Operand(wAddSubB_Result),
    .iInputReady(wAddSubBOutputReady && (iOperation == 16'b0_000101)),
    .OutputReady(wSquareRoot_OutputReady),
    .Result(wSquareRoot_Result)
  );

  assign wModulus2N_ResultA = iChannel_Ax & wAddSubA_Result;
  assign wModulus2N_ResultB = iChannel_Ay & wAddSubB_Result;
  assign wModulus2N_ResultC = iChannel_Az & wAddSubC_Result;

  always @(*) begin
    case(iOperation)
      16'b1_000000: ResultA = iChannel_Ax;
      16'b0_000001: ResultA = (wAddSubA_Result[63] == 1'b1)? { 1'b1, wAddSubA_Result[30:0] } : { 1'b0, wAddSubA_Result[30:0] };
      16'b0_000010: ResultA = (wAddSubA_Result[63] == 1'b1)? { 1'b1, wAddSubA_Result[30:0] } : { 1'b0, wAddSubA_Result[30:0] };
      16'b0_010_110: ResultA = (wAddSubA_Result[63] == 1'b1)? { 1'b1, wAddSubA_Result[30:0] } : { 1'b0, wAddSubA_Result[30:0] };
      16'b0_000011: ResultA = wDivisionA_Result;
      16'b0_000100: ResultA = wMultiplicationA_Result[31:0];
      16'b0_101_000: ResultA = wMultiplicationA_Result[31:0];
      16'b0_010_111: ResultA = (wAddSubB_Result[63] == 1'b1)? { 1'b1, wAddSubB_Result[30:0] } : { 1'b0, wAddSubB_Result[30:0] };
      16'b0_000101: ResultA = wSquareRoot_Result;
      16'b0_001_111: ResultA = 32'b0;
      16'b0_000111: ResultA = iChannel_Ax;
      16'b0_110_000: ResultA = iTMEMReadData[95:64];
      16'b0_110_001: ResultA = { 16'b0, iCurrentIP };
      16'b1_000100: ResultA = wSwizzleOutputX;
      16'b0_101_001: ResultA = iChannel_Ax >> 17;
      16'b1_000001, 16'b1_011010: ResultA = iChannel_Ax;
      16'b1_000010: ResultA = iChannel_Bx;
      16'b1_000011: ResultA = iChannel_Bx;
      16'b0_001_110, 16'b0_101_011, 16'b0_101_100, 16'b0_101_101: ResultA = (wAddSubA_Result[63] == 1'b1)? { 1'b1, wAddSubA_Result[30:0] } : { 1'b0, wAddSubA_Result[30:0] };
      16'b0_100_100: ResultA = (wAddSubA_Result[63] == 1'b1)? { 1'b1, wAddSubA_Result[30:0] } : { 1'b0, wAddSubA_Result[30:0] };
      16'b0_100_000: ResultA = wModulus2N_ResultA;
      16'b0_100_001: ResultA = iChannel_Ax & (32'hFFFFFFFF >> 32 - 17);
      16'b0_011_111: ResultA = iChannel_Ax;
      16'b0_100_011: ResultA = ~iChannel_Ax + 1'b1;
      16'b0_100_101: ResultA = iChannel_Bx;
      default: begin
        ResultA = 32'b0;
      end
    endcase
  end


  always @(*) begin
    case(iOperation)
      16'b1_000000: ResultB = iChannel_Ax;
      16'b0_000001: ResultB = (wAddSubB_Result[63] == 1'b1)? { 1'b1, wAddSubB_Result[30:0] } : { 1'b0, wAddSubB_Result[30:0] };
      16'b0_000010: ResultB = (wAddSubB_Result[63] == 1'b1)? { 1'b1, wAddSubB_Result[30:0] } : { 1'b0, wAddSubB_Result[30:0] };
      16'b0_010_110: ResultB = (wAddSubB_Result[63] == 1'b1)? { 1'b1, wAddSubB_Result[30:0] } : { 1'b0, wAddSubB_Result[30:0] };
      16'b0_000011: ResultB = wDivisionB_Result;
      16'b0_000100: ResultB = wMultiplicationB_Result[31:0];
      16'b0_101_000: ResultB = wMultiplicationB_Result[31:0];
      16'b0_010_111: ResultB = (wAddSubB_Result[63] == 1'b1)? { 1'b1, wAddSubB_Result[30:0] } : { 1'b0, wAddSubB_Result[30:0] };
      16'b0_000101: ResultB = wSquareRoot_Result;
      16'b0_001_111: ResultB = 32'b0;
      16'b0_000111: ResultB = iChannel_Ay;
      16'b0_110_000: ResultB = iTMEMReadData[63:32];
      16'b0_110_001: ResultB = { 16'b0, iCurrentIP };
      16'b0_101_001: ResultB = iChannel_Ay >> 17;
      16'b1_000001, 16'b1_011010: ResultB = iChannel_By;
      16'b1_000010: ResultB = iChannel_Ax;
      16'b1_000011: ResultB = iChannel_By;
      16'b1_000100: ResultB = wSwizzleOutputY;
      16'b0_001_110, 16'b0_101_011, 16'b0_101_100, 16'b0_101_101: ResultB = (wAddSubB_Result[63] == 1'b1)? { 1'b1, wAddSubB_Result[30:0] } : { 1'b0, wAddSubB_Result[30:0] };
      16'b0_100_100: ResultB = (wAddSubB_Result[63] == 1'b1)? { 1'b1, wAddSubB_Result[30:0] } : { 1'b0, wAddSubB_Result[30:0] };
      16'b0_100_000: ResultB = wModulus2N_ResultB;
      16'b0_100_001: ResultB = iChannel_Ay & (32'hFFFFFFFF >> 32 - 17);
      16'b0_011_111: ResultB = iChannel_Ay;
      16'b0_100_011: ResultB = ~iChannel_Ay + 1'b1;
      16'b0_100_101: ResultB = iChannel_Ay;
      default: begin
        ResultB = 32'b0;
      end
    endcase
  end


  always @(*) begin
    case(iOperation)
      16'b1_000000: ResultC = iChannel_Ax;
      16'b0_000001: ResultC = (wAddSubC_Result[63] == 1'b1)? { 1'b1, wAddSubC_Result[30:0] } : { 1'b0, wAddSubC_Result[30:0] };
      16'b0_000010: ResultC = (wAddSubC_Result[63] == 1'b1)? { 1'b1, wAddSubC_Result[30:0] } : { 1'b0, wAddSubC_Result[30:0] };
      16'b0_010_110: ResultC = (wAddSubC_Result[63] == 1'b1)? { 1'b1, wAddSubC_Result[30:0] } : { 1'b0, wAddSubC_Result[30:0] };
      16'b0_000011: ResultC = wDivisionC_Result;
      16'b0_000100: ResultC = wMultiplicationC_Result[31:0];
      16'b0_101_000: ResultC = wMultiplicationC_Result[31:0];
      16'b0_010_111: ResultC = (wAddSubB_Result[63] == 1'b1)? { 1'b1, wAddSubB_Result[30:0] } : { 1'b0, wAddSubB_Result[30:0] };
      16'b0_000101: ResultC = wSquareRoot_Result;
      16'b0_001_111: ResultC = 32'b0;
      16'b0_000111: ResultC = iChannel_Az;
      16'b0_110_000: ResultC = iTMEMReadData[31:0];
      16'b0_110_001: ResultC = { 16'b0, iCurrentIP };
      16'b1_000100: ResultC = wSwizzleOutputZ;
      16'b0_101_001: ResultC = iChannel_Az >> 17;
      16'b1_000001, 16'b1_011010: ResultC = iChannel_Bz;
      16'b1_000010: ResultC = iChannel_Bz;
      16'b1_000011: ResultC = iChannel_Ax;
      16'b0_001_110, 16'b0_101_011, 16'b0_101_100, 16'b0_101_101: ResultC = (wAddSubC_Result[63] == 1'b1)? { 1'b1, wAddSubC_Result[30:0] } : { 1'b0, wAddSubC_Result[30:0] };
      16'b0_100_100: ResultC = (wAddSubC_Result[63] == 1'b1)? { 1'b1, wAddSubC_Result[30:0] } : { 1'b0, wAddSubC_Result[30:0] };
      16'b0_100_000: ResultC = wModulus2N_ResultC;
      16'b0_100_001: ResultC = iChannel_Az & (32'hFFFFFFFF >> 32 - 17);
      16'b0_011_111: ResultC = wMultiplicationA_Result[31:0];
      16'b0_100_011: ResultC = ~iChannel_Az + 1'b1;
      16'b0_100_101: ResultC = iChannel_Az;
      default: begin
        ResultC = 32'b0;
      end
    endcase
  end


  always @(*) begin
    case(iOperation)
      16'b1_011000, 16'b1_011001, 16'b1_011010: oBranchTaken = OutputReady;
      16'b0_001_000: oBranchTaken = wArithmeticComparison_Result;
      16'b0_010_000: oBranchTaken = wArithmeticComparison_Result;
      16'b0_011_000: oBranchTaken = wArithmeticComparison_Result;
      16'b0_001_001: oBranchTaken = wArithmeticComparison_Result;
      16'b0_010_001: oBranchTaken = wArithmeticComparison_Result;
      16'b0_011_001: oBranchTaken = wArithmeticComparison_Result;
      16'b0_001_010: oBranchTaken = wArithmeticComparison_Result;
      16'b0_010_010: oBranchTaken = wArithmeticComparison_Result;
      16'b0_011_010: oBranchTaken = wArithmeticComparison_Result;
      16'b0_001_011: oBranchTaken = wArithmeticComparison_Result;
      16'b0_010_011: oBranchTaken = wArithmeticComparison_Result;
      16'b0_011_011: oBranchTaken = wArithmeticComparison_Result;
      16'b0_001_100: oBranchTaken = wArithmeticComparison_Result;
      16'b0_010_100: oBranchTaken = wArithmeticComparison_Result;
      16'b0_011_100: oBranchTaken = wArithmeticComparison_Result;
      16'b0_001_101: oBranchTaken = wArithmeticComparison_Result;
      16'b0_010_101: oBranchTaken = wArithmeticComparison_Result;
      16'b0_011_101: oBranchTaken = wArithmeticComparison_Result;
      default: oBranchTaken = 0;
    endcase
  end


  always @(*) begin
    case(iOperation)
      16'b1_011000, 16'b1_011001, 16'b1_011010, 16'b0_001_000, 16'b0_010_000, 16'b0_011_000, 16'b0_001_001, 16'b0_010_001, 16'b0_011_001, 16'b0_001_010, 16'b0_010_010, 16'b0_011_010, 16'b0_001_011, 16'b0_010_011, 16'b0_011_011, 16'b0_001_100, 16'b0_010_100, 16'b0_011_100: oBranchNotTaken = !oBranchTaken && OutputReady;
      16'b0_001_101: oBranchNotTaken = !oBranchTaken && OutputReady;
      16'b0_010_101: oBranchNotTaken = !oBranchTaken && OutputReady;
      16'b0_011_101: oBranchNotTaken = !oBranchTaken && OutputReady;
      default: oBranchNotTaken = 0;
    endcase
  end

  wire wDivisionOutputReadyA;wire wDivisionOutputReadyB;wire wDivisionOutputReadyC;
  wire wDivisionOutputReady;
  assign wAddSubAOutputReady = wAddSubA_OutputReady;
  assign wAddSubBOutputReady = wAddSubB_OutputReady;
  assign wAddSubCOutputReady = wAddSubC_OutputReady;

  FFT1
  FFT_DivisionA
  (
    .D(1'b1),
    .Clock(wDivisionA_OutputReady),
    .Reset(iInputReady),
    .Q(wDivisionOutputReadyA)
  );


  FFT1
  FFT_DivisionB
  (
    .D(1'b1),
    .Clock(wDivisionB_OutputReady),
    .Reset(iInputReady),
    .Q(wDivisionOutputReadyB)
  );


  FFT1
  FFT_DivisionC
  (
    .D(1'b1),
    .Clock(wDivisionC_OutputReady),
    .Reset(iInputReady),
    .Q(wDivisionOutputReadyC)
  );

  assign wDivisionOutputReady = wDivisionOutputReadyA && wDivisionOutputReadyB && wDivisionOutputReadyC;
  assign wMultiplicationOutputReadyA = wMultiplicationA_OutputReady;
  assign wMultiplicationOutputReadyB = wMultiplicationB_OutputReady;
  assign wMultiplicationOutputReadyC = wMultiplicationC_OutputReady;
  assign wMultiplicationOutputReadyD = wMultiplicationD_OutputReady;
  assign wMultiplicationOutputReady = wMultiplicationOutputReadyA && wMultiplicationOutputReadyB && wMultiplicationOutputReadyC;
  wire wSquareRootOutputReady;

  FFT1
  FFT_Sqrt
  (
    .D(1'b1),
    .Clock(wSquareRoot_OutputReady),
    .Reset(iInputReady),
    .Q(wSquareRootOutputReady)
  );

  wire wOutputDelay1Cycle;wire wOutputDelay2Cycle;wire wOutputDelay3Cycle;

  FFD_POSEDGE_ASYNC_RESET
  #(
    1
  )
  FFOutputReadyDelay2
  (
    .Clock(Clock),
    .Clear(Reset),
    .D(iInputReady),
    .Q(wOutputDelay1Cycle)
  );


  FFD_POSEDGE_ASYNC_RESET
  #(
    1
  )
  FFOutputReadyDelay22
  (
    .Clock(Clock),
    .Clear(Reset),
    .D(wOutputDelay1Cycle),
    .Q(wOutputDelay2Cycle)
  );


  FFD_POSEDGE_ASYNC_RESET
  #(
    1
  )
  FFOutputReadyDelay222
  (
    .Clock(Clock && (wOperation == 16'b0_101_111)),
    .Clear(Reset),
    .D(wOutputDelay2Cycle),
    .Q(wOutputDelay3Cycle)
  );


  FFD_POSEDGE_SYNCRONOUS_RESET
  #(
    16
  )
  SourceZ2
  (
    .Clock(Clock),
    .Reset(Reset),
    .Enable(iInputReady),
    .D(iOperation),
    .Q(wOperation)
  );


  always @(*) begin
    case(wOperation)
      16'b0_101_001: OutputReady = wOutputDelay1Cycle;
      16'b1_000000: OutputReady = wOutputDelay1Cycle;
      16'b0_000000: OutputReady = wOutputDelay1Cycle;
      16'b0_100_001: OutputReady = wOutputDelay1Cycle;
      16'b0_100_011: OutputReady = wOutputDelay1Cycle;
      16'b0_101_111: OutputReady = wOutputDelay3Cycle;
      16'b0_110_000: OutputReady = wTMReadOutputReady;
      16'b0_000001, 16'b0_001_110, 16'b0_101_011, 16'b0_101_100, 16'b0_101_101: OutputReady = wAddSubAOutputReady && wAddSubBOutputReady && wAddSubCOutputReady;
      16'b0_000010, 16'b0_100_100: OutputReady = wAddSubAOutputReady && wAddSubBOutputReady && wAddSubCOutputReady;
      16'b0_000011: OutputReady = wDivisionOutputReady;
      16'b0_000100, 16'b0_101_000: OutputReady = wMultiplicationOutputReady;
      16'b0_011_111: OutputReady = wMultiplicationOutputReadyA;
      16'b0_010_111: OutputReady = wAddSubBOutputReady;
      16'b0_010_110: OutputReady = wAddSubAOutputReady && wAddSubBOutputReady && wAddSubCOutputReady;
      16'b0_000101: OutputReady = wSquareRootOutputReady;
      16'b0_001_111: OutputReady = wOutputDelay1Cycle;
      16'b0_000111: OutputReady = wOutputDelay1Cycle;
      16'b1_000100: OutputReady = wOutputDelay1Cycle;
      16'b1_000001, 16'b1_000010, 16'b1_000011, 16'b1_011000, 16'b0_110_001, 16'b1_011001, 16'b1_011010: OutputReady = wOutputDelay1Cycle;
      16'b0_001_000, 16'b0_010_000, 16'b0_011_000: OutputReady = ArithmeticComparison_OutputReady;
      16'b0_001_001, 16'b0_010_001, 16'b0_011_001: OutputReady = ArithmeticComparison_OutputReady;
      16'b0_001_010, 16'b0_010_010, 16'b0_011_010: OutputReady = ArithmeticComparison_OutputReady;
      16'b0_001_011, 16'b0_010_011, 16'b0_011_011: OutputReady = ArithmeticComparison_OutputReady;
      16'b0_001_100, 16'b0_010_100, 16'b0_011_100: OutputReady = ArithmeticComparison_OutputReady;
      16'b0_001_101, 16'b0_010_101, 16'b0_011_101: OutputReady = ArithmeticComparison_OutputReady;
      16'b0_100_000: OutputReady = wAddSubAOutputReady && wAddSubBOutputReady && wAddSubCOutputReady;
      16'b0_100_101: OutputReady = wOutputDelay1Cycle;
      default: begin
        OutputReady = 32'b0;
      end
    endcase
  end


endmodule

