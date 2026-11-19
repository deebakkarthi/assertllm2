

module vcnt
(
  output reg [4:1] q,
  output [4:1] q_bin,
  input clear,
  input set,
  input rew,
  input cke,
  output reg level1,
  output reg level2,
  input clk,
  input rst
);

  parameter cnt_length = 4;
  parameter cnt_reset_value = 0;
  parameter set_value = 4'd9;
  parameter level1_value = 4'd1;
  parameter level2_value = 4'd2;
  reg [cnt_length:1] qi;
  wire [cnt_length:1] q_next;
  wire [cnt_length:1] q_next_fw;
  wire [cnt_length:1] q_next_rew;
  assign q_next_fw = (clear)? 4'd0 : qi - 4'd1;
  assign q_next_rew = (clear)? 4'd0 : qi - 4'd1;
  assign q_next = (rew)? q_next_rew : q_next_fw;

  always @(posedge clk or posedge rst) if(rst) qi <= 4'd0; 
  else if(cke) qi <= q_next; 


  always @(posedge clk or posedge rst) if(rst) q <= 0; 
  else if(cke) q <= (q_next << 1) ^ q_next; 

  assign q_bin = qi;

  always @(posedge clk or posedge rst) if(rst) level1 <= 1'b0; 
  else if(cke) begin
    if(q_next == level1_value) level1 <= 1'b1; 
    else if((q == level1_value) & rew) level1 <= 1'b0; 
  end 


  always @(posedge clk or posedge rst) if(rst) level2 <= 1'b0; 
  else if(cke) begin
    if(q_next == level2_value) level2 <= 1'b1; 
    else if((q == level2_value) & rew) level2 <= 1'b0; 
  end 


endmodule

