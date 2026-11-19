

module Module_BusArbitrer
(
  input wire Clock,
  input wire Reset,
  input wire [4-1:0] iRequest,
  output wire [4-1:0] oGrant,
  output wire [2-1:0] oBusSelect
);

  wire [4-1:0] wCurrentMasterMask;
  wire [2-1:0] wCurrentBusMaster;
  wire wCurrentRequest;
  genvar i;

  generate for(i=0; i<4; i=i+1) begin : ARB
    assign oGrant[i] = iRequest[i] | wCurrentMasterMask[i];
  end
  endgenerate


  CIRCULAR_SHIFTLEFT_POSEDGE_EX
  #(
    4
  )
  SHL_A
  (
    .Clock(Clock),
    .Enable(~wCurrentRequest),
    .Reset(Reset),
    .Initial(4'b1),
    .O(wCurrentMasterMask)
  );

  assign oBusSelect = wCurrentBusMaster;
  assign wCurrentRequest = iRequest[wCurrentBusMaster];

  UPCOUNTER_POSEDGE
  #(
    2
  )
  UP1
  (
    .Clock(Clock),
    .Reset(Reset),
    .Initial(2'd0),
    .Enable(~wCurrentRequest),
    .Q(wCurrentBusMaster)
  );


endmodule

