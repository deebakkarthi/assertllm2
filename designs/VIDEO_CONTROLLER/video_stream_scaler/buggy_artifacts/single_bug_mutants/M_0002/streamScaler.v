

module streamScaler #
(
  parameter DATA_WIDTH = 8,
  parameter CHANNELS = 1,
  parameter DISCARD_CNT_WIDTH = 8,
  parameter INPUT_X_RES_WIDTH = 11,
  parameter INPUT_Y_RES_WIDTH = 11,
  parameter OUTPUT_X_RES_WIDTH = 11,
  parameter OUTPUT_Y_RES_WIDTH = 11,
  parameter FRACTION_BITS = 8,
  parameter SCALE_INT_BITS = 4,
  parameter SCALE_FRAC_BITS = 14,
  parameter BUFFER_SIZE = 4,
  parameter COEFF_WIDTH = FRACTION_BITS + 1,
  parameter SCALE_BITS = SCALE_INT_BITS + SCALE_FRAC_BITS,
  parameter BUFFER_SIZE_WIDTH = (BUFFER_SIZE + 1 <= 2)? 1 : 
  (BUFFER_SIZE + 1 <= 4)? 2 : 
  (BUFFER_SIZE + 1 <= 8)? 3 : 
  (BUFFER_SIZE + 1 <= 16)? 4 : 
  (BUFFER_SIZE + 1 <= 32)? 5 : 
  (BUFFER_SIZE + 1 <= 64)? 6 : 7
)
(
  input wire clk,
  input wire rst,
  input wire [DATA_WIDTH*CHANNELS-1:0] dIn,
  input wire dInValid,
  output wire nextDin,
  input wire start,
  output reg [DATA_WIDTH*CHANNELS-1:0] dOut,
  output reg dOutValid,
  input wire nextDout,
  input wire [DISCARD_CNT_WIDTH-1:0] inputDiscardCnt,
  input wire [INPUT_X_RES_WIDTH-1:0] inputXRes,
  input wire [INPUT_Y_RES_WIDTH-1:0] inputYRes,
  input wire [OUTPUT_X_RES_WIDTH-1:0] outputXRes,
  input wire [OUTPUT_Y_RES_WIDTH-1:0] outputYRes,
  input wire [SCALE_BITS-1:0] xScale,
  input wire [SCALE_BITS-1:0] yScale,
  input wire [OUTPUT_X_RES_WIDTH-1+SCALE_FRAC_BITS:0] leftOffset,
  input wire [SCALE_FRAC_BITS-1:0] topFracOffset,
  input wire nearestNeighbor
);

  reg advanceRead1;
  reg advanceRead2;
  wire [DATA_WIDTH*CHANNELS-1:0] readData00;
  wire [DATA_WIDTH*CHANNELS-1:0] readData01;
  wire [DATA_WIDTH*CHANNELS-1:0] readData10;
  wire [DATA_WIDTH*CHANNELS-1:0] readData11;
  reg [DATA_WIDTH*CHANNELS-1:0] readData00Reg;
  reg [DATA_WIDTH*CHANNELS-1:0] readData01Reg;
  reg [DATA_WIDTH*CHANNELS-1:0] readData10Reg;
  reg [DATA_WIDTH*CHANNELS-1:0] readData11Reg;
  wire [INPUT_X_RES_WIDTH-1:0] readAddress;
  reg readyForRead;
  reg [OUTPUT_Y_RES_WIDTH-1:0] outputLine;
  reg [OUTPUT_X_RES_WIDTH-1:0] outputColumn;
  reg [INPUT_X_RES_WIDTH-1+SCALE_FRAC_BITS:0] xScaleAmount;
  reg [INPUT_Y_RES_WIDTH-1+SCALE_FRAC_BITS:0] yScaleAmount;
  reg [INPUT_Y_RES_WIDTH-1+SCALE_FRAC_BITS:0] yScaleAmountNext;
  wire [BUFFER_SIZE_WIDTH-1:0] fillCount;
  reg lineSwitchOutputDisable;
  reg dOutValidInt;
  reg [COEFF_WIDTH-1:0] xBlend;
  wire [COEFF_WIDTH-1:0] yBlend;assign yBlend = { 1'b0, yScaleAmount[SCALE_FRAC_BITS-1:SCALE_FRAC_BITS-FRACTION_BITS] };
  wire [INPUT_X_RES_WIDTH-1:0] xPixLow;assign xPixLow = xScaleAmount[INPUT_X_RES_WIDTH-1+SCALE_FRAC_BITS:SCALE_FRAC_BITS];
  wire [INPUT_Y_RES_WIDTH-1:0] yPixLow;assign yPixLow = yScaleAmount[INPUT_Y_RES_WIDTH-1+SCALE_FRAC_BITS:SCALE_FRAC_BITS];
  wire [INPUT_Y_RES_WIDTH-1:0] yPixLowNext;assign yPixLowNext = yScaleAmountNext[INPUT_Y_RES_WIDTH-1+SCALE_FRAC_BITS:SCALE_FRAC_BITS];
  wire allDataWritten;
  reg readState;
  parameter RS_START = 0;
  parameter RS_READ_LINE = 1;

  always @(posedge clk or posedge rst or posedge start) begin
    if(rst | start) begin
      outputLine <= 0;
      outputColumn <= 0;
      xScaleAmount <= 0;
      yScaleAmount <= 0;
      readState <= RS_START;
      dOutValidInt <= 0;
      lineSwitchOutputDisable <= 0;
      advanceRead1 <= 0;
      advanceRead2 <= 0;
      yScaleAmountNext <= 0;
    end else begin
      case(readState)
        RS_START: begin
          xScaleAmount <= leftOffset;
          yScaleAmount <= { { INPUT_Y_RES_WIDTH{ 1'b0 } }, topFracOffset };
          if(readyForRead) begin
            readState <= RS_READ_LINE;
            dOutValidInt <= 1;
          end 
        end
        RS_READ_LINE: begin
          if(nextDout && dOutValidInt) begin
            if(outputColumn == outputXRes) begin
              if(yPixLowNext == yPixLow + 1) begin
                advanceRead1 <= 1;
                if(fillCount < 3) dOutValidInt <= 0; 
              end else if(yPixLowNext > yPixLow + 1) begin
                advanceRead2 <= 1;
                if(fillCount < 4) dOutValidInt <= 0; 
              end 
              outputColumn <= 0;
              xScaleAmount <= leftOffset;
              outputLine <= outputLine + 1;
              yScaleAmount <= yScaleAmountNext;
              lineSwitchOutputDisable <= 1;
            end else begin
              if(lineSwitchOutputDisable == 0) begin
                outputColumn <= outputColumn + 1;
                xScaleAmount <= (outputColumn + 1) * xScale + leftOffset;
              end 
              advanceRead1 <= 0;
              advanceRead2 <= 0;
              lineSwitchOutputDisable <= 0;
            end
          end else begin
            advanceRead1 <= 0;
            advanceRead2 <= 0;
            lineSwitchOutputDisable <= 0;
          end
          if((fillCount >= 2) && (dOutValidInt == 0) || allDataWritten) begin
            if(!advanceRead1 && !advanceRead2) begin
              dOutValidInt <= 1;
              lineSwitchOutputDisable <= 0;
            end 
          end 
        end
      endcase
      yScaleAmountNext <= (outputLine + 1) * yScale + { { OUTPUT_Y_RES_WIDTH{ 1'b0 } }, topFracOffset };
    end
  end

  assign readAddress = xPixLow;
  reg dOutValid_1;
  reg dOutValid_2;
  reg dOutValid_3;

  always @(posedge clk or posedge rst) begin
    if(rst) begin
      dOutValid_1 <= 0;
      dOutValid_2 <= 0;
      dOutValid_3 <= 0;
      dOutValid <= 0;
    end else begin
      dOutValid_1 <= nextDout && dOutValidInt && !lineSwitchOutputDisable;
      dOutValid_2 <= dOutValid_1;
      dOutValid_3 <= dOutValid_2;
      dOutValid <= dOutValid_3;
    end
  end

  reg [COEFF_WIDTH-1:0] coeff00;
  reg [COEFF_WIDTH-1:0] coeff01;
  reg [COEFF_WIDTH-1:0] coeff10;
  reg [COEFF_WIDTH-1:0] coeff11;
  wire [COEFF_WIDTH-1:0] coeffOne;assign coeffOne = { 1'b1, { COEFF_WIDTH - 1{ 1'b0 } } };
  wire [COEFF_WIDTH-1:0] coeffHalf;assign coeffHalf = { 2'b01, { COEFF_WIDTH - 2{ 1'b0 } } };
  wire [COEFF_WIDTH-1:0] preCoeff00;assign preCoeff00 = ((coeffOne - xBlend) * (coeffOne - yBlend) + (coeffHalf - 1) >> FRACTION_BITS) & { { COEFF_WIDTH{ 1'b0 } }, { COEFF_WIDTH{ 1'b1 } } };
  wire [COEFF_WIDTH-1:0] preCoeff01;assign preCoeff01 = (xBlend * (coeffOne - yBlend) + (coeffHalf - 1) >> FRACTION_BITS) & { { COEFF_WIDTH{ 1'b0 } }, { COEFF_WIDTH{ 1'b1 } } };
  wire [COEFF_WIDTH-1:0] preCoeff10;assign preCoeff10 = ((coeffOne - xBlend) * yBlend + (coeffHalf - 1) >> FRACTION_BITS) & { { COEFF_WIDTH{ 1'b0 } }, { COEFF_WIDTH{ 1'b1 } } };

  always @(posedge clk or posedge rst) begin
    if(rst) begin
      coeff00 <= 0;
      coeff01 <= 0;
      coeff10 <= 0;
      coeff11 <= 0;
      xBlend <= 0;
    end else begin
      xBlend <= { 1'b0, xScaleAmount[SCALE_FRAC_BITS-1:SCALE_FRAC_BITS-FRACTION_BITS] };
      if(nearestNeighbor == 1'b0) begin
        coeff00 <= preCoeff00;
        coeff01 <= preCoeff01;
        coeff10 <= preCoeff10;
        coeff11 <= (xBlend * yBlend + (coeffHalf - 1) >> FRACTION_BITS) & { { COEFF_WIDTH{ 1'b0 } }, { COEFF_WIDTH{ 1'b1 } } };
      end else begin
        coeff00 <= ((xBlend < coeffHalf) && (yBlend < coeffHalf))? coeffOne : { COEFF_WIDTH{ 1'b0 } };
        coeff01 <= ((xBlend >= coeffHalf) && (yBlend < coeffHalf))? coeffOne : { COEFF_WIDTH{ 1'b0 } };
        coeff10 <= ((xBlend < coeffHalf) && (yBlend >= coeffHalf))? coeffOne : { COEFF_WIDTH{ 1'b0 } };
        coeff11 <= ((xBlend >= coeffHalf) && (yBlend >= coeffHalf))? coeffOne : { COEFF_WIDTH{ 1'b0 } };
      end
    end
  end

  reg [(DATA_WIDTH+COEFF_WIDTH)*CHANNELS-1:0] product00;reg [(DATA_WIDTH+COEFF_WIDTH)*CHANNELS-1:0] product01;reg [(DATA_WIDTH+COEFF_WIDTH)*CHANNELS-1:0] product10;reg [(DATA_WIDTH+COEFF_WIDTH)*CHANNELS-1:0] product11;

  generate genvar channel;for(channel=0; channel<CHANNELS; channel=channel+1) begin : blend_mult_generate

    always @(posedge clk or posedge rst) begin
      if(rst) begin
        product00[(DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1:(DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
        product01[(DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1:(DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
        product10[(DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1:(DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
        product11[(DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1:(DATA_WIDTH+COEFF_WIDTH)*channel] <= 0;
        readData00Reg[DATA_WIDTH*(channel+1)-1:DATA_WIDTH*channel] <= 0;
        readData01Reg[DATA_WIDTH*(channel+1)-1:DATA_WIDTH*channel] <= 0;
        readData10Reg[DATA_WIDTH*(channel+1)-1:DATA_WIDTH*channel] <= 0;
        readData11Reg[DATA_WIDTH*(channel+1)-1:DATA_WIDTH*channel] <= 0;
        dOut[DATA_WIDTH*(channel+1)-1:DATA_WIDTH*channel] <= 0;
      end else begin
        readData00Reg[DATA_WIDTH*(channel+1)-1:DATA_WIDTH*channel] <= readData00[DATA_WIDTH*(channel+1)-1:DATA_WIDTH*channel];
        readData01Reg[DATA_WIDTH*(channel+1)-1:DATA_WIDTH*channel] <= readData01[DATA_WIDTH*(channel+1)-1:DATA_WIDTH*channel];
        readData10Reg[DATA_WIDTH*(channel+1)-1:DATA_WIDTH*channel] <= readData10[DATA_WIDTH*(channel+1)-1:DATA_WIDTH*channel];
        readData11Reg[DATA_WIDTH*(channel+1)-1:DATA_WIDTH*channel] <= readData11[DATA_WIDTH*(channel+1)-1:DATA_WIDTH*channel];
        product00[(DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1:(DATA_WIDTH+COEFF_WIDTH)*channel] <= readData00Reg[DATA_WIDTH*(channel+1)-1:DATA_WIDTH*channel] * coeff00;
        product01[(DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1:(DATA_WIDTH+COEFF_WIDTH)*channel] <= readData01Reg[DATA_WIDTH*(channel+1)-1:DATA_WIDTH*channel] * coeff01;
        product10[(DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1:(DATA_WIDTH+COEFF_WIDTH)*channel] <= readData10Reg[DATA_WIDTH*(channel+1)-1:DATA_WIDTH*channel] * coeff10;
        product11[(DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1:(DATA_WIDTH+COEFF_WIDTH)*channel] <= readData11Reg[DATA_WIDTH*(channel+1)-1:DATA_WIDTH*channel] * coeff11;
        dOut[DATA_WIDTH*(channel+1)-1:DATA_WIDTH*channel] <= (product00[(DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1:(DATA_WIDTH+COEFF_WIDTH)*channel] + product01[(DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1:(DATA_WIDTH+COEFF_WIDTH)*channel] + product10[(DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1:(DATA_WIDTH+COEFF_WIDTH)*channel] + product11[(DATA_WIDTH+COEFF_WIDTH)*(channel+1)-1:(DATA_WIDTH+COEFF_WIDTH)*channel] >> FRACTION_BITS) & { { COEFF_WIDTH{ 1'b0 } }, { DATA_WIDTH{ 1'b1 } } };
      end
    end

  end
  endgenerate

  reg [INPUT_Y_RES_WIDTH-1:0] writeNextValidLine;
  reg [INPUT_Y_RES_WIDTH-1:0] writeNextPlusOne;
  reg [INPUT_Y_RES_WIDTH-1:0] writeRowCount;
  reg [OUTPUT_Y_RES_WIDTH-1:0] writeOutputLine;
  reg getNextPlusOne;

  always @(posedge clk or posedge rst or posedge start) begin
    if(rst | start) begin
      writeOutputLine <= 0;
      writeNextValidLine <= 0;
      writeNextPlusOne <= 1;
      getNextPlusOne <= 1;
    end else begin
      if(writeRowCount >= writeNextValidLine) begin
        if(getNextPlusOne) begin
          writeNextPlusOne <= writeNextValidLine + 1;
        end 
        getNextPlusOne <= 0;
        writeOutputLine <= writeOutputLine + 1;
        writeNextValidLine <= (writeOutputLine * yScale + { { OUTPUT_Y_RES_WIDTH + SCALE_INT_BITS{ 1'b0 } }, topFracOffset } >> SCALE_FRAC_BITS) & { { SCALE_BITS{ 1'b0 } }, { OUTPUT_Y_RES_WIDTH{ 1'b1 } } };
      end else begin
        getNextPlusOne <= 1;
      end
    end
  end

  reg discardInput;
  reg [DISCARD_CNT_WIDTH-1:0] discardCountReg;
  wire advanceWrite;
  reg [1:0] writeState;
  reg [INPUT_X_RES_WIDTH-1:0] writeColCount;
  reg enableNextDin;
  reg forceRead;
  parameter WS_START = 0;
  parameter WS_DISCARD = 1;
  parameter WS_READ = 2;
  parameter WS_DONE = 3;

  always @(posedge clk or posedge rst or posedge start) begin
    if(rst | start) begin
      writeState <= WS_START;
      enableNextDin <= 0;
      discardInput <= 0;
      readyForRead <= 0;
      writeRowCount <= 0;
      writeColCount <= 0;
      discardCountReg <= 0;
      forceRead <= 0;
    end else begin
      case(writeState)
        WS_START: begin
          discardCountReg <= inputDiscardCnt;
          if(inputDiscardCnt > 0) begin
            discardInput <= 1;
            enableNextDin <= 1;
            writeState <= WS_DISCARD;
          end else begin
            discardInput <= 0;
            enableNextDin <= 1;
            writeState <= WS_READ;
          end
          discardInput <= (inputDiscardCnt > 0)? 1'b1 : 1'b0;
        end
        WS_DISCARD: begin
          if(dInValid) begin
            discardCountReg <= discardCountReg - 1;
            if(discardCountReg - 1 == 0) begin
              discardInput <= 0;
              writeState <= WS_READ;
            end 
          end 
        end
        WS_READ: begin
          if(dInValid & nextDin) begin
            if(writeColCount == inputXRes) begin
              if((writeNextValidLine == writeRowCount + 1) || (writeNextPlusOne == writeRowCount + 1)) begin
                discardInput <= 0;
              end else begin
                discardInput <= 1;
              end
              if(writeRowCount[1]) readyForRead <= 1; 
              if(writeRowCount == inputYRes) begin
                writeState <= WS_DONE;
                enableNextDin <= 0;
                forceRead <= 1;
              end 
              writeColCount <= 0;
              writeRowCount <= writeRowCount + 1;
            end else begin
              writeColCount <= writeColCount + 1;
            end
          end 
        end
        WS_DONE: begin
        end
      endcase
    end
  end

  assign advanceWrite = (writeColCount == inputXRes) & (discardInput == 0) & dInValid & nextDin;
  assign allDataWritten = writeState == WS_DONE;
  assign nextDin = (fillCount < BUFFER_SIZE) & enableNextDin;

  ramFifo
  #(
    .DATA_WIDTH(DATA_WIDTH * CHANNELS),
    .ADDRESS_WIDTH(INPUT_X_RES_WIDTH),
    .BUFFER_SIZE(BUFFER_SIZE)
  )
  ramRB
  (
    .clk(clk),
    .rst(rst | start),
    .advanceRead1(advanceRead1),
    .advanceRead2(forceRead),
    .advanceWrite(advanceWrite),
    .forceRead(advanceRead2),
    .writeData(dIn),
    .writeAddress(writeColCount),
    .writeEnable(dInValid & nextDin & enableNextDin & ~discardInput),
    .fillCount(fillCount),
    .readData00(readData00),
    .readData01(readData01),
    .readData10(readData10),
    .readData11(readData11),
    .readAddress(readAddress)
  );


endmodule



module ramFifo #
(
  parameter DATA_WIDTH = 8,
  parameter ADDRESS_WIDTH = 8,
  parameter BUFFER_SIZE = 2,
  parameter BUFFER_SIZE_WIDTH = (BUFFER_SIZE + 1 <= 2)? 1 : 
  (BUFFER_SIZE + 1 <= 4)? 2 : 
  (BUFFER_SIZE + 1 <= 8)? 3 : 
  (BUFFER_SIZE + 1 <= 16)? 4 : 
  (BUFFER_SIZE + 1 <= 32)? 5 : 
  (BUFFER_SIZE + 1 <= 64)? 6 : 7
)
(
  input wire clk,
  input wire rst,
  input wire advanceRead1,
  input wire advanceRead2,
  input wire advanceWrite,
  input wire forceRead,
  input wire [DATA_WIDTH-1:0] writeData,
  input wire [ADDRESS_WIDTH-1:0] writeAddress,
  input wire writeEnable,
  output reg [BUFFER_SIZE_WIDTH-1:0] fillCount,
  output wire [DATA_WIDTH-1:0] readData00,
  output wire [DATA_WIDTH-1:0] readData01,
  output wire [DATA_WIDTH-1:0] readData10,
  output wire [DATA_WIDTH-1:0] readData11,
  input wire [ADDRESS_WIDTH-1:0] readAddress
);

  reg [BUFFER_SIZE-1:0] writeSelect;
  reg [BUFFER_SIZE-1:0] readSelect;

  always @(posedge clk or posedge rst) begin
    if(rst) readSelect <= 1; 
    else begin
      if(advanceRead1) begin
        readSelect <= { readSelect[BUFFER_SIZE-2:0], readSelect[BUFFER_SIZE - 1] };
      end else if(advanceRead2) begin
        readSelect <= { readSelect[BUFFER_SIZE-3:0], readSelect[BUFFER_SIZE-1:BUFFER_SIZE-2] };
      end 
    end
  end


  always @(posedge clk or posedge rst) begin
    if(rst) writeSelect <= 1; 
    else begin
      if(advanceWrite) begin
        writeSelect <= { writeSelect[BUFFER_SIZE-2:0], writeSelect[BUFFER_SIZE - 1] };
      end 
    end
  end

  wire [DATA_WIDTH-1:0] ramDataOutA [2**BUFFER_SIZE-1:0];
  wire [DATA_WIDTH-1:0] ramDataOutB [2**BUFFER_SIZE-1:0];

  generate genvar i;for(i=0; i<BUFFER_SIZE; i=i+1) begin : ram_generate

    ramDualPort
    #(
      .DATA_WIDTH(DATA_WIDTH),
      .ADDRESS_WIDTH(ADDRESS_WIDTH)
    )
    ram_inst_i
    (
      .clk(clk),
      .addrA(((writeSelect[i] == 1'b1) && !forceRead && writeEnable)? writeAddress : readAddress),
      .dataA(writeData),
      .weA(((writeSelect[i] == 1'b1) && !forceRead)? writeEnable : 1'b0),
      .qA(ramDataOutA[2 ** i]),
      .addrB(readAddress + 1),
      .dataB(0),
      .weB(1'b0),
      .qB(ramDataOutB[2 ** i])
    );

  end
  endgenerate

  wire [BUFFER_SIZE-1:0] readSelect0;assign readSelect0 = readSelect;
  wire [BUFFER_SIZE-1:0] readSelect1;assign readSelect1 = (readSelect << 1) | readSelect[BUFFER_SIZE - 1];
  assign readData00 = ramDataOutA[readSelect0];
  assign readData10 = ramDataOutA[readSelect1];
  assign readData01 = ramDataOutB[readSelect0];
  assign readData11 = ramDataOutB[readSelect1];

  always @(posedge clk or posedge rst) begin
    if(rst) begin
      fillCount <= 0;
    end else begin
      if(advanceWrite) begin
        if(advanceRead1) fillCount <= fillCount; 
        else if(advanceRead2) fillCount <= fillCount - 1; 
        else fillCount <= fillCount + 1;
      end else begin
        if(advanceRead1) fillCount <= fillCount - 1; 
        else if(advanceRead2) fillCount <= fillCount - 2; 
        else fillCount <= fillCount;
      end
    end
  end


endmodule



module ramDualPort #
(
  parameter DATA_WIDTH = 8,
  parameter ADDRESS_WIDTH = 8
)
(
  input wire [DATA_WIDTH-1:0] dataA,
  input [DATA_WIDTH-1:0] dataB,
  input wire [ADDRESS_WIDTH-1:0] addrA,
  input [ADDRESS_WIDTH-1:0] addrB,
  input wire weA,
  input weB,
  input clk,
  output reg [DATA_WIDTH-1:0] qA,
  output reg [DATA_WIDTH-1:0] qB
);

  reg [DATA_WIDTH-1:0] ram [2**ADDRESS_WIDTH-1:0];

  always @(posedge clk) begin
    if(weA) begin
      ram[addrA] <= dataA;
      qA <= dataA;
    end else begin
      qA <= ram[addrA];
    end
  end


  always @(posedge clk) begin
    if(weB) begin
      ram[addrB] <= dataB;
      qB <= dataB;
    end else begin
      qB <= ram[addrB];
    end
  end


endmodule

