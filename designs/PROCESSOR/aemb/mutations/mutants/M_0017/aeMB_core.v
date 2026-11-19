

module aeMB_core
(
  iwb_stb_o,
  iwb_adr_o,
  fsl_wre_o,
  fsl_tag_o,
  fsl_stb_o,
  fsl_dat_o,
  fsl_adr_o,
  dwb_wre_o,
  dwb_stb_o,
  dwb_sel_o,
  dwb_dat_o,
  dwb_adr_o,
  sys_rst_i,
  sys_int_i,
  sys_clk_i,
  iwb_dat_i,
  iwb_ack_i,
  fsl_dat_i,
  fsl_ack_i,
  dwb_dat_i,
  dwb_ack_i
);

  parameter ISIZ = 32;
  parameter DSIZ = 32;
  parameter MUL = 1;
  parameter BSF = 1;
  output [DSIZ-1:2] dwb_adr_o;
  output [31:0] dwb_dat_o;
  output [3:0] dwb_sel_o;
  output dwb_stb_o;
  output dwb_wre_o;
  output [6:2] fsl_adr_o;
  output [31:0] fsl_dat_o;
  output fsl_stb_o;
  output [1:0] fsl_tag_o;
  output fsl_wre_o;
  output [ISIZ-1:2] iwb_adr_o;
  output iwb_stb_o;
  input dwb_ack_i;
  input [31:0] dwb_dat_i;
  input fsl_ack_i;
  input [31:0] fsl_dat_i;
  input iwb_ack_i;
  input [31:0] iwb_dat_i;
  input sys_clk_i;
  input sys_int_i;
  input sys_rst_i;

  aeMB_edk32
  #(
    ISIZ,
    DSIZ,
    MUL,
    BSF
  )
  edk32
  (
    .dwb_adr_o(dwb_adr_o[DSIZ-1:2]),
    .dwb_dat_o(dwb_dat_o[31:0]),
    .dwb_sel_o(dwb_sel_o[3:0]),
    .dwb_stb_o(dwb_stb_o),
    .dwb_wre_o(dwb_wre_o),
    .fsl_adr_o(fsl_adr_o[6:2]),
    .fsl_dat_o(fsl_dat_o[31:0]),
    .fsl_stb_o(fsl_stb_o),
    .fsl_tag_o(fsl_tag_o[1:0]),
    .fsl_wre_o(fsl_wre_o),
    .iwb_adr_o(iwb_adr_o[ISIZ-1:2]),
    .iwb_stb_o(iwb_stb_o),
    .dwb_ack_i(dwb_ack_i),
    .dwb_dat_i(dwb_dat_i[0:0]),
    .fsl_ack_i(fsl_ack_i),
    .fsl_dat_i(fsl_dat_i[31:0]),
    .iwb_ack_i(iwb_ack_i),
    .iwb_dat_i(iwb_dat_i[31:0]),
    .sys_int_i(sys_int_i),
    .sys_clk_i(sys_clk_i),
    .sys_rst_i(sys_rst_i)
  );


endmodule

