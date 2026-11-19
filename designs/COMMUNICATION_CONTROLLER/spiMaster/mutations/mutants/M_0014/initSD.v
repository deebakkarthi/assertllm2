

module initSD
(
  checkSumByte,
  clk,
  cmdByte,
  dataByte1,
  dataByte2,
  dataByte3,
  dataByte4,
  initError,
  respByte,
  respTout,
  rst,
  rxDataRdy,
  rxDataRdyClr,
  SDInitRdy,
  SDInitReq,
  sendCmdRdy,
  sendCmdReq,
  spiClkDelayIn,
  spiClkDelayOut,
  spiCS_n,
  txDataEmpty,
  txDataFull,
  txDataOut,
  txDataWen
);

  input clk;
  input [7:0] respByte;
  input respTout;
  input rst;
  input rxDataRdy;
  input SDInitReq;
  input sendCmdRdy;
  input [7:0] spiClkDelayIn;
  input txDataEmpty;
  input txDataFull;
  output [7:0] checkSumByte;
  output [7:0] cmdByte;
  output [7:0] dataByte1;
  output [7:0] dataByte2;
  output [7:0] dataByte3;
  output [7:0] dataByte4;
  output [1:0] initError;
  output rxDataRdyClr;
  output SDInitRdy;
  output sendCmdReq;
  output [7:0] spiClkDelayOut;
  output spiCS_n;
  output [7:0] txDataOut;
  output txDataWen;
  reg [7:0] checkSumByte;reg [7:0] next_checkSumByte;
  wire clk;
  reg [7:0] cmdByte;reg [7:0] next_cmdByte;
  reg [7:0] dataByte1;reg [7:0] next_dataByte1;
  reg [7:0] dataByte2;reg [7:0] next_dataByte2;
  reg [7:0] dataByte3;reg [7:0] next_dataByte3;
  reg [7:0] dataByte4;reg [7:0] next_dataByte4;
  reg [1:0] initError;reg [1:0] next_initError;
  wire [7:0] respByte;
  wire respTout;
  wire rst;
  wire rxDataRdy;
  reg rxDataRdyClr;reg next_rxDataRdyClr;
  reg SDInitRdy;reg next_SDInitRdy;
  wire SDInitReq;
  wire sendCmdRdy;
  reg sendCmdReq;reg next_sendCmdReq;
  wire [7:0] spiClkDelayIn;
  reg [7:0] spiClkDelayOut;reg [7:0] next_spiClkDelayOut;
  reg spiCS_n;reg next_spiCS_n;
  wire txDataEmpty;
  wire txDataFull;
  reg [7:0] txDataOut;reg [7:0] next_txDataOut;
  reg txDataWen;reg next_txDataWen;
  reg [9:0] delCnt1;reg [9:0] next_delCnt1;
  reg [7:0] delCnt2;reg [7:0] next_delCnt2;
  reg [7:0] loopCnt;reg [7:0] next_loopCnt;
  reg [3:0] CurrState_initSDSt;reg [3:0] NextState_initSDSt;

  always @(spiClkDelayIn or SDInitReq or txDataFull or loopCnt or sendCmdRdy or respTout or respByte or delCnt1 or delCnt2 or txDataEmpty or spiClkDelayOut or SDInitRdy or spiCS_n or initError or txDataOut or txDataWen or cmdByte or dataByte1 or dataByte2 or dataByte3 or dataByte4 or checkSumByte or sendCmdReq or rxDataRdyClr or CurrState_initSDSt) begin
    NextState_initSDSt <= CurrState_initSDSt;
    next_spiClkDelayOut <= spiClkDelayOut;
    next_SDInitRdy <= SDInitRdy;
    next_spiCS_n <= spiCS_n;
    next_initError <= initError;
    next_txDataOut <= txDataOut;
    next_txDataWen <= txDataWen;
    next_cmdByte <= cmdByte;
    next_dataByte1 <= dataByte1;
    next_dataByte2 <= dataByte2;
    next_dataByte3 <= dataByte3;
    next_dataByte4 <= dataByte4;
    next_checkSumByte <= checkSumByte;
    next_sendCmdReq <= sendCmdReq;
    next_loopCnt <= loopCnt;
    next_delCnt1 <= delCnt1;
    next_delCnt2 <= delCnt2;
    next_rxDataRdyClr <= rxDataRdyClr;
    case(CurrState_initSDSt)
      4'b0000: begin
        next_spiClkDelayOut <= spiClkDelayIn;
        next_SDInitRdy <= 1'b0;
        next_spiCS_n <= 1'b1;
        next_initError <= 2'b00;
        next_txDataOut <= 8'h00;
        next_txDataWen <= 1'b0;
        next_cmdByte <= 8'h00;
        next_dataByte1 <= 8'h00;
        next_dataByte2 <= 8'h00;
        next_dataByte3 <= 8'h00;
        next_dataByte4 <= 8'h00;
        next_checkSumByte <= 8'h00;
        next_sendCmdReq <= 1'b0;
        next_loopCnt <= 8'h00;
        next_delCnt1 <= 10'h000;
        next_delCnt2 <= 8'h00;
        next_rxDataRdyClr <= 1'b0;
        NextState_initSDSt <= 4'b0001;
      end
      4'b0001: begin
        next_SDInitRdy <= 1'b1;
        next_spiClkDelayOut <= spiClkDelayIn;
        next_cmdByte <= 8'h00;
        next_dataByte1 <= 8'h00;
        next_dataByte2 <= 8'h00;
        next_dataByte3 <= 8'h00;
        next_dataByte4 <= 8'h00;
        next_checkSumByte <= 8'h00;
        if(SDInitReq == 1'b1) begin
          NextState_initSDSt <= 4'b0010;
          next_SDInitRdy <= 1'b0;
          next_loopCnt <= 8'h00;
          next_spiClkDelayOut <= 8'h3b;
          next_initError <= 2'b00;
        end 
      end
      4'b0010: begin
        if(txDataFull == 1'b0) begin
          NextState_initSDSt <= 4'b0011;
          next_txDataOut <= 8'hff;
          next_txDataWen <= 1'b1;
          next_loopCnt <= loopCnt + 1'b1;
        end 
      end
      4'b0011: begin
        next_txDataWen <= 1'b0;
        if(loopCnt == 8'ha0) begin
          NextState_initSDSt <= 4'b1101;
        end else begin
          NextState_initSDSt <= 4'b0010;
        end
      end
      4'b1101: begin
        if(txDataEmpty == 1'b1) begin
          NextState_initSDSt <= 4'b0100;
          next_loopCnt <= 8'h00;
        end 
      end
      4'b0100: begin
        next_cmdByte <= 8'h40;
        next_dataByte1 <= 8'h00;
        next_dataByte2 <= 8'h00;
        next_dataByte3 <= 8'h00;
        next_dataByte4 <= 8'h00;
        next_checkSumByte <= 8'h95;
        next_sendCmdReq <= 1'b1;
        next_loopCnt <= loopCnt + 1'b1;
        next_spiCS_n <= 1'b0;
        NextState_initSDSt <= 4'b0101;
      end
      4'b0101: begin
        next_sendCmdReq <= 1'b0;
        NextState_initSDSt <= 4'b0110;
      end
      4'b0110: begin
        if(sendCmdRdy == 1'b1) begin
          NextState_initSDSt <= 4'b0111;
          next_spiCS_n <= 1'b1;
        end 
      end
      4'b0111: begin
        if((respTout == 1'b1) || (respByte != 8'h01) || (loopCnt != 8'hff)) begin
          NextState_initSDSt <= 4'b0100;
        end else if((respTout == 1'b1) || (respByte != 8'h01)) begin
          NextState_initSDSt <= 4'b0001;
          next_initError <= 2'b01;
        end else begin
          NextState_initSDSt <= 4'b1010;
        end
      end
      4'b1000: begin
        if(sendCmdRdy == 1'b1) begin
          NextState_initSDSt <= 4'b1001;
          next_spiCS_n <= 1'b1;
        end 
      end
      4'b1001: begin
        if(((respTout == 1'b1) || (respByte != 8'h00)) && (loopCnt != 8'hff)) begin
          NextState_initSDSt <= 4'b1010;
        end else if((respTout == 1'b1) || (respByte != 8'h00)) begin
          NextState_initSDSt <= 4'b0001;
          next_initError <= 2'b10;
        end else begin
          NextState_initSDSt <= 4'b0001;
        end
      end
      4'b1010: begin
        next_cmdByte <= 8'h41;
        next_dataByte1 <= 8'h00;
        next_dataByte2 <= 8'h00;
        next_dataByte3 <= 8'h00;
        next_dataByte4 <= 8'h00;
        next_checkSumByte <= 8'hff;
        next_sendCmdReq <= 1'b1;
        next_loopCnt <= loopCnt + 1'b1;
        next_spiCS_n <= 1'b0;
        next_delCnt1 <= 10'h000;
        NextState_initSDSt <= 4'b1011;
      end
      4'b1011: begin
        next_delCnt1 <= delCnt1 + 1'b1;
        next_delCnt2 <= 8'h00;
        next_sendCmdReq <= 1'b0;
        if(delCnt1 == 10'h177) begin
          NextState_initSDSt <= 4'b1000;
        end else begin
          NextState_initSDSt <= 4'b1100;
        end
      end
      4'b1100: begin
        next_delCnt2 <= delCnt2 + 1'b1;
        if(delCnt2 == 8'hff) begin
          NextState_initSDSt <= 4'b1011;
        end 
      end
    endcase
  end


  always @(posedge clk) begin
    if(rst == 1'b1) CurrState_initSDSt <= 4'b0000; 
    else CurrState_initSDSt <= NextState_initSDSt;
  end


  always @(posedge clk) begin
    if(rst == 1'b1) begin
      spiClkDelayOut <= spiClkDelayIn;
      SDInitRdy <= 1'b0;
      spiCS_n <= 1'b1;
      initError <= 2'b00;
      txDataOut <= 8'h00;
      txDataWen <= 1'b0;
      cmdByte <= 8'h00;
      dataByte1 <= 8'h00;
      dataByte2 <= 8'h00;
      dataByte3 <= 8'h00;
      dataByte4 <= 8'h00;
      checkSumByte <= 8'h00;
      sendCmdReq <= 1'b0;
      rxDataRdyClr <= 1'b0;
      loopCnt <= 8'h00;
      delCnt1 <= 10'h000;
      delCnt2 <= 8'h00;
    end else begin
      spiClkDelayOut <= next_spiClkDelayOut;
      SDInitRdy <= next_SDInitRdy;
      spiCS_n <= next_spiCS_n;
      initError <= next_initError;
      txDataOut <= next_txDataOut;
      txDataWen <= next_txDataWen;
      cmdByte <= next_cmdByte;
      dataByte1 <= next_dataByte1;
      dataByte2 <= next_dataByte2;
      dataByte3 <= next_dataByte3;
      dataByte4 <= next_dataByte4;
      checkSumByte <= next_checkSumByte;
      sendCmdReq <= next_sendCmdReq;
      rxDataRdyClr <= next_rxDataRdyClr;
      loopCnt <= next_loopCnt;
      delCnt1 <= next_delCnt1;
      delCnt2 <= next_delCnt2;
    end
  end


endmodule

