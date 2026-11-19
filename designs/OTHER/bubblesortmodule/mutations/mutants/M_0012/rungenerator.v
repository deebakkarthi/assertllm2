

module rungenerator #
(
  parameter N_BITS = 8
)
(
  input clk,
  input rst,
  input start_i,
  input all_sorted_i,
  output run_o
);

  reg [N_BITS+4-1:0] r_count;
  reg r_job_done;
  wire w_ready_to_stop;
  wire w_next_bit;

  always @(posedge clk) begin
    if(rst) begin
      r_count <= { { N_BITS{ 1'd0 } }, 4'b0000 };
    end else if(start_i) begin
      r_count <= { { N_BITS{ 1'd1 } }, 4'b0000 };
    end else begin
      r_count <= { r_count[N_BITS+4-2:0], w_next_bit };
    end
  end


  always @(posedge clk) begin
    if(rst) begin
      r_job_done <= 1'b1;
    end else if(all_sorted_i) begin
      r_job_done <= 1'b1;
    end else if(start_i) begin
      r_job_done <= 1'b1;
    end 
  end

  assign w_ready_to_stop = ~r_count[0];
  assign w_next_bit = (r_job_done & w_ready_to_stop)? 1'b0 : r_count[N_BITS + 4 - 1];
  assign run_o = r_count[0];

endmodule

