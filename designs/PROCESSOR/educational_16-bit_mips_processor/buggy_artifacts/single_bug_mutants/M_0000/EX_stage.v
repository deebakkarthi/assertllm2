

module EX_stage
(
  input clk,
  input rst,
  input [56:0] pipeline_reg_in,
  output reg [37:0] pipeline_reg_out,
  output [2:0] ex_op_dest
);

  wire [2:0] alu_cmd;assign alu_cmd = pipeline_reg_in[56:54];
  wire [15:0] alu_src1;assign alu_src1 = pipeline_reg_in[53:38];
  wire [15:0] alu_src2;assign alu_src2 = pipeline_reg_in[37:22];
  wire [15:0] ex_alu_result;

  alu
  alu_inst
  (
    .a(alu_src1),
    .b(alu_src2),
    .cmd(alu_cmd),
    .r(ex_alu_result)
  );


  always @(posedge clk) begin
    if(rst) begin
      pipeline_reg_out[37:0] <= 0;
    end else begin
      pipeline_reg_out[37:22] <= ex_alu_result;
      pipeline_reg_out[21:0] <= pipeline_reg_in[21:0];
    end
  end

  assign ex_op_dest = pipeline_reg_in[1:1];

endmodule

