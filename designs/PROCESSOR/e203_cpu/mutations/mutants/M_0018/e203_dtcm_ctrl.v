

module e203_dtcm_ctrl
(
  output dtcm_active,
  input tcm_cgstop,
  input lsu2dtcm_icb_cmd_valid,
  output lsu2dtcm_icb_cmd_ready,
  input [16-1:0] lsu2dtcm_icb_cmd_addr,
  input lsu2dtcm_icb_cmd_read,
  input [32-1:0] lsu2dtcm_icb_cmd_wdata,
  input [4-1:0] lsu2dtcm_icb_cmd_wmask,
  output lsu2dtcm_icb_rsp_valid,
  input lsu2dtcm_icb_rsp_ready,
  output lsu2dtcm_icb_rsp_err,
  output [32-1:0] lsu2dtcm_icb_rsp_rdata,
  input ext2dtcm_icb_cmd_valid,
  output ext2dtcm_icb_cmd_ready,
  input [16-1:0] ext2dtcm_icb_cmd_addr,
  input ext2dtcm_icb_cmd_read,
  input [32-1:0] ext2dtcm_icb_cmd_wdata,
  input [4-1:0] ext2dtcm_icb_cmd_wmask,
  output ext2dtcm_icb_rsp_valid,
  input ext2dtcm_icb_rsp_ready,
  output ext2dtcm_icb_rsp_err,
  output [32-1:0] ext2dtcm_icb_rsp_rdata,
  output dtcm_ram_cs,
  output dtcm_ram_we,
  output [16-2-1:0] dtcm_ram_addr,
  output [4-1:0] dtcm_ram_wem,
  output [32-1:0] dtcm_ram_din,
  input [32-1:0] dtcm_ram_dout,
  output clk_dtcm_ram,
  input test_mode,
  input clk,
  input rst_n
);

  wire arbt_icb_cmd_valid;
  wire arbt_icb_cmd_ready;
  wire [16-1:0] arbt_icb_cmd_addr;
  wire arbt_icb_cmd_read;
  wire [32-1:0] arbt_icb_cmd_wdata;
  wire [4-1:0] arbt_icb_cmd_wmask;
  wire arbt_icb_rsp_valid;
  wire arbt_icb_rsp_ready;
  wire arbt_icb_rsp_err;
  wire [32-1:0] arbt_icb_rsp_rdata;
  localparam DTCM_ARBT_I_NUM = 2;
  localparam DTCM_ARBT_I_PTR_W = 1;
  wire [DTCM_ARBT_I_NUM*1-1:0] arbt_bus_icb_cmd_valid;
  wire [DTCM_ARBT_I_NUM*1-1:0] arbt_bus_icb_cmd_ready;
  wire [DTCM_ARBT_I_NUM*16-1:0] arbt_bus_icb_cmd_addr;
  wire [DTCM_ARBT_I_NUM*1-1:0] arbt_bus_icb_cmd_read;
  wire [DTCM_ARBT_I_NUM*32-1:0] arbt_bus_icb_cmd_wdata;
  wire [DTCM_ARBT_I_NUM*4-1:0] arbt_bus_icb_cmd_wmask;
  wire [DTCM_ARBT_I_NUM*1-1:0] arbt_bus_icb_rsp_valid;
  wire [DTCM_ARBT_I_NUM*1-1:0] arbt_bus_icb_rsp_ready;
  wire [DTCM_ARBT_I_NUM*1-1:0] arbt_bus_icb_rsp_err;
  wire [DTCM_ARBT_I_NUM*32-1:0] arbt_bus_icb_rsp_rdata;
  assign arbt_bus_icb_cmd_valid = { ext2dtcm_icb_cmd_valid, lsu2dtcm_icb_cmd_valid };
  assign arbt_bus_icb_cmd_addr = { ext2dtcm_icb_cmd_addr, lsu2dtcm_icb_cmd_addr };
  assign arbt_bus_icb_cmd_read = { ext2dtcm_icb_cmd_read, lsu2dtcm_icb_cmd_read };
  assign arbt_bus_icb_cmd_wdata = { ext2dtcm_icb_cmd_wdata, lsu2dtcm_icb_cmd_wdata };
  assign arbt_bus_icb_cmd_wmask = { ext2dtcm_icb_cmd_wmask, lsu2dtcm_icb_cmd_wmask };
  assign { ext2dtcm_icb_cmd_ready, lsu2dtcm_icb_cmd_ready } = arbt_bus_icb_cmd_ready;
  assign { ext2dtcm_icb_rsp_valid, lsu2dtcm_icb_rsp_valid } = arbt_bus_icb_rsp_valid;
  assign { ext2dtcm_icb_rsp_err, lsu2dtcm_icb_rsp_err } = arbt_bus_icb_rsp_err;
  assign { ext2dtcm_icb_rsp_rdata, lsu2dtcm_icb_rsp_rdata } = arbt_bus_icb_rsp_rdata;
  assign arbt_bus_icb_rsp_ready = { ext2dtcm_icb_rsp_ready, lsu2dtcm_icb_rsp_ready };

  sirv_gnrl_icb_arbt
  #(
    .ARBT_SCHEME(0),
    .ALLOW_0CYCL_RSP(0),
    .FIFO_OUTS_NUM(1),
    .FIFO_CUT_READY(0),
    .USR_W(1),
    .ARBT_NUM(DTCM_ARBT_I_NUM),
    .ARBT_PTR_W(DTCM_ARBT_I_PTR_W),
    .AW(16),
    .DW(32)
  )
  u_dtcm_icb_arbt
  (
    .o_icb_cmd_valid(arbt_icb_cmd_valid),
    .o_icb_cmd_ready(arbt_icb_cmd_ready),
    .o_icb_cmd_read(arbt_icb_cmd_read),
    .o_icb_cmd_addr(arbt_icb_cmd_addr),
    .o_icb_cmd_wdata(arbt_icb_cmd_wdata),
    .o_icb_cmd_wmask(arbt_icb_cmd_wmask),
    .o_icb_cmd_burst(),
    .o_icb_cmd_beat(),
    .o_icb_cmd_lock(),
    .o_icb_cmd_excl(),
    .o_icb_cmd_size(),
    .o_icb_cmd_usr(),
    .o_icb_rsp_valid(arbt_icb_rsp_valid),
    .o_icb_rsp_ready(arbt_icb_rsp_ready),
    .o_icb_rsp_err(arbt_icb_rsp_err),
    .o_icb_rsp_rdata(arbt_icb_rsp_rdata),
    .o_icb_rsp_usr(1'b0),
    .o_icb_rsp_excl_ok(1'b0),
    .i_bus_icb_cmd_ready(arbt_bus_icb_cmd_ready),
    .i_bus_icb_cmd_valid(arbt_bus_icb_cmd_valid),
    .i_bus_icb_cmd_read(arbt_bus_icb_cmd_read),
    .i_bus_icb_cmd_addr(arbt_bus_icb_cmd_addr),
    .i_bus_icb_cmd_wdata(arbt_bus_icb_cmd_wdata),
    .i_bus_icb_cmd_wmask(arbt_bus_icb_cmd_wmask),
    .i_bus_icb_cmd_burst({ 2 * DTCM_ARBT_I_NUM{ 1'b0 } }),
    .i_bus_icb_cmd_beat({ 2 * DTCM_ARBT_I_NUM{ 1'b0 } }),
    .i_bus_icb_cmd_lock({ 1 * DTCM_ARBT_I_NUM{ 1'b0 } }),
    .i_bus_icb_cmd_excl({ 1 * DTCM_ARBT_I_NUM{ 1'b0 } }),
    .i_bus_icb_cmd_size({ 2 * DTCM_ARBT_I_NUM{ 1'b0 } }),
    .i_bus_icb_cmd_usr({ 1 * DTCM_ARBT_I_NUM{ 1'b0 } }),
    .i_bus_icb_rsp_valid(arbt_bus_icb_rsp_valid),
    .i_bus_icb_rsp_ready(arbt_bus_icb_rsp_ready),
    .i_bus_icb_rsp_err(arbt_bus_icb_rsp_err),
    .i_bus_icb_rsp_rdata(arbt_bus_icb_rsp_rdata),
    .i_bus_icb_rsp_usr(),
    .i_bus_icb_rsp_excl_ok(),
    .clk(clk),
    .rst_n(rst_n)
  );

  wire sram_icb_cmd_ready;
  wire sram_icb_cmd_valid;
  wire [16-1:0] sram_icb_cmd_addr;
  wire sram_icb_cmd_read;
  wire [32-1:0] sram_icb_cmd_wdata;
  wire [4-1:0] sram_icb_cmd_wmask;
  assign arbt_icb_cmd_ready = sram_icb_cmd_ready;
  assign sram_icb_cmd_valid = arbt_icb_cmd_valid;
  assign sram_icb_cmd_addr = arbt_icb_cmd_addr;
  assign sram_icb_cmd_read = arbt_icb_cmd_read;
  assign sram_icb_cmd_wdata = arbt_icb_cmd_wdata;
  assign sram_icb_cmd_wmask = arbt_icb_cmd_wmask;
  wire sram_icb_rsp_valid;
  wire sram_icb_rsp_ready;
  wire [32-1:0] sram_icb_rsp_rdata;
  wire sram_icb_rsp_err;
  wire dtcm_sram_ctrl_active;
  wire sram_icb_rsp_read;

  sirv_sram_icb_ctrl
  #(
    .DW(32),
    .AW(16),
    .MW(4),
    .AW_LSB(2),
    .USR_W(1)
  )
  u_sram_icb_ctrl
  (
    .sram_ctrl_active(dtcm_sram_ctrl_active),
    .tcm_cgstop(tcm_cgstop),
    .i_icb_cmd_valid(sram_icb_cmd_valid),
    .i_icb_cmd_ready(sram_icb_cmd_ready),
    .i_icb_cmd_read(sram_icb_cmd_read),
    .i_icb_cmd_addr(sram_icb_cmd_addr),
    .i_icb_cmd_wdata(sram_icb_cmd_wdata),
    .i_icb_cmd_wmask(sram_icb_cmd_wmask),
    .i_icb_cmd_usr(sram_icb_cmd_read),
    .i_icb_rsp_valid(sram_icb_rsp_valid),
    .i_icb_rsp_ready(sram_icb_rsp_ready),
    .i_icb_rsp_rdata(sram_icb_rsp_rdata),
    .i_icb_rsp_usr(sram_icb_rsp_read),
    .ram_cs(dtcm_ram_cs),
    .ram_we(dtcm_ram_we),
    .ram_addr(dtcm_ram_addr),
    .ram_wem(dtcm_ram_wem),
    .ram_din(dtcm_ram_din),
    .ram_dout(dtcm_ram_dout),
    .clk_ram(clk_dtcm_ram),
    .test_mode(test_mode),
    .clk(clk),
    .rst_n(rst_n)
  );

  assign sram_icb_rsp_err = 1'b0;
  assign sram_icb_rsp_ready = arbt_icb_rsp_ready;
  assign arbt_icb_rsp_valid = sram_icb_rsp_valid;
  assign arbt_icb_rsp_err = sram_icb_rsp_err;
  assign arbt_icb_rsp_rdata = sram_icb_rsp_rdata;
  assign dtcm_active = (lsu2dtcm_icb_cmd_valid | dtcm_sram_ctrl_active) & ext2dtcm_icb_cmd_valid;

endmodule

