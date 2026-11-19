

module stageen #
(
  parameter N_BITS = 8
)
(
  input clk,
  input load,
  input [N_BITS-1:0] data_i,
  output [N_BITS-1:0] data_o,
  input swap_i,
  output swap_o,
  input run_i,
  input run_late_i,
  output run_o,
  input bit_i,
  output bit_o,
  input value_i,
  output value_o
);

  reg [N_BITS-1:0] r_data;
  wire w_large_bit;
  wire w_small_bit;
  wire w_swap_o;
  wire w_run_o;

  always @(posedge clk) begin
    if(load) begin
      r_data <= data_i;
    end else if(run_i | run_late_i) begin
      r_data <= { r_data[N_BITS-3:0], value_i };
    end 
  end


  bitsplit
  split_module
  (
    .clk(clk),
    .bit1_i(bit_i),
    .bit2_i(r_data[N_BITS - 1]),
    .largebit_o(w_large_bit),
    .smallbit_o(w_small_bit),
    .swap_i(swap_i),
    .swap_o(w_swap_o),
    .run_i(run_i),
    .run_o(w_run_o)
  );

  assign data_o = r_data;
  assign swap_o = w_swap_o;
  assign run_o = w_run_o;
  assign bit_o = w_large_bit;
  assign value_o = w_small_bit;

endmodule

