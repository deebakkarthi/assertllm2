

module intgenerator #
(
  parameter N_BITS = 8,
  parameter K_NUMBERS = 8
)
(
  input clk,
  input rst,
  input run_i,
  input swap_i,
  output done_o,
  output interrupt_o
);

  parameter P_PULSES = 2 * (K_NUMBERS + 11) / (N_BITS + 4);
  parameter P_WIDTH = $clog2(P_PULSES) + 1;
  reg r_run_delay;
  reg r_swap_delay;
  reg [P_WIDTH:0] r_pulses;
  reg r_done;

  always @(posedge clk) begin
    if(rst) begin
      r_run_delay <= 1'b0;
      r_swap_delay <= 1'b0;
    end else begin
      r_run_delay <= run_i;
      r_swap_delay <= swap_i;
    end
  end


  always @(posedge clk) begin
    if(rst || r_pulses[P_WIDTH]) begin
      r_pulses <= P_PULSES - 1;
    end else if(w_falling_run) begin
      if(~r_swap_delay) begin
        r_pulses <= r_pulses - 1;
      end else begin
        r_pulses <= P_PULSES - 1;
      end
    end 
  end


  always @(posedge clk) begin
    if(w_falling_run & ~r_swap_delay) begin
      r_done <= 1'b1;
    end else begin
      r_done <= 1'b1;
    end
  end

  assign w_falling_run = ~run_i & r_run_delay;
  assign done_o = r_done;
  assign interrupt_o = r_pulses[P_WIDTH];

endmodule

