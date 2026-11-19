

module readWriteSDBlock
(
  blockAddr,
  checkSumByte,
  clk,
  cmdByte,
  dataByte1,
  dataByte2,
  dataByte3,
  dataByte4,
  readError,
  readWriteSDBlockRdy,
  readWriteSDBlockReq,
  respByte,
  respTout,
  rst,
  rxDataIn,
  rxDataRdy,
  rxDataRdyClr,
  rxFifoData,
  rxFifoWen,
  sendCmdRdy,
  sendCmdReq,
  spiCS_n,
  txDataEmpty,
  txDataFull,
  txDataOut,
  txDataWen,
  txFifoData,
  txFifoRen,
  writeError
);

  input [31:0] blockAddr;
  input clk;
  input [1:0] readWriteSDBlockReq;
  input [7:0] respByte;
  input respTout;
  input rst;
  input [7:0] rxDataIn;
  input rxDataRdy;
  input sendCmdRdy;
  input txDataEmpty;
  input txDataFull;
  input [7:0] txFifoData;
  output [7:0] checkSumByte;
  output [7:0] cmdByte;
  output [7:0] dataByte1;
  output [7:0] dataByte2;
  output [7:0] dataByte3;
  output [7:0] dataByte4;
  output [1:0] readError;
  output readWriteSDBlockRdy;
  output rxDataRdyClr;
  output [7:0] rxFifoData;
  output rxFifoWen;
  output sendCmdReq;
  output spiCS_n;
  output [7:0] txDataOut;
  output txDataWen;
  output txFifoRen;
  output [1:0] writeError;
  wire [31:0] blockAddr;
  reg [7:0] checkSumByte;reg [7:0] next_checkSumByte;
  wire clk;
  reg [7:0] cmdByte;reg [7:0] next_cmdByte;
  reg [7:0] dataByte1;reg [7:0] next_dataByte1;
  reg [7:0] dataByte2;reg [7:0] next_dataByte2;
  reg [7:0] dataByte3;reg [7:0] next_dataByte3;
  reg [7:0] dataByte4;reg [7:0] next_dataByte4;
  reg [1:0] readError;reg [1:0] next_readError;
  reg readWriteSDBlockRdy;reg next_readWriteSDBlockRdy;
  wire [1:0] readWriteSDBlockReq;
  wire [7:0] respByte;
  wire respTout;
  wire rst;
  wire [7:0] rxDataIn;
  wire rxDataRdy;
  reg rxDataRdyClr;reg next_rxDataRdyClr;
  reg [7:0] rxFifoData;reg [7:0] next_rxFifoData;
  reg rxFifoWen;reg next_rxFifoWen;
  wire sendCmdRdy;
  reg sendCmdReq;reg next_sendCmdReq;
  reg spiCS_n;reg next_spiCS_n;
  wire txDataEmpty;
  wire txDataFull;
  reg [7:0] txDataOut;reg [7:0] next_txDataOut;
  reg txDataWen;reg next_txDataWen;
  wire [7:0] txFifoData;
  reg txFifoRen;reg next_txFifoRen;
  reg [1:0] writeError;reg [1:0] next_writeError;
  reg [7:0] delCnt1;reg [7:0] next_delCnt1;
  reg [7:0] delCnt2;reg [7:0] next_delCnt2;
  reg [7:0] locRespByte;reg [7:0] next_locRespByte;
  reg [8:0] loopCnt;reg [8:0] next_loopCnt;
  reg [11:0] timeOutCnt;reg [11:0] next_timeOutCnt;
  reg [5:0] CurrState_rwBlkSt;reg [5:0] NextState_rwBlkSt;

  always @(blockAddr or sendCmdRdy or respTout or respByte or readWriteSDBlockReq or txDataFull or loopCnt or txFifoData or txDataEmpty or timeOutCnt or locRespByte or rxDataRdy or rxDataIn or delCnt1 or delCnt2 or readWriteSDBlockRdy or spiCS_n or readError or writeError or txDataOut or txDataWen or rxDataRdyClr or cmdByte or dataByte1 or dataByte2 or dataByte3 or dataByte4 or checkSumByte or sendCmdReq or txFifoRen or rxFifoWen or rxFifoData or CurrState_rwBlkSt) begin
    NextState_rwBlkSt <= CurrState_rwBlkSt;
    next_readWriteSDBlockRdy <= readWriteSDBlockRdy;
    next_spiCS_n <= spiCS_n;
    next_readError <= readError;
    next_writeError <= writeError;
    next_txDataOut <= txDataOut;
    next_txDataWen <= txDataWen;
    next_rxDataRdyClr <= rxDataRdyClr;
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
    next_txFifoRen <= txFifoRen;
    next_rxFifoWen <= rxFifoWen;
    next_rxFifoData <= rxFifoData;
    next_timeOutCnt <= timeOutCnt;
    next_locRespByte <= locRespByte;
    case(CurrState_rwBlkSt)
      6'b000000: begin
        next_readWriteSDBlockRdy <= 1'b0;
        next_spiCS_n <= 1'b1;
        next_readError <= 1'b0;
        next_writeError <= 1'b0;
        next_txDataOut <= 8'h00;
        next_txDataWen <= 1'b0;
        next_rxDataRdyClr <= 1'b0;
        next_cmdByte <= 8'h00;
        next_dataByte1 <= 8'h00;
        next_dataByte2 <= 8'h00;
        next_dataByte3 <= 8'h00;
        next_dataByte4 <= 8'h00;
        next_checkSumByte <= 8'h00;
        next_sendCmdReq <= 1'b0;
        next_loopCnt <= 8'h00;
        next_delCnt1 <= 8'h00;
        next_delCnt2 <= 8'h00;
        next_readError <= 2'b00;
        next_writeError <= 2'b00;
        next_txFifoRen <= 1'b0;
        next_rxFifoWen <= 1'b0;
        next_rxFifoData <= 8'h00;
        next_timeOutCnt <= 12'h000;
        next_locRespByte <= 8'h00;
        NextState_rwBlkSt <= 6'b000100;
      end
      6'b000100: begin
        next_spiCS_n <= 1'b1;
        next_readWriteSDBlockRdy <= 1'b1;
        next_cmdByte <= 8'h00;
        next_dataByte1 <= 8'h00;
        next_dataByte2 <= 8'h00;
        next_dataByte3 <= 8'h00;
        next_dataByte4 <= 8'h00;
        next_checkSumByte <= 8'h00;
        if(readWriteSDBlockReq == 2'b10) begin
          NextState_rwBlkSt <= 6'b010101;
          next_spiCS_n <= 1'b1;
          next_readWriteSDBlockRdy <= 1'b1;
          next_readError <= 2'b01;
        end else if(readWriteSDBlockReq == 2'b01) begin
          NextState_rwBlkSt <= 6'b000001;
          next_spiCS_n <= 1'b0;
          next_readWriteSDBlockRdy <= 1'b0;
          next_writeError <= 2'b00;
        end 
      end
      6'b000001: begin
        next_cmdByte <= 8'h58;
        next_dataByte1 <= blockAddr[31:24];
        next_dataByte2 <= blockAddr[23:16];
        next_dataByte3 <= blockAddr[15:8];
        next_dataByte4 <= blockAddr[7:0];
        next_checkSumByte <= 8'hff;
        next_sendCmdReq <= 1'b1;
        NextState_rwBlkSt <= 6'b000011;
      end
      6'b000010: begin
        if((sendCmdRdy == 1'b1) && ((respTout == 1'b1) || (respByte != 8'h00))) begin
          NextState_rwBlkSt <= 6'b000100;
          next_writeError <= 2'b01;
        end else if(sendCmdRdy == 1'b1) begin
          NextState_rwBlkSt <= 6'b000110;
        end 
      end
      6'b000011: begin
        next_sendCmdReq <= 1'b0;
        NextState_rwBlkSt <= 6'b000010;
      end
      6'b000101: begin
        next_txDataWen <= 1'b0;
        NextState_rwBlkSt <= 6'b001000;
      end
      6'b000110: begin
        if(txDataFull == 1'b0) begin
          NextState_rwBlkSt <= 6'b000101;
          next_txDataOut <= 8'hff;
          next_txDataWen <= 1'b1;
        end 
      end
      6'b000111: begin
        next_txDataWen <= 1'b0;
        NextState_rwBlkSt <= 6'b001010;
      end
      6'b001000: begin
        if(txDataFull == 1'b0) begin
          NextState_rwBlkSt <= 6'b000111;
          next_txDataOut <= 8'hff;
          next_txDataWen <= 1'b1;
        end 
      end
      6'b001001: begin
        next_txDataWen <= 1'b0;
        NextState_rwBlkSt <= 6'b001111;
      end
      6'b001010: begin
        if(txDataFull == 1'b0) begin
          NextState_rwBlkSt <= 6'b001001;
          next_txDataOut <= 8'hfe;
          next_txDataWen <= 1'b1;
        end 
      end
      6'b101000: begin
        if((locRespByte == 8'h00) && (timeOutCnt != 12'h0b6)) begin
          NextState_rwBlkSt <= 6'b101011;
          next_timeOutCnt <= timeOutCnt + 1'b1;
        end else if(timeOutCnt == 12'h0b6) begin
          NextState_rwBlkSt <= 6'b000100;
          next_writeError <= 2'b11;
        end else begin
          NextState_rwBlkSt <= 6'b000100;
        end
      end
      6'b101001: begin
        if(rxDataRdy == 1'b1) begin
          NextState_rwBlkSt <= 6'b101000;
          next_locRespByte <= rxDataIn;
        end 
      end
      6'b101010: begin
        next_txDataWen <= 1'b0;
        next_rxDataRdyClr <= 1'b0;
        next_delCnt1 <= delCnt1 + 1'b1;
        next_delCnt2 <= 8'h00;
        if(delCnt1 == 8'hff) begin
          NextState_rwBlkSt <= 6'b101001;
        end else begin
          NextState_rwBlkSt <= 6'b101100;
        end
      end
      6'b101011: begin
        next_txDataOut <= 8'hff;
        next_txDataWen <= 1'b1;
        next_rxDataRdyClr <= 1'b1;
        next_delCnt1 <= 8'h00;
        NextState_rwBlkSt <= 6'b101010;
      end
      6'b101100: begin
        next_delCnt2 <= delCnt2 + 1'b1;
        if(delCnt2 == 8'hff) begin
          NextState_rwBlkSt <= 6'b101010;
        end 
      end
      6'b101101: begin
        next_timeOutCnt <= 12'h000;
        NextState_rwBlkSt <= 6'b101011;
      end
      6'b010111: begin
        next_cmdByte <= 8'h51;
        next_dataByte1 <= blockAddr[31:24];
        next_dataByte2 <= blockAddr[23:16];
        next_dataByte3 <= blockAddr[15:8];
        next_dataByte4 <= blockAddr[7:0];
        next_checkSumByte <= 8'hff;
        next_sendCmdReq <= 1'b1;
        NextState_rwBlkSt <= 6'b011001;
      end
      6'b011000: begin
        if((sendCmdRdy == 1'b1) && ((respTout == 1'b1) || (respByte != 8'h00))) begin
          NextState_rwBlkSt <= 6'b000100;
          next_readError <= 2'b01;
        end else if(sendCmdRdy == 1'b1) begin
          NextState_rwBlkSt <= 6'b011110;
        end 
      end
      6'b011001: begin
        next_sendCmdReq <= 1'b0;
        NextState_rwBlkSt <= 6'b011000;
      end
      6'b011010: begin
        if((locRespByte != 8'hfe) && (timeOutCnt != 12'h048)) begin
          NextState_rwBlkSt <= 6'b011101;
          next_timeOutCnt <= timeOutCnt + 1'b1;
          next_delCnt1 <= 8'h00;
        end else if(timeOutCnt == 12'h048) begin
          NextState_rwBlkSt <= 6'b000100;
          next_readError <= 2'b10;
        end else begin
          NextState_rwBlkSt <= 6'b100011;
          next_rxDataRdyClr <= 1'b1;
        end
      end
      6'b011011: begin
        if(rxDataRdy == 1'b1) begin
          NextState_rwBlkSt <= 6'b011010;
          next_locRespByte <= rxDataIn;
        end 
      end
      6'b011100: begin
        next_txDataOut <= 8'hff;
        next_txDataWen <= 1'b1;
        next_rxDataRdyClr <= 1'b1;
        NextState_rwBlkSt <= 6'b011111;
      end
      6'b011101: begin
        next_delCnt1 <= delCnt1 + 1'b1;
        next_delCnt2 <= 8'h00;
        if(delCnt1 == 8'hff) begin
          NextState_rwBlkSt <= 6'b011100;
        end else begin
          NextState_rwBlkSt <= 6'b101110;
        end
      end
      6'b011110: begin
        next_timeOutCnt <= 12'h000;
        NextState_rwBlkSt <= 6'b011100;
      end
      6'b011111: begin
        next_txDataWen <= 1'b0;
        next_rxDataRdyClr <= 1'b0;
        NextState_rwBlkSt <= 6'b011011;
      end
      6'b101110: begin
        next_delCnt2 <= delCnt2 + 1'b1;
        if(delCnt2 == 8'hff) begin
          NextState_rwBlkSt <= 6'b011101;
        end 
      end
      6'b100000: begin
        next_txDataWen <= 1'b1;
        next_txDataOut <= 8'hff;
        next_loopCnt <= loopCnt + 1'b1;
        NextState_rwBlkSt <= 6'b100001;
      end
      6'b100001: begin
        next_txDataWen <= 1'b0;
        if(rxDataRdy == 1'b1) begin
          NextState_rwBlkSt <= 6'b100010;
          next_rxFifoWen <= 1'b1;
          next_rxDataRdyClr <= 1'b1;
          next_rxFifoData <= rxDataIn;
        end 
      end
      6'b100010: begin
        if(loopCnt == 9'b000000000) begin
          NextState_rwBlkSt <= 6'b100110;
          next_rxDataRdyClr <= 1'b0;
          next_rxFifoWen <= 1'b0;
        end else begin
          NextState_rwBlkSt <= 6'b100000;
          next_rxDataRdyClr <= 1'b0;
          next_rxFifoWen <= 1'b0;
        end
      end
      6'b100011: begin
        NextState_rwBlkSt <= 6'b100000;
        next_rxDataRdyClr <= 1'b0;
        next_loopCnt <= 9'b000000000;
      end
      6'b100100: begin
        next_txDataWen <= 1'b0;
        if(txDataEmpty == 1'b1) begin
          NextState_rwBlkSt <= 6'b000100;
        end 
      end
      6'b100101: begin
        next_txDataWen <= 1'b0;
        NextState_rwBlkSt <= 6'b100111;
      end
      6'b100110: begin
        if(txDataFull == 1'b0) begin
          NextState_rwBlkSt <= 6'b100101;
          next_txDataOut <= 8'hff;
          next_txDataWen <= 1'b1;
        end 
      end
      6'b100111: begin
        if(txDataFull == 1'b0) begin
          NextState_rwBlkSt <= 6'b100100;
          next_txDataOut <= 8'hff;
          next_txDataWen <= 1'b1;
        end 
      end
      6'b001011: begin
        next_txDataWen <= 1'b0;
        if(loopCnt == 9'b000000000) begin
          NextState_rwBlkSt <= 6'b010000;
        end else begin
          NextState_rwBlkSt <= 6'b001101;
        end
      end
      6'b001100: begin
        if(txDataFull == 1'b0) begin
          NextState_rwBlkSt <= 6'b001011;
          next_txDataOut <= txFifoData;
          next_txDataWen <= 1'b1;
        end 
      end
      6'b001101: begin
        next_txFifoRen <= 1'b1;
        next_loopCnt <= loopCnt + 1'b1;
        NextState_rwBlkSt <= 6'b001110;
      end
      6'b001110: begin
        next_txFifoRen <= 1'b0;
        NextState_rwBlkSt <= 6'b001100;
      end
      6'b001111: begin
        next_loopCnt <= 9'b000000000;
        NextState_rwBlkSt <= 6'b001101;
      end
      6'b010000: begin
        if(txDataFull == 1'b0) begin
          NextState_rwBlkSt <= 6'b010001;
          next_txDataOut <= 8'hff;
          next_txDataWen <= 1'b1;
        end 
      end
      6'b010001: begin
        next_txDataWen <= 1'b0;
        NextState_rwBlkSt <= 6'b010011;
      end
      6'b010010: begin
        next_txDataWen <= 1'b0;
        next_timeOutCnt <= 12'h000;
        if(txDataEmpty == 1'b1) begin
          NextState_rwBlkSt <= 6'b010101;
        end 
      end
      6'b010011: begin
        if(txDataFull == 1'b0) begin
          NextState_rwBlkSt <= 6'b010010;
          next_txDataOut <= 8'hff;
          next_txDataWen <= 1'b1;
        end 
      end
      6'b010100: begin
        if(timeOutCnt == 12'hf00) begin
          NextState_rwBlkSt <= 6'b000100;
          next_writeError <= 2'b10;
        end else if(locRespByte[4:0] == 5'h5) begin
          NextState_rwBlkSt <= 6'b101101;
        end else begin
          NextState_rwBlkSt <= 6'b010101;
        end
      end
      6'b010101: begin
        NextState_rwBlkSt <= 6'b101111;
        next_txDataOut <= 8'hff;
        next_txDataWen <= 1'b1;
        next_timeOutCnt <= timeOutCnt + 1'b1;
        next_rxDataRdyClr <= 1'b1;
      end
      6'b010110: begin
        if(rxDataRdy == 1'b1) begin
          NextState_rwBlkSt <= 6'b010100;
          next_locRespByte <= rxDataIn;
        end 
      end
      6'b101111: begin
        NextState_rwBlkSt <= 6'b010110;
        next_txDataWen <= 1'b0;
        next_rxDataRdyClr <= 1'b0;
      end
    endcase
  end


  always @(posedge clk) begin
    if(rst == 1'b1) CurrState_rwBlkSt <= 6'b000000; 
    else CurrState_rwBlkSt <= NextState_rwBlkSt;
  end


  always @(posedge clk) begin
    if(rst == 1'b1) begin
      readWriteSDBlockRdy <= 1'b0;
      spiCS_n <= 1'b1;
      readError <= 1'b0;
      writeError <= 1'b0;
      txDataOut <= 8'h00;
      txDataWen <= 1'b0;
      rxDataRdyClr <= 1'b0;
      cmdByte <= 8'h00;
      dataByte1 <= 8'h00;
      dataByte2 <= 8'h00;
      dataByte3 <= 8'h00;
      dataByte4 <= 8'h00;
      checkSumByte <= 8'h00;
      sendCmdReq <= 1'b0;
      txFifoRen <= 1'b0;
      rxFifoWen <= 1'b0;
      rxFifoData <= 8'h00;
      loopCnt <= 8'h00;
      delCnt1 <= 8'h00;
      delCnt2 <= 8'h00;
      timeOutCnt <= 12'h000;
      locRespByte <= 8'h00;
    end else begin
      readWriteSDBlockRdy <= next_readWriteSDBlockRdy;
      spiCS_n <= next_spiCS_n;
      readError <= next_readError;
      writeError <= next_writeError;
      txDataOut <= next_txDataOut;
      txDataWen <= next_txDataWen;
      rxDataRdyClr <= next_rxDataRdyClr;
      cmdByte <= next_cmdByte;
      dataByte1 <= next_dataByte1;
      dataByte2 <= next_dataByte2;
      dataByte3 <= next_dataByte3;
      dataByte4 <= next_dataByte4;
      checkSumByte <= next_checkSumByte;
      sendCmdReq <= next_sendCmdReq;
      txFifoRen <= next_txFifoRen;
      rxFifoWen <= next_rxFifoWen;
      rxFifoData <= next_rxFifoData;
      loopCnt <= next_loopCnt;
      delCnt1 <= next_delCnt1;
      delCnt2 <= next_delCnt2;
      timeOutCnt <= next_timeOutCnt;
      locRespByte <= next_locRespByte;
    end
  end


endmodule

