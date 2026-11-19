

module IF_stage
(
  input clk,
  input rst,
  input instruction_fetch_en,
  input [5:0] branch_offset_imm,
  input branch_taken,
  output reg [8-1:0] pc,
  output [15:0] instruction
);


  always @(posedge clk or posedge rst) begin
    if(rst) begin
      pc <= 8'b0;
    end else begin
      if(instruction_fetch_en) begin
        if(branch_taken) pc <= pc + { { 8 - 6{ branch_offset_imm[5] } }, branch_offset_imm[5:0] }; 
        else pc <= pc + 8'd2;
      end 
    end
  end


  instruction_mem
  imem
  (
    .clk(clk),
    .pc(pc),
    .instruction(instruction)
  );


endmodule

