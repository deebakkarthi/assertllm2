

module e203_clk_ctrl
(
  input clk,
  input rst_n,
  input test_mode,
  input core_cgstop,
  output clk_aon,
  input core_ifu_active,
  input core_exu_active,
  input core_lsu_active,
  input core_biu_active,
  input itcm_active,
  output itcm_ls,
  input dtcm_active,
  output dtcm_ls,
  output clk_core_ifu,
  output clk_core_exu,
  output clk_core_lsu,
  output clk_core_biu,
  output clk_itcm,
  output clk_dtcm,
  input core_wfi
);

  wire ifu_clk_en;assign ifu_clk_en = core_cgstop & (core_ifu_active & ~core_wfi);
  wire exu_clk_en;assign exu_clk_en = core_cgstop | core_exu_active;
  wire lsu_clk_en;assign lsu_clk_en = core_cgstop | core_lsu_active;
  wire biu_clk_en;assign biu_clk_en = core_cgstop | core_biu_active;

  e203_clkgate
  u_ifu_clkgate
  (
    .clk_in(clk),
    .test_mode(test_mode),
    .clock_en(ifu_clk_en),
    .clk_out(clk_core_ifu)
  );


  e203_clkgate
  u_exu_clkgate
  (
    .clk_in(clk),
    .test_mode(test_mode),
    .clock_en(exu_clk_en),
    .clk_out(clk_core_exu)
  );


  e203_clkgate
  u_lsu_clkgate
  (
    .clk_in(clk),
    .test_mode(test_mode),
    .clock_en(lsu_clk_en),
    .clk_out(clk_core_lsu)
  );


  e203_clkgate
  u_biu_clkgate
  (
    .clk_in(clk),
    .test_mode(test_mode),
    .clock_en(biu_clk_en),
    .clk_out(clk_core_biu)
  );

  wire itcm_active_r;

  sirv_gnrl_dffr
  #(
    1
  )
  itcm_active_dffr
  (
    itcm_active,
    itcm_active_r,
    clk,
    rst_n
  );

  wire itcm_clk_en;assign itcm_clk_en = core_cgstop | itcm_active | itcm_active_r;
  assign itcm_ls = ~itcm_clk_en;

  e203_clkgate
  u_itcm_clkgate
  (
    .clk_in(clk),
    .test_mode(test_mode),
    .clock_en(itcm_clk_en),
    .clk_out(clk_itcm)
  );

  wire dtcm_active_r;

  sirv_gnrl_dffr
  #(
    1
  )
  dtcm_active_dffr
  (
    dtcm_active,
    dtcm_active_r,
    clk,
    rst_n
  );

  wire dtcm_clk_en;assign dtcm_clk_en = core_cgstop | dtcm_active | dtcm_active_r;
  assign dtcm_ls = ~dtcm_clk_en;

  e203_clkgate
  u_dtcm_clkgate
  (
    .clk_in(clk),
    .test_mode(test_mode),
    .clock_en(dtcm_clk_en),
    .clk_out(clk_dtcm)
  );

  assign clk_aon = clk;

endmodule

