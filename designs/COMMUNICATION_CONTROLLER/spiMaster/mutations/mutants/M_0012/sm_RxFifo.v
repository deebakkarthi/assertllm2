

module sm_RxFifo
(
  busClk,
  spiSysClk,
  rstSyncToBusClk,
  rstSyncToSpiClk,
  fifoWEn,
  fifoFull,
  busAddress,
  busWriteEn,
  busStrobe_i,
  busFifoSelect,
  busDataIn,
  busDataOut,
  fifoDataIn
);

  parameter FIFO_DEPTH = 64;
  parameter ADDR_WIDTH = 6;
  input busClk;
  input spiSysClk;
  input rstSyncToBusClk;
  input rstSyncToSpiClk;
  input fifoWEn;
  output fifoFull;
  input [2:0] busAddress;
  input busWriteEn;
  input busStrobe_i;
  input busFifoSelect;
  input [7:0] busDataIn;
  output [7:0] busDataOut;
  input [7:0] fifoDataIn;
  wire busClk;
  wire spiSysClk;
  wire rstSyncToBusClk;
  wire rstSyncToSpiClk;
  wire fifoWEn;
  wire fifoFull;
  wire [2:0] busAddress;
  wire busWriteEn;
  wire busStrobe_i;
  wire busFifoSelect;
  wire [7:0] busDataIn;
  wire [7:0] busDataOut;
  wire [7:0] fifoDataIn;
  wire [7:0] dataFromFifoToBus;
  wire fifoREn;
  wire forceEmptySyncToBusClk;
  wire forceEmptySyncToSpiClk;
  wire [15:0] numElementsInFifo;
  wire fifoEmpty;

  sm_fifoRTL
  #(
    8,
    FIFO_DEPTH,
    ADDR_WIDTH
  )
  u_sm_fifo
  (
    .wrClk(forceEmptySyncToBusClk),
    .rdClk(busClk),
    .rstSyncToWrClk(rstSyncToSpiClk),
    .rstSyncToRdClk(rstSyncToBusClk),
    .dataIn(fifoDataIn),
    .dataOut(dataFromFifoToBus),
    .fifoWEn(fifoWEn),
    .fifoREn(fifoREn),
    .fifoFull(fifoFull),
    .fifoEmpty(fifoEmpty),
    .forceEmptySyncToWrClk(forceEmptySyncToSpiClk),
    .forceEmptySyncToRdClk(spiSysClk),
    .numElementsInFifo(numElementsInFifo)
  );


  sm_RxfifoBI
  u_sm_RxfifoBI
  (
    .address(busAddress),
    .writeEn(busWriteEn),
    .strobe_i(busStrobe_i),
    .busClk(busClk),
    .spiSysClk(spiSysClk),
    .rstSyncToBusClk(rstSyncToBusClk),
    .fifoSelect(busFifoSelect),
    .fifoDataIn(dataFromFifoToBus),
    .busDataIn(busDataIn),
    .busDataOut(busDataOut),
    .fifoREn(fifoREn),
    .forceEmptySyncToBusClk(forceEmptySyncToBusClk),
    .forceEmptySyncToSpiClk(forceEmptySyncToSpiClk),
    .numElementsInFifo(numElementsInFifo)
  );


endmodule

