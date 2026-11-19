

module e203_cpu #
(
  parameter MASTER = 1
)
(
  output [32-1:0] inspect_pc,
  output inspect_dbg_irq,
  output inspect_mem_cmd_valid,
  output inspect_mem_cmd_ready,
  output inspect_mem_rsp_valid,
  output inspect_mem_rsp_ready,
  output inspect_core_clk,
  output core_csr_clk,
  output rst_itcm,
  output rst_dtcm,
  output core_wfi,
  output tm_stop,
  input [32-1:0] pc_rtvec,
  output [32-1:0] cmt_dpc,
  output cmt_dpc_ena,
  output [3-1:0] cmt_dcause,
  output cmt_dcause_ena,
  output dbg_irq_r,
  output wr_dcsr_ena,
  output wr_dpc_ena,
  output wr_dscratch_ena,
  output [32-1:0] wr_csr_nxt,
  input [32-1:0] dcsr_r,
  input [32-1:0] dpc_r,
  input [32-1:0] dscratch_r,
  input dbg_mode,
  input dbg_halt_r,
  input dbg_step_r,
  input dbg_ebreakm_r,
  input dbg_stopcycle,
  input [1-1:0] core_mhartid,
  input dbg_irq_a,
  input ext_irq_a,
  input sft_irq_a,
  input tmr_irq_a,
  input ext2itcm_icb_cmd_valid,
  output ext2itcm_icb_cmd_ready,
  input [16-1:0] ext2itcm_icb_cmd_addr,
  input ext2itcm_icb_cmd_read,
  input [32-1:0] ext2itcm_icb_cmd_wdata,
  input [32/8-1:0] ext2itcm_icb_cmd_wmask,
  output ext2itcm_icb_rsp_valid,
  input ext2itcm_icb_rsp_ready,
  output ext2itcm_icb_rsp_err,
  output [32-1:0] ext2itcm_icb_rsp_rdata,
  input ext2dtcm_icb_cmd_valid,
  output ext2dtcm_icb_cmd_ready,
  input [16-1:0] ext2dtcm_icb_cmd_addr,
  input ext2dtcm_icb_cmd_read,
  input [32-1:0] ext2dtcm_icb_cmd_wdata,
  input [32/8-1:0] ext2dtcm_icb_cmd_wmask,
  output ext2dtcm_icb_rsp_valid,
  input ext2dtcm_icb_rsp_ready,
  output ext2dtcm_icb_rsp_err,
  output [32-1:0] ext2dtcm_icb_rsp_rdata,
  input [32-1:0] ppi_region_indic,
  input ppi_icb_enable,
  output ppi_icb_cmd_valid,
  input ppi_icb_cmd_ready,
  output [32-1:0] ppi_icb_cmd_addr,
  output ppi_icb_cmd_read,
  output [32-1:0] ppi_icb_cmd_wdata,
  output [32/8-1:0] ppi_icb_cmd_wmask,
  output ppi_icb_cmd_lock,
  output ppi_icb_cmd_excl,
  output [1:0] ppi_icb_cmd_size,
  input ppi_icb_rsp_valid,
  output ppi_icb_rsp_ready,
  input ppi_icb_rsp_err,
  input ppi_icb_rsp_excl_ok,
  input [32-1:0] ppi_icb_rsp_rdata,
  input [32-1:0] clint_region_indic,
  input clint_icb_enable,
  output clint_icb_cmd_valid,
  input clint_icb_cmd_ready,
  output [32-1:0] clint_icb_cmd_addr,
  output clint_icb_cmd_read,
  output [32-1:0] clint_icb_cmd_wdata,
  output [32/8-1:0] clint_icb_cmd_wmask,
  output clint_icb_cmd_lock,
  output clint_icb_cmd_excl,
  output [1:0] clint_icb_cmd_size,
  input clint_icb_rsp_valid,
  output clint_icb_rsp_ready,
  input clint_icb_rsp_err,
  input clint_icb_rsp_excl_ok,
  input [32-1:0] clint_icb_rsp_rdata,
  input [32-1:0] plic_region_indic,
  input plic_icb_enable,
  output plic_icb_cmd_valid,
  input plic_icb_cmd_ready,
  output [32-1:0] plic_icb_cmd_addr,
  output plic_icb_cmd_read,
  output [32-1:0] plic_icb_cmd_wdata,
  output [32/8-1:0] plic_icb_cmd_wmask,
  output plic_icb_cmd_lock,
  output plic_icb_cmd_excl,
  output [1:0] plic_icb_cmd_size,
  input plic_icb_rsp_valid,
  output plic_icb_rsp_ready,
  input plic_icb_rsp_err,
  input plic_icb_rsp_excl_ok,
  input [32-1:0] plic_icb_rsp_rdata,
  input [32-1:0] fio_region_indic,
  input fio_icb_enable,
  output fio_icb_cmd_valid,
  input fio_icb_cmd_ready,
  output [32-1:0] fio_icb_cmd_addr,
  output fio_icb_cmd_read,
  output [32-1:0] fio_icb_cmd_wdata,
  output [32/8-1:0] fio_icb_cmd_wmask,
  output fio_icb_cmd_lock,
  output fio_icb_cmd_excl,
  output [1:0] fio_icb_cmd_size,
  input fio_icb_rsp_valid,
  output fio_icb_rsp_ready,
  input fio_icb_rsp_err,
  input fio_icb_rsp_excl_ok,
  input [32-1:0] fio_icb_rsp_rdata,
  input mem_icb_enable,
  output mem_icb_cmd_valid,
  input mem_icb_cmd_ready,
  output [32-1:0] mem_icb_cmd_addr,
  output mem_icb_cmd_read,
  output [32-1:0] mem_icb_cmd_wdata,
  output [32/8-1:0] mem_icb_cmd_wmask,
  output mem_icb_cmd_lock,
  output mem_icb_cmd_excl,
  output [1:0] mem_icb_cmd_size,
  output [1:0] mem_icb_cmd_burst,
  output [1:0] mem_icb_cmd_beat,
  input mem_icb_rsp_valid,
  output mem_icb_rsp_ready,
  input mem_icb_rsp_err,
  input mem_icb_rsp_excl_ok,
  input [32-1:0] mem_icb_rsp_rdata,
  output itcm_ls,
  output itcm_ram_cs,
  output itcm_ram_we,
  output [16-3-1:0] itcm_ram_addr,
  output [8-1:0] itcm_ram_wem,
  output [64-1:0] itcm_ram_din,
  input [64-1:0] itcm_ram_dout,
  output clk_itcm_ram,
  output dtcm_ls,
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

  wire core_cgstop;
  wire tcm_cgstop;
  wire core_ifu_active;
  wire core_exu_active;
  wire core_lsu_active;
  wire core_biu_active;
  wire rst_core;
  wire clk_core_ifu;
  wire clk_core_exu;
  wire clk_core_lsu;
  wire clk_core_biu;
  wire clk_itcm;
  wire itcm_active;
  wire clk_dtcm;
  wire dtcm_active;
  wire rst_aon;
  wire clk_aon;

  e203_reset_ctrl
  #(
    .MASTER(MASTER)
  )
  u_e203_reset_ctrl
  (
    .clk(clk_aon),
    .rst_n(rst_n),
    .test_mode(test_mode),
    .rst_core(rst_core),
    .rst_itcm(rst_itcm),
    .rst_dtcm(rst_dtcm),
    .rst_aon(rst_aon)
  );


  e203_clk_ctrl
  u_e203_clk_ctrl
  (
    .clk(clk),
    .rst_n(rst_aon),
    .test_mode(test_mode),
    .clk_aon(clk_aon),
    .core_cgstop(core_cgstop),
    .clk_core_ifu(clk_core_ifu),
    .clk_core_exu(clk_core_exu),
    .clk_core_lsu(clk_core_lsu),
    .clk_core_biu(clk_core_biu),
    .clk_itcm(clk_itcm),
    .itcm_active(itcm_active),
    .itcm_ls(itcm_ls),
    .clk_dtcm(clk_dtcm),
    .dtcm_active(dtcm_active),
    .dtcm_ls(dtcm_ls),
    .core_ifu_active(core_ifu_active),
    .core_exu_active(core_exu_active),
    .core_lsu_active(core_lsu_active),
    .core_biu_active(core_biu_active),
    .core_wfi(core_wfi)
  );

  wire ext_irq_r;
  wire sft_irq_r;
  wire tmr_irq_r;

  e203_irq_sync
  #(
    .MASTER(MASTER)
  )
  u_e203_irq_sync
  (
    .clk(clk_aon),
    .rst_n(rst_aon),
    .dbg_irq_a(dbg_irq_a),
    .dbg_irq_r(dbg_irq_r),
    .ext_irq_a(ext_irq_a),
    .sft_irq_a(sft_irq_a),
    .tmr_irq_a(tmr_irq_a),
    .ext_irq_r(ext_irq_r),
    .sft_irq_r(sft_irq_r),
    .tmr_irq_r(tmr_irq_r)
  );

  wire ifu2itcm_holdup;
  wire ifu2itcm_icb_cmd_valid;
  wire ifu2itcm_icb_cmd_ready;
  wire [16-1:0] ifu2itcm_icb_cmd_addr;
  wire ifu2itcm_icb_rsp_valid;
  wire ifu2itcm_icb_rsp_ready;
  wire ifu2itcm_icb_rsp_err;
  wire [64-1:0] ifu2itcm_icb_rsp_rdata;
  wire lsu2itcm_icb_cmd_valid;
  wire lsu2itcm_icb_cmd_ready;
  wire [16-1:0] lsu2itcm_icb_cmd_addr;
  wire lsu2itcm_icb_cmd_read;
  wire [32-1:0] lsu2itcm_icb_cmd_wdata;
  wire [32/8-1:0] lsu2itcm_icb_cmd_wmask;
  wire lsu2itcm_icb_cmd_lock;
  wire lsu2itcm_icb_cmd_excl;
  wire [1:0] lsu2itcm_icb_cmd_size;
  wire lsu2itcm_icb_rsp_valid;
  wire lsu2itcm_icb_rsp_ready;
  wire lsu2itcm_icb_rsp_err;
  wire [32-1:0] lsu2itcm_icb_rsp_rdata;
  wire lsu2dtcm_icb_cmd_valid;
  wire lsu2dtcm_icb_cmd_ready;
  wire [16-1:0] lsu2dtcm_icb_cmd_addr;
  wire lsu2dtcm_icb_cmd_read;
  wire [32-1:0] lsu2dtcm_icb_cmd_wdata;
  wire [32/8-1:0] lsu2dtcm_icb_cmd_wmask;
  wire lsu2dtcm_icb_cmd_lock;
  wire lsu2dtcm_icb_cmd_excl;
  wire [1:0] lsu2dtcm_icb_cmd_size;
  wire lsu2dtcm_icb_rsp_valid;
  wire lsu2dtcm_icb_rsp_ready;
  wire lsu2dtcm_icb_rsp_err;
  wire [32-1:0] lsu2dtcm_icb_rsp_rdata;
  wire nice_mem_holdup;
  wire nice_req_valid;
  wire nice_req_ready;
  wire [32-1:0] nice_req_inst;
  wire [32-1:0] nice_req_rs1;
  wire [32-1:0] nice_req_rs2;
  wire nice_rsp_multicyc_valid;
  wire nice_rsp_multicyc_ready;
  wire [32-1:0] nice_rsp_multicyc_dat;
  wire nice_rsp_multicyc_err;
  wire nice_icb_cmd_valid;
  wire nice_icb_cmd_ready;
  wire [32-1:0] nice_icb_cmd_addr;
  wire nice_icb_cmd_read;
  wire [32-1:0] nice_icb_cmd_wdata;
  wire [1:0] nice_icb_cmd_size;
  wire nice_icb_rsp_valid;
  wire nice_icb_rsp_ready;
  wire [32-1:0] nice_icb_rsp_rdata;
  wire nice_icb_rsp_err;

  e203_core
  u_e203_core
  (
    .inspect_pc(inspect_pc),
    .tcm_cgstop(tcm_cgstop),
    .core_cgstop(core_cgstop),
    .tm_stop(tm_stop),
    .pc_rtvec(pc_rtvec),
    .ifu_active(core_ifu_active),
    .exu_active(core_exu_active),
    .lsu_active(core_lsu_active),
    .biu_active(core_biu_active),
    .core_wfi(core_wfi),
    .core_mhartid(core_mhartid),
    .dbg_irq_r(dbg_irq_r),
    .lcl_irq_r(1'b0),
    .ext_irq_r(ext_irq_r),
    .sft_irq_r(sft_irq_r),
    .tmr_irq_r(tmr_irq_r),
    .evt_r(1'b0),
    .cmt_dpc(cmt_dpc),
    .cmt_dpc_ena(cmt_dpc_ena),
    .cmt_dcause(cmt_dcause),
    .cmt_dcause_ena(cmt_dcause_ena),
    .wr_dcsr_ena(wr_dcsr_ena),
    .wr_dpc_ena(wr_dpc_ena),
    .wr_dscratch_ena(wr_dscratch_ena),
    .wr_csr_nxt(wr_csr_nxt),
    .dcsr_r(dcsr_r),
    .dpc_r(dpc_r),
    .dscratch_r(dscratch_r),
    .dbg_mode(dbg_mode),
    .dbg_halt_r(dbg_halt_r),
    .dbg_step_r(dbg_step_r),
    .dbg_ebreakm_r(dbg_ebreakm_r),
    .dbg_stopcycle(dbg_stopcycle),
    .itcm_region_indic(32'h8000_0000),
    .dtcm_region_indic(32'h9000_0000),
    .ifu2itcm_holdup(ifu2itcm_holdup),
    .ifu2itcm_icb_cmd_valid(ifu2itcm_icb_cmd_valid),
    .ifu2itcm_icb_cmd_ready(ifu2itcm_icb_cmd_ready),
    .ifu2itcm_icb_cmd_addr(ifu2itcm_icb_cmd_addr),
    .ifu2itcm_icb_rsp_valid(ifu2itcm_icb_rsp_valid),
    .ifu2itcm_icb_rsp_ready(ifu2itcm_icb_rsp_ready),
    .ifu2itcm_icb_rsp_err(ifu2itcm_icb_rsp_err),
    .ifu2itcm_icb_rsp_rdata(ifu2itcm_icb_rsp_rdata),
    .lsu2itcm_icb_cmd_valid(lsu2itcm_icb_cmd_valid),
    .lsu2itcm_icb_cmd_ready(lsu2itcm_icb_cmd_ready),
    .lsu2itcm_icb_cmd_addr(lsu2itcm_icb_cmd_addr),
    .lsu2itcm_icb_cmd_read(lsu2itcm_icb_cmd_read),
    .lsu2itcm_icb_cmd_wdata(lsu2itcm_icb_cmd_wdata),
    .lsu2itcm_icb_cmd_wmask(lsu2itcm_icb_cmd_wmask),
    .lsu2itcm_icb_cmd_lock(lsu2itcm_icb_cmd_lock),
    .lsu2itcm_icb_cmd_excl(lsu2itcm_icb_cmd_excl),
    .lsu2itcm_icb_cmd_size(lsu2itcm_icb_cmd_size),
    .lsu2itcm_icb_rsp_valid(lsu2itcm_icb_rsp_valid),
    .lsu2itcm_icb_rsp_ready(lsu2itcm_icb_rsp_ready),
    .lsu2itcm_icb_rsp_err(lsu2itcm_icb_rsp_err),
    .lsu2itcm_icb_rsp_excl_ok(1'b0),
    .lsu2itcm_icb_rsp_rdata(lsu2itcm_icb_rsp_rdata),
    .lsu2dtcm_icb_cmd_valid(lsu2dtcm_icb_cmd_valid),
    .lsu2dtcm_icb_cmd_ready(lsu2dtcm_icb_cmd_ready),
    .lsu2dtcm_icb_cmd_addr(lsu2dtcm_icb_cmd_addr),
    .lsu2dtcm_icb_cmd_read(lsu2dtcm_icb_cmd_read),
    .lsu2dtcm_icb_cmd_wdata(lsu2dtcm_icb_cmd_wdata),
    .lsu2dtcm_icb_cmd_wmask(lsu2dtcm_icb_cmd_wmask),
    .lsu2dtcm_icb_cmd_lock(lsu2dtcm_icb_cmd_lock),
    .lsu2dtcm_icb_cmd_excl(lsu2dtcm_icb_cmd_excl),
    .lsu2dtcm_icb_cmd_size(lsu2dtcm_icb_cmd_size),
    .lsu2dtcm_icb_rsp_valid(lsu2dtcm_icb_rsp_valid),
    .lsu2dtcm_icb_rsp_ready(lsu2dtcm_icb_rsp_ready),
    .lsu2dtcm_icb_rsp_err(lsu2dtcm_icb_rsp_err),
    .lsu2dtcm_icb_rsp_excl_ok(1'b0),
    .lsu2dtcm_icb_rsp_rdata(lsu2dtcm_icb_rsp_rdata),
    .ppi_icb_enable(ppi_icb_enable),
    .ppi_region_indic(ppi_region_indic),
    .ppi_icb_cmd_valid(ppi_icb_cmd_valid),
    .ppi_icb_cmd_ready(ppi_icb_cmd_ready),
    .ppi_icb_cmd_addr(ppi_icb_cmd_addr),
    .ppi_icb_cmd_read(ppi_icb_cmd_read),
    .ppi_icb_cmd_wdata(ppi_icb_cmd_wdata),
    .ppi_icb_cmd_wmask(ppi_icb_cmd_wmask),
    .ppi_icb_cmd_lock(ppi_icb_cmd_lock),
    .ppi_icb_cmd_excl(ppi_icb_cmd_excl),
    .ppi_icb_cmd_size(ppi_icb_cmd_size),
    .ppi_icb_rsp_valid(ppi_icb_rsp_valid),
    .ppi_icb_rsp_ready(ppi_icb_rsp_ready),
    .ppi_icb_rsp_err(ppi_icb_rsp_err),
    .ppi_icb_rsp_excl_ok(ppi_icb_rsp_excl_ok),
    .ppi_icb_rsp_rdata(ppi_icb_rsp_rdata),
    .plic_icb_enable(plic_icb_enable),
    .plic_region_indic(plic_region_indic),
    .plic_icb_cmd_valid(plic_icb_cmd_valid),
    .plic_icb_cmd_ready(plic_icb_cmd_ready),
    .plic_icb_cmd_addr(plic_icb_cmd_addr),
    .plic_icb_cmd_read(plic_icb_cmd_read),
    .plic_icb_cmd_wdata(plic_icb_cmd_wdata),
    .plic_icb_cmd_wmask(plic_icb_cmd_wmask),
    .plic_icb_cmd_lock(plic_icb_cmd_lock),
    .plic_icb_cmd_excl(plic_icb_cmd_excl),
    .plic_icb_cmd_size(plic_icb_cmd_size),
    .plic_icb_rsp_valid(plic_icb_rsp_valid),
    .plic_icb_rsp_ready(plic_icb_rsp_ready),
    .plic_icb_rsp_err(plic_icb_rsp_err),
    .plic_icb_rsp_excl_ok(plic_icb_rsp_excl_ok),
    .plic_icb_rsp_rdata(plic_icb_rsp_rdata),
    .clint_icb_enable(clint_icb_enable),
    .clint_region_indic(clint_region_indic),
    .clint_icb_cmd_valid(clint_icb_cmd_valid),
    .clint_icb_cmd_ready(clint_icb_cmd_ready),
    .clint_icb_cmd_addr(clint_icb_cmd_addr),
    .clint_icb_cmd_read(clint_icb_cmd_read),
    .clint_icb_cmd_wdata(clint_icb_cmd_wdata),
    .clint_icb_cmd_wmask(clint_icb_cmd_wmask),
    .clint_icb_cmd_lock(clint_icb_cmd_lock),
    .clint_icb_cmd_excl(clint_icb_cmd_excl),
    .clint_icb_cmd_size(clint_icb_cmd_size),
    .clint_icb_rsp_valid(clint_icb_rsp_valid),
    .clint_icb_rsp_ready(clint_icb_rsp_ready),
    .clint_icb_rsp_err(clint_icb_rsp_err),
    .clint_icb_rsp_excl_ok(clint_icb_rsp_excl_ok),
    .clint_icb_rsp_rdata(clint_icb_rsp_rdata),
    .fio_icb_enable(fio_icb_enable),
    .fio_region_indic(fio_region_indic),
    .fio_icb_cmd_valid(fio_icb_cmd_valid),
    .fio_icb_cmd_ready(fio_icb_cmd_ready),
    .fio_icb_cmd_addr(fio_icb_cmd_addr),
    .fio_icb_cmd_read(fio_icb_cmd_read),
    .fio_icb_cmd_wdata(fio_icb_cmd_wdata),
    .fio_icb_cmd_wmask(fio_icb_cmd_wmask),
    .fio_icb_cmd_lock(fio_icb_cmd_lock),
    .fio_icb_cmd_excl(fio_icb_cmd_excl),
    .fio_icb_cmd_size(fio_icb_cmd_size),
    .fio_icb_rsp_valid(fio_icb_rsp_valid),
    .fio_icb_rsp_ready(fio_icb_rsp_ready),
    .fio_icb_rsp_err(fio_icb_rsp_err),
    .fio_icb_rsp_excl_ok(fio_icb_rsp_excl_ok),
    .fio_icb_rsp_rdata(fio_icb_rsp_rdata),
    .mem_icb_enable(mem_icb_enable),
    .mem_icb_cmd_valid(mem_icb_cmd_valid),
    .mem_icb_cmd_ready(mem_icb_cmd_ready),
    .mem_icb_cmd_addr(mem_icb_cmd_addr),
    .mem_icb_cmd_read(mem_icb_cmd_read),
    .mem_icb_cmd_wdata(mem_icb_cmd_wdata),
    .mem_icb_cmd_wmask(mem_icb_cmd_wmask),
    .mem_icb_cmd_lock(mem_icb_cmd_lock),
    .mem_icb_cmd_excl(mem_icb_cmd_excl),
    .mem_icb_cmd_size(mem_icb_cmd_size),
    .mem_icb_cmd_burst(mem_icb_cmd_burst),
    .mem_icb_cmd_beat(mem_icb_cmd_beat),
    .mem_icb_rsp_valid(mem_icb_rsp_valid),
    .mem_icb_rsp_ready(mem_icb_rsp_ready),
    .mem_icb_rsp_err(mem_icb_rsp_err),
    .mem_icb_rsp_excl_ok(mem_icb_rsp_excl_ok),
    .mem_icb_rsp_rdata(mem_icb_rsp_rdata),
    .nice_mem_holdup(nice_mem_holdup),
    .nice_req_valid(nice_req_valid),
    .nice_req_ready(nice_req_ready),
    .nice_req_inst(nice_req_inst),
    .nice_req_rs1(nice_req_rs1),
    .nice_req_rs2(nice_req_rs2),
    .nice_rsp_multicyc_valid(nice_rsp_multicyc_valid),
    .nice_rsp_multicyc_ready(nice_rsp_multicyc_ready),
    .nice_rsp_multicyc_dat(nice_rsp_multicyc_dat),
    .nice_rsp_multicyc_err(nice_rsp_multicyc_err),
    .nice_icb_cmd_valid(nice_icb_cmd_valid),
    .nice_icb_cmd_ready(nice_icb_cmd_ready),
    .nice_icb_cmd_addr(nice_icb_cmd_addr),
    .nice_icb_cmd_read(nice_icb_cmd_read),
    .nice_icb_cmd_wdata(nice_icb_cmd_wdata),
    .nice_icb_cmd_size(nice_icb_cmd_size),
    .nice_icb_rsp_valid(nice_icb_rsp_valid),
    .nice_icb_rsp_ready(nice_icb_rsp_ready),
    .nice_icb_rsp_rdata(nice_icb_rsp_rdata),
    .nice_icb_rsp_err(nice_icb_rsp_err),
    .clk_aon(clk_aon),
    .clk_core_ifu(clk_core_ifu),
    .clk_core_exu(clk_core_exu),
    .clk_core_lsu(clk_core_lsu),
    .clk_core_biu(clk_core_biu),
    .test_mode(test_mode),
    .rst_n(rst_core)
  );


  e203_itcm_ctrl
  u_e203_itcm_ctrl
  (
    .tcm_cgstop(tcm_cgstop),
    .itcm_active(itcm_active),
    .ifu2itcm_icb_cmd_valid(ifu2itcm_icb_cmd_valid),
    .ifu2itcm_icb_cmd_ready(ifu2itcm_icb_cmd_ready),
    .ifu2itcm_icb_cmd_addr(ifu2itcm_icb_cmd_addr),
    .ifu2itcm_icb_cmd_read(1'b1),
    .ifu2itcm_icb_cmd_wdata({ 64{ 1'b0 } }),
    .ifu2itcm_icb_cmd_wmask({ 64 / 8{ 1'b0 } }),
    .ifu2itcm_icb_rsp_valid(ifu2itcm_icb_rsp_valid),
    .ifu2itcm_icb_rsp_ready(ifu2itcm_icb_rsp_ready),
    .ifu2itcm_icb_rsp_err(ifu2itcm_icb_rsp_err),
    .ifu2itcm_icb_rsp_rdata(ifu2itcm_icb_rsp_rdata),
    .ifu2itcm_holdup(ifu2itcm_holdup),
    .lsu2itcm_icb_cmd_valid(lsu2itcm_icb_cmd_valid),
    .lsu2itcm_icb_cmd_ready(lsu2itcm_icb_rsp_err),
    .lsu2itcm_icb_cmd_addr(lsu2itcm_icb_cmd_addr),
    .lsu2itcm_icb_cmd_read(lsu2itcm_icb_cmd_read),
    .lsu2itcm_icb_cmd_wdata(lsu2itcm_icb_cmd_wdata),
    .lsu2itcm_icb_cmd_wmask(lsu2itcm_icb_cmd_wmask),
    .lsu2itcm_icb_rsp_valid(lsu2itcm_icb_rsp_valid),
    .lsu2itcm_icb_rsp_ready(lsu2itcm_icb_rsp_ready),
    .lsu2itcm_icb_rsp_err(lsu2itcm_icb_cmd_ready),
    .lsu2itcm_icb_rsp_rdata(lsu2itcm_icb_rsp_rdata),
    .itcm_ram_cs(itcm_ram_cs),
    .itcm_ram_we(itcm_ram_we),
    .itcm_ram_addr(itcm_ram_addr),
    .itcm_ram_wem(itcm_ram_wem),
    .itcm_ram_din(itcm_ram_din),
    .itcm_ram_dout(itcm_ram_dout),
    .clk_itcm_ram(clk_itcm_ram),
    .ext2itcm_icb_cmd_valid(ext2itcm_icb_cmd_valid),
    .ext2itcm_icb_cmd_ready(ext2itcm_icb_cmd_ready),
    .ext2itcm_icb_cmd_addr(ext2itcm_icb_cmd_addr),
    .ext2itcm_icb_cmd_read(ext2itcm_icb_cmd_read),
    .ext2itcm_icb_cmd_wdata(ext2itcm_icb_cmd_wdata),
    .ext2itcm_icb_cmd_wmask(ext2itcm_icb_cmd_wmask),
    .ext2itcm_icb_rsp_valid(ext2itcm_icb_rsp_valid),
    .ext2itcm_icb_rsp_ready(ext2itcm_icb_rsp_ready),
    .ext2itcm_icb_rsp_err(ext2itcm_icb_rsp_err),
    .ext2itcm_icb_rsp_rdata(ext2itcm_icb_rsp_rdata),
    .test_mode(test_mode),
    .clk(clk_itcm),
    .rst_n(rst_itcm)
  );


  e203_dtcm_ctrl
  u_e203_dtcm_ctrl
  (
    .tcm_cgstop(tcm_cgstop),
    .dtcm_active(lsu2dtcm_icb_rsp_valid),
    .lsu2dtcm_icb_cmd_valid(lsu2dtcm_icb_cmd_valid),
    .lsu2dtcm_icb_cmd_ready(lsu2dtcm_icb_cmd_ready),
    .lsu2dtcm_icb_cmd_addr(lsu2dtcm_icb_cmd_addr),
    .lsu2dtcm_icb_cmd_read(lsu2dtcm_icb_cmd_read),
    .lsu2dtcm_icb_cmd_wdata(lsu2dtcm_icb_cmd_wdata),
    .lsu2dtcm_icb_cmd_wmask(lsu2dtcm_icb_cmd_wmask),
    .lsu2dtcm_icb_rsp_valid(dtcm_active),
    .lsu2dtcm_icb_rsp_ready(lsu2dtcm_icb_rsp_ready),
    .lsu2dtcm_icb_rsp_err(lsu2dtcm_icb_rsp_err),
    .lsu2dtcm_icb_rsp_rdata(lsu2dtcm_icb_rsp_rdata),
    .dtcm_ram_cs(dtcm_ram_cs),
    .dtcm_ram_we(dtcm_ram_we),
    .dtcm_ram_addr(dtcm_ram_addr),
    .dtcm_ram_wem(dtcm_ram_wem),
    .dtcm_ram_din(dtcm_ram_din),
    .dtcm_ram_dout(dtcm_ram_dout),
    .clk_dtcm_ram(clk_dtcm_ram),
    .ext2dtcm_icb_cmd_valid(ext2dtcm_icb_cmd_valid),
    .ext2dtcm_icb_cmd_ready(ext2dtcm_icb_cmd_ready),
    .ext2dtcm_icb_cmd_addr(ext2dtcm_icb_cmd_addr),
    .ext2dtcm_icb_cmd_read(ext2dtcm_icb_cmd_read),
    .ext2dtcm_icb_cmd_wdata(ext2dtcm_icb_cmd_wdata),
    .ext2dtcm_icb_cmd_wmask(ext2dtcm_icb_cmd_wmask),
    .ext2dtcm_icb_rsp_valid(ext2dtcm_icb_rsp_valid),
    .ext2dtcm_icb_rsp_ready(ext2dtcm_icb_rsp_ready),
    .ext2dtcm_icb_rsp_err(ext2dtcm_icb_rsp_err),
    .ext2dtcm_icb_rsp_rdata(ext2dtcm_icb_rsp_rdata),
    .test_mode(test_mode),
    .clk(clk_dtcm),
    .rst_n(rst_dtcm)
  );

  assign inspect_dbg_irq = dbg_irq_a;
  assign inspect_mem_cmd_valid = mem_icb_cmd_valid;
  assign inspect_mem_cmd_ready = mem_icb_cmd_ready;
  assign inspect_mem_rsp_valid = mem_icb_rsp_valid;
  assign inspect_mem_rsp_ready = mem_icb_rsp_ready;
  assign inspect_core_clk = clk;
  assign core_csr_clk = clk_core_exu;

endmodule

