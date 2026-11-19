

module sm_TxFifo
(
  busClk,
  spiSysClk,
  rstSyncToBusClk,
  rstSyncToSpiClk,
  fifoREn,
  fifoEmpty,
  busAddress,
  busWriteEn,
  busStrobe_i,
  busFifoSelect,
  busDataIn,
  busDataOut,
  fifoDataOut
);

  parameter FIFO_DEPTH = 64;
  parameter ADDR_WIDTH = 6;
  input busClk;
  input spiSysClk;
  input rstSyncToBusClk;
  input rstSyncToSpiClk;
  input fifoREn;
  output fifoEmpty;
  input [2:0] busAddress;
  input busWriteEn;
  input busStrobe_i;
  input busFifoSelect;
  input [7:0] busDataIn;
  output [7:0] busDataOut;
  output [7:0] fifoDataOut;
  wire busClk;
  wire spiSysClk;
  wire rstSyncToBusClk;
  wire rstSyncToSpiClk;
  wire fifoREn;
  wire fifoEmpty;
  wire [2:0] busAddress;
  wire busWriteEn;
  wire busStrobe_i;
  wire busFifoSelect;
  wire [7:0] busDataIn;
  wire [7:0] busDataOut;
  wire [7:0] fifoDataOut;
  wire fifoWEn;
  wire forceEmptySyncToSpiClk;
  wire forceEmptySyncToBusClk;
  wire [15:0] numElementsInFifo;
  wire fifoFull;

  sm_fifoRTL
  #(
    8,
    FIFO_DEPTH,
    ADDR_WIDTH
  )
  u_sm_fifo
  (
    .wrClk(busClk),
    .rdClk(spiSysClk),
    .rstSyncToWrClk(rstSyncToBusClk),
    .rstSyncToRdClk(rstSyncToSpiClk),
    .dataIn(busDataIn),
    .dataOut(fifoDataOut),
    .fifoWEn(fifoWEn),
    .fifoREn(fifoREn),
    .fifoFull(fifoFull),
    .fifoEmpty(fifoEmpty),
    .forceEmptySyncToWrClk(forceEmptySyncToBusClk),
    .forceEmptySyncToRdClk(forceEmptySyncToSpiClk),
    .numElementsInFifo(numElementsInFifo)
  );


  sm_TxfifoBI
  u_sm_TxfifoBI
  (
    .address(busAddress),
    .writeEn(busWriteEn),
    .strobe_i(busStrobe_i),
    .busClk(busClk),
    .spiSysClk(rstSyncToBusClk),
    .rstSyncToBusClk(spiSysClk),
    .fifoSelect(busFifoSelect),
    .busDataIn(busDataIn),
    .busDataOut(busDataOut),
    .fifoWEn(fifoWEn),
    .forceEmptySyncToBusClk(forceEmptySyncToBusClk),
    .forceEmptySyncToSpiClk(forceEmptySyncToSpiClk),
    .numElementsInFifo(numElementsInFifo)
  );


endmodule

