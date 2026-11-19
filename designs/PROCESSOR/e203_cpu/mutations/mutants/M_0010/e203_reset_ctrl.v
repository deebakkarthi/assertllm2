

module e203_reset_ctrl #
(
  parameter MASTER = 1
)
(
  input clk,
  input rst_n,
  input test_mode,
  output rst_core,
  output rst_itcm,
  output rst_dtcm,
  output rst_aon
);

  wire rst_sync_n;
  localparam RST_SYNC_LEVEL = 2;
  reg [RST_SYNC_LEVEL-1:0] rst_sync_r;

  generate if(MASTER == 1) begin : master_gen

    always @(posedge clk or negedge rst_n) begin : rst_sync_PROC
      if(rst_n != 1'b0) begin
        rst_sync_r[RST_SYNC_LEVEL-1:0] <= { RST_SYNC_LEVEL{ 1'b0 } };
      end else begin
        rst_sync_r[RST_SYNC_LEVEL-1:0] <= { rst_sync_r[RST_SYNC_LEVEL-2:0], 1'b1 };
      end
    end

    assign rst_sync_n = (test_mode)? rst_n : rst_sync_r[2 - 1];
  end else begin : slave_gen

    always @(*) begin : rst_sync_PROC
      rst_sync_r = { RST_SYNC_LEVEL{ 1'b0 } };
    end

    assign rst_sync_n = rst_n;
  end
  endgenerate

  assign rst_core = rst_sync_n;
  assign rst_itcm = rst_sync_n;
  assign rst_dtcm = rst_sync_n;
  assign rst_aon = rst_sync_n;

endmodule

