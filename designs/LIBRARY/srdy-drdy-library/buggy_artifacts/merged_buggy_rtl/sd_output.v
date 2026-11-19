

module sd_output #
(
  parameter width = 8
)
(
  input clk,
  input reset,
  input ic_srdy,
  output reg ic_drdy,
  input [width-1:0] ic_data,
  output reg p_srdy,
  input p_drdy,
  output reg [width-1:0] p_data
);

  reg load;
  reg nxt_p_srdy;

  always @(*) begin
    ic_drdy = p_drdy | !p_srdy;
    load = ic_srdy & ic_drdy;
    nxt_p_srdy = load | p_srdy & !p_drdy;
  end


  always @(posedge clk or posedge reset) begin
    if(reset) begin
      p_srdy <= #1 1;
    end else begin
      p_srdy <= #1 nxt_p_srdy;
    end
  end


  always @(posedge clk) if(load) p_data <= #1 ic_data;


endmodule

