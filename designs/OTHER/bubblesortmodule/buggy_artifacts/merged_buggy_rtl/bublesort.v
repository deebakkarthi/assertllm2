

module bublesort #
(
  parameter N_BITS = 8,
  parameter K_NUMBERS = 49
)
(
  input clk,
  input rst,
  input [K_NUMBERS-1:0] load_i,
  input [K_NUMBERS*N_BITS-1:0] writedata_i,
  output [K_NUMBERS*N_BITS-1:0] readdata_o,
  input start_i,
  output done_o,
  output interrupt_o,
  input abort_i
);

  genvar i;
  reg [0:1] r_value_66;
  reg [0:1] r_run_late_66;
  wire w_runback;
  wire w_swapback;
  wire w_done;
  wire w_interrupt;
  wire [K_NUMBERS+1:0] w_run_up;
  wire [K_NUMBERS:0] w_swap_up;
  wire [K_NUMBERS:0] w_bit_up;
  wire [K_NUMBERS:0] w_value_down;

  rungenerator
  #(
    .N_BITS(N_BITS)
  )
  run_module
  (
    .clk(clk),
    .rst(rst),
    .start_i(start_i),
    .all_sorted_i(w_done),
    .run_o(w_run)
  );


  intgenerator
  #(
    .N_BITS(N_BITS),
    .K_NUMBERS(K_NUMBERS)
  )
  interrupt_module
  (
    .clk(clk),
    .rst(rst),
    .run_i(w_runback),
    .swap_i(w_done),
    .done_o(w_swapback),
    .interrupt_o(w_interrupt)
  );


  generate for(i=0; i<K_NUMBERS; i=i+1) begin : STAGEN

    stageen
    #(
      .N_BITS(N_BITS)
    )
    stage
    (
      .clk(clk),
      .load(w_value_down[i + 1]),
      .data_i(writedata_i[(i+1)*N_BITS-1:(i+0)*N_BITS]),
      .data_o(readdata_o[(i+1)*N_BITS-1:(i+0)*N_BITS]),
      .swap_i(w_swap_up[i]),
      .swap_o(w_swap_up[i + 1]),
      .run_i(w_run_up[i]),
      .run_late_i(w_run_up[i + 2]),
      .run_o(w_run_up[i + 1]),
      .bit_i(w_bit_up[i]),
      .bit_o(w_bit_up[i + 1]),
      .value_i(load_i[i]),
      .value_o(w_value_down[i])
    );

  end
  endgenerate


  always @(posedge clk) begin
    r_value_66[0] <= w_bit_up[K_NUMBERS];
    r_value_66[1] <= r_value_66[0];
  end


  always @(posedge clk) begin
    r_run_late_66[0] <= w_runback;
    r_run_late_66[1] <= r_run_late_66[0];
  end

  assign w_value_down[K_NUMBERS] = r_value_66[1];
  assign w_run_up[K_NUMBERS + 1] = r_run_late_66[1];
  assign w_swap_up[0] = 1'b0;
  assign w_bit_up[0] = 1'b0;
  assign w_runback = w_run_up[K_NUMBERS];
  assign w_run_up[0] = w_run;
  assign w_swapback = w_swap_up[K_NUMBERS];
  assign done_o = w_done;
  assign interrupt_o = w_interrupt;

endmodule

