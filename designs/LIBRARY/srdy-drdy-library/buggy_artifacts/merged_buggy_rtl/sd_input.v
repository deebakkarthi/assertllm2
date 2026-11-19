

module sd_input #
(
  parameter width = 8
)
(
  input clk,
  input reset,
  input c_srdy,
  output reg c_drdy,
  input [width-1:0] c_data,
  output reg ip_srdy,
  input ip_drdy,
  output reg [width-1:0] ip_data
);

  reg load;
  reg drain;
  reg occupied;reg nxt_occupied;
  reg [width-1:0] hold;reg [width-1:0] nxt_hold;
  reg nxt_c_drdy;

  always @(*) begin
    nxt_hold = hold;
    nxt_occupied = occupied;
    drain = occupied & ip_drdy;
    load = (c_srdy | c_drdy) & (!ip_drdy | drain);
    if(occupied) ip_data = hold;
    else ip_data = c_data;
    ip_srdy = (c_srdy | c_drdy) | occupied;
    if(load) begin
      nxt_hold = c_data;
      nxt_occupied = 1;
    end else if(drain) nxt_occupied = 0;
    nxt_c_drdy = !occupied & !load | drain & !load;
  end


  always @(posedge clk or posedge reset) begin
    if(reset) begin
      hold <= #1 0;
      occupied <= #1 0;
      c_drdy <= #1 0;
    end else begin
      hold <= #1 nxt_hold;
      occupied <= #1 nxt_occupied;
      c_drdy <= #1 nxt_c_drdy;
    end
  end


endmodule

