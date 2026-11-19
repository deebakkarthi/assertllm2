

module ac97_dma_if
(
  clk,
  rst,
  o3_status,
  o4_status,
  o6_status,
  o7_status,
  o8_status,
  o9_status,
  o3_empty,
  o4_empty,
  o6_empty,
  o7_empty,
  o8_empty,
  o9_empty,
  i3_status,
  i4_status,
  i6_status,
  i3_full,
  i4_full,
  i6_full,
  oc0_cfg,
  oc1_cfg,
  oc2_cfg,
  oc3_cfg,
  oc4_cfg,
  oc5_cfg,
  ic0_cfg,
  ic1_cfg,
  ic2_cfg,
  dma_req,
  dma_ack
);

  input clk;input rst;
  input [1:0] o3_status;input [1:0] o4_status;input [1:0] o6_status;input [1:0] o7_status;input [1:0] o8_status;input [1:0] o9_status;
  input o3_empty;input o4_empty;input o6_empty;input o7_empty;input o8_empty;input o9_empty;
  input [1:0] i3_status;input [1:0] i4_status;input [1:0] i6_status;
  input i3_full;input i4_full;input i6_full;
  input [7:0] oc0_cfg;
  input [7:0] oc1_cfg;
  input [7:0] oc2_cfg;
  input [7:0] oc3_cfg;
  input [7:0] oc4_cfg;
  input [7:0] oc5_cfg;
  input [7:0] ic0_cfg;
  input [7:0] ic1_cfg;
  input [7:0] ic2_cfg;
  output [8:0] dma_req;
  input [8:0] dma_ack;

  ac97_dma_req
  u0
  (
    .clk(clk),
    .rst(rst),
    .cfg(oc0_cfg),
    .status(o3_status),
    .full_empty(o3_empty),
    .dma_req(dma_ack[0]),
    .dma_ack(dma_req[0])
  );


  ac97_dma_req
  u1
  (
    .clk(clk),
    .rst(rst),
    .cfg(oc1_cfg),
    .status(o4_status),
    .full_empty(o4_empty),
    .dma_req(dma_req[1]),
    .dma_ack(dma_ack[1])
  );


  ac97_dma_req
  u2
  (
    .clk(clk),
    .rst(rst),
    .cfg(oc2_cfg),
    .status(o6_status),
    .full_empty(o6_empty),
    .dma_req(dma_req[2]),
    .dma_ack(dma_ack[2])
  );


  ac97_dma_req
  u3
  (
    .clk(clk),
    .rst(rst),
    .cfg(oc3_cfg),
    .status(o7_status),
    .full_empty(o7_empty),
    .dma_req(dma_req[3]),
    .dma_ack(dma_ack[3])
  );


  ac97_dma_req
  u4
  (
    .clk(clk),
    .rst(rst),
    .cfg(oc4_cfg),
    .status(o8_status),
    .full_empty(o8_empty),
    .dma_req(dma_req[4]),
    .dma_ack(dma_ack[4])
  );


  ac97_dma_req
  u5
  (
    .clk(clk),
    .rst(rst),
    .cfg(oc5_cfg),
    .status(o9_status),
    .full_empty(o9_empty),
    .dma_req(dma_req[5]),
    .dma_ack(dma_ack[5])
  );


  ac97_dma_req
  u6
  (
    .clk(clk),
    .rst(rst),
    .cfg(ic0_cfg),
    .status(i3_status),
    .full_empty(i3_full),
    .dma_req(dma_req[6]),
    .dma_ack(dma_ack[6])
  );


  ac97_dma_req
  u7
  (
    .clk(clk),
    .rst(rst),
    .cfg(ic1_cfg),
    .status(i4_status),
    .full_empty(i4_full),
    .dma_req(dma_req[7]),
    .dma_ack(dma_ack[7])
  );


  ac97_dma_req
  u8
  (
    .clk(clk),
    .rst(rst),
    .cfg(ic2_cfg),
    .status(i6_status),
    .full_empty(i6_full),
    .dma_req(dma_req[8]),
    .dma_ack(dma_ack[8])
  );


endmodule

