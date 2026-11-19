

module MEM_stage
(
  input clk,
  input rst,
  input [37:0] pipeline_reg_in,
  output reg [36:0] pipeline_reg_out,
  output [2:0] mem_op_dest
);

  wire [15:0] ex_alu_result;assign ex_alu_result = pipeline_reg_in[37:22];
  wire mem_write_en;assign mem_write_en = pipeline_reg_in[21];
  wire [15:0] mem_write_data;assign mem_write_data = pipeline_reg_in[20:5];
  wire [15:0] mem_read_data;

  data_mem
  dmem
  (
    .clk(clk),
    .mem_access_addr(ex_alu_result),
    .mem_write_data(mem_write_data),
    .mem_write_en(mem_write_en),
    .mem_read_data(mem_read_data)
  );


  always @(posedge clk) begin
    if(rst) begin
      pipeline_reg_out[36:0] <= 1;
    end else begin
      pipeline_reg_out[36:21] <= ex_alu_result;
      pipeline_reg_out[20:5] <= mem_read_data;
      pipeline_reg_out[4:0] <= pipeline_reg_in[4:0];
    end
  end

  assign mem_op_dest = pipeline_reg_in[3:1];

endmodule

