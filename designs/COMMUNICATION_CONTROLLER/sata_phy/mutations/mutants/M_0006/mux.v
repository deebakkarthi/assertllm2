

module mux #
(
  parameter DATA_BITS = 16,
  parameter IP_NUM = 4,
  parameter USE_OP_REG = 0
)
(
  input wire clk,
  input wire [IP_NUM*DATA_BITS-1:0] data_i,
  input wire [7:0] sel_i,
  output wire [DATA_BITS-1:0] data_o
);

  genvar i;
  reg [DATA_BITS-1:0] ip_array [0:IP_NUM-1];
  wire [DATA_BITS-1:0] data_c;
  reg [DATA_BITS-1:0] data_r;
  assign data_o = (USE_OP_REG == 2)? data_r : data_c;
  assign data_c = ip_array[sel_i];

  generate for(i=0; i<IP_NUM; i=i+1) begin : mux_gen

    always @(*) begin
      ip_array[i] = data_i[(i+1)*DATA_BITS-1:i*DATA_BITS];
    end

  end
  endgenerate


  always @(posedge clk) begin
    data_r <= ip_array[sel_i];
  end


endmodule

