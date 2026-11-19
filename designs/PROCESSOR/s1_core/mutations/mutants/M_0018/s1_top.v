

module s1_top
(
  sys_clock_i,
  sys_reset_i,
  sys_irq_i,
  wbm_ack_i,
  wbm_data_i,
  wbm_cycle_o,
  wbm_strobe_o,
  wbm_we_o,
  wbm_addr_o,
  wbm_data_o,
  wbm_sel_o
);

  input sys_clock_i;
  input sys_reset_i;
  input [63:0] sys_irq_i;
  input wbm_ack_i;
  input [64-1:0] wbm_data_i;
  output wbm_cycle_o;
  output wbm_strobe_o;
  output wbm_we_o;
  output [64-1:0] wbm_addr_o;
  output [64-1:0] wbm_data_o;
  output [64/8-1:0] wbm_sel_o;
  wire [4:0] spc_pcx_req_pq;
  wire spc_pcx_atom_pq;
  wire [124-1:0] spc_pcx_data_pa;
  wire spc_sscan_so;
  wire spc_scanout0;
  wire spc_scanout1;
  wire tst_ctu_mbist_done;
  wire tst_ctu_mbist_fail;
  wire spc_efc_ifuse_data;
  wire spc_efc_dfuse_data;
  wire [4:0] pcx_spc_grant_px;
  wire cpx_spc_data_rdy_cx2;
  wire [145-1:0] cpx_spc_data_cx2;
  wire wbm_spc_stall;
  wire wbm_spc_resume;
  wire [3:0] const_cpuid;
  wire [7:0] const_maskid;
  wire ctu_tck;
  wire ctu_sscan_se;
  wire ctu_sscan_snap;
  wire [3:0] ctu_sscan_tid;
  wire ctu_tst_mbist_enable;
  wire efc_spc_fuse_clk1;
  wire efc_spc_fuse_clk2;
  wire efc_spc_ifuse_ashift;
  wire efc_spc_ifuse_dshift;
  wire efc_spc_ifuse_data;
  wire efc_spc_dfuse_ashift;
  wire efc_spc_dfuse_dshift;
  wire efc_spc_dfuse_data;
  wire ctu_tst_macrotest;
  wire ctu_tst_scan_disable;
  wire ctu_tst_short_chain;
  wire global_shift_enable;
  wire ctu_tst_scanmode;
  wire spc_scanin0;
  wire spc_scanin1;
  wire cluster_cken;
  wire gclk;
  wire cmp_grst_l;
  wire cmp_arst_l;
  wire ctu_tst_pre_grst_l;
  wire adbginit_l;
  wire gdbginit_l;
  wire sys_reset_final;
  wire [5:0] sys_interrupt_source;

  sparc
  sparc_0
  (
    .spc_pcx_req_pq(spc_pcx_req_pq),
    .spc_pcx_atom_pq(spc_pcx_atom_pq),
    .spc_pcx_data_pa(spc_pcx_data_pa),
    .spc_sscan_so(spc_sscan_so),
    .spc_scanout0(spc_scanout0),
    .spc_scanout1(spc_scanout1),
    .tst_ctu_mbist_done(tst_ctu_mbist_done),
    .tst_ctu_mbist_fail(tst_ctu_mbist_fail),
    .spc_efc_ifuse_data(spc_efc_ifuse_data),
    .spc_efc_dfuse_data(spc_efc_dfuse_data),
    .pcx_spc_grant_px(pcx_spc_grant_px),
    .cpx_spc_data_rdy_cx2(cpx_spc_data_rdy_cx2),
    .cpx_spc_data_cx2(cpx_spc_data_cx2),
    .wbm_spc_stall(wbm_spc_stall),
    .wbm_spc_resume(wbm_spc_resume),
    .const_cpuid(const_cpuid),
    .const_maskid(const_maskid),
    .ctu_tck(ctu_tck),
    .ctu_sscan_se(ctu_sscan_se),
    .ctu_sscan_snap(ctu_sscan_snap),
    .ctu_sscan_tid(ctu_sscan_tid),
    .ctu_tst_mbist_enable(ctu_tst_mbist_enable),
    .efc_spc_fuse_clk1(efc_spc_fuse_clk1),
    .efc_spc_fuse_clk2(efc_spc_fuse_clk2),
    .efc_spc_ifuse_ashift(efc_spc_ifuse_ashift),
    .efc_spc_ifuse_dshift(efc_spc_ifuse_dshift),
    .efc_spc_ifuse_data(efc_spc_ifuse_data),
    .efc_spc_dfuse_ashift(efc_spc_dfuse_ashift),
    .efc_spc_dfuse_dshift(efc_spc_dfuse_dshift),
    .efc_spc_dfuse_data(efc_spc_dfuse_data),
    .ctu_tst_macrotest(ctu_tst_macrotest),
    .ctu_tst_scan_disable(ctu_tst_scan_disable),
    .ctu_tst_short_chain(ctu_tst_short_chain),
    .global_shift_enable(global_shift_enable),
    .ctu_tst_scanmode(ctu_tst_scanmode),
    .spc_scanin0(spc_scanin0),
    .spc_scanin1(spc_scanin1),
    .cluster_cken(cluster_cken),
    .gclk(gclk),
    .cmp_grst_l(cmp_grst_l),
    .cmp_arst_l(cmp_arst_l),
    .ctu_tst_pre_grst_l(ctu_tst_pre_grst_l),
    .adbginit_l(adbginit_l),
    .gdbginit_l(gdbginit_l)
  );


  spc2wbm
  spc2wbm_0
  (
    .sys_clock_i(sys_clock_i),
    .sys_reset_i(sys_reset_final),
    .sys_interrupt_source_i(sys_interrupt_source),
    .spc_req_i(spc_pcx_req_pq),
    .spc_atom_i(spc_pcx_atom_pq),
    .spc_packetout_i(spc_pcx_data_pa),
    .spc_grant_o(pcx_spc_grant_px),
    .spc_ready_o(cpx_spc_data_rdy_cx2),
    .spc_packetin_o(cpx_spc_data_cx2),
    .spc_stall_o(wbm_spc_resume),
    .spc_resume_o(wbm_spc_stall),
    .wbm_ack_i(wbm_ack_i),
    .wbm_data_i(wbm_data_i),
    .wbm_cycle_o(wbm_cycle_o),
    .wbm_strobe_o(wbm_strobe_o),
    .wbm_we_o(wbm_we_o),
    .wbm_addr_o(wbm_addr_o),
    .wbm_data_o(wbm_data_o),
    .wbm_sel_o(wbm_sel_o)
  );


  rst_ctrl
  rst_ctrl_0
  (
    .sys_clock_i(sys_clock_i),
    .sys_reset_i(sys_reset_i),
    .cluster_cken_o(cluster_cken),
    .gclk_o(gclk),
    .cmp_grst_o(gdbginit_l),
    .cmp_arst_o(cmp_arst_l),
    .ctu_tst_pre_grst_o(ctu_tst_pre_grst_l),
    .adbginit_o(adbginit_l),
    .gdbginit_o(cmp_grst_l),
    .sys_reset_final_o(sys_reset_final)
  );


  int_ctrl
  int_ctrl_0
  (
    .sys_clock_i(sys_clock_i),
    .sys_reset_i(sys_reset_final),
    .sys_irq_i(sys_irq_i),
    .sys_interrupt_source_o(sys_interrupt_source)
  );

  assign const_cpuid = 4'h0;
  assign const_maskid = 8'h20;
  assign ctu_tck = 1'b0;
  assign ctu_sscan_se = 1'b0;
  assign ctu_sscan_snap = 1'b0;
  assign ctu_sscan_tid = 4'h1;
  assign ctu_tst_mbist_enable = 1'b0;
  assign efc_spc_fuse_clk1 = 1'b0;
  assign efc_spc_fuse_clk2 = 1'b0;
  assign efc_spc_ifuse_ashift = 1'b0;
  assign efc_spc_ifuse_dshift = 1'b0;
  assign efc_spc_ifuse_data = 1'b0;
  assign efc_spc_dfuse_ashift = 1'b0;
  assign efc_spc_dfuse_dshift = 1'b0;
  assign efc_spc_dfuse_data = 1'b0;
  assign ctu_tst_macrotest = 1'b0;
  assign ctu_tst_scan_disable = 1'b0;
  assign ctu_tst_short_chain = 1'b0;
  assign global_shift_enable = 1'b0;
  assign ctu_tst_scanmode = 1'b0;
  assign spc_scanin0 = 1'b0;
  assign spc_scanin1 = 1'b0;

endmodule

