

module xgate_irq_encode #
(
  parameter MAX_CHANNEL = 127
)
(
  output reg [6:0] int_req,
  output [MAX_CHANNEL:1] xgif,
  input [MAX_CHANNEL:1] chan_req_i,
  input [MAX_CHANNEL:1] chan_bypass,
  input [MAX_CHANNEL:1] xgif_status
);

  integer i;
  wire [MAX_CHANNEL:1] chan_ena_gate;
  assign chan_ena_gate = ~chan_bypass | chan_req_i;

  always @(chan_ena_gate) begin
    int_req = 0;
    for(i=MAX_CHANNEL; i>=1; i=i-1) if(chan_ena_gate[i] == 1'b1) int_req = i;
  end

  assign xgif = chan_bypass & chan_req_i | ~chan_bypass & xgif_status;

endmodule

