

module aeMB_edk32
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
  sys_int_i,
  iwb_dat_i,
  iwb_ack_i,
  fsl_dat_i,
  fsl_ack_i,
  dwb_dat_i,
  dwb_ack_i,
  sys_clk_i,
  sys_rst_i
);

  parameter IW = 32;
  parameter DW = 32;
  parameter MUL = 0;
  parameter BSF = 1;
  output [DW-1:2] dwb_adr_o;
  output [31:0] dwb_dat_o;
  output [3:0] dwb_sel_o;
  output dwb_stb_o;
  output dwb_wre_o;
  output [6:2] fsl_adr_o;
  output [31:0] fsl_dat_o;
  output fsl_stb_o;
  output [1:0] fsl_tag_o;
  output fsl_wre_o;
  output [IW-1:2] iwb_adr_o;
  output iwb_stb_o;
  input dwb_ack_i;
  input [31:0] dwb_dat_i;
  input fsl_ack_i;
  input [31:0] fsl_dat_i;
  input iwb_ack_i;
  input [31:0] iwb_dat_i;
  input sys_int_i;
  wire [10:0] rALT;
  wire rBRA;
  wire rDLY;
  wire [31:0] rDWBDI;
  wire [3:0] rDWBSEL;
  wire [15:0] rIMM;
  wire rMSR_BIP;
  wire rMSR_IE;
  wire [1:0] rMXALT;
  wire [2:0] rMXALU;
  wire [1:0] rMXDST;
  wire [1:0] rMXSRC;
  wire [1:0] rMXTGT;
  wire [5:0] rOPC;
  wire [31:2] rPC;
  wire [31:2] rPCLNK;
  wire [4:0] rRA;
  wire [4:0] rRB;
  wire [4:0] rRD;
  wire [31:0] rREGA;
  wire [31:0] rREGB;
  wire [31:0] rRESULT;
  wire [4:0] rRW;
  wire [31:0] rSIMM;
  wire rSTALL;
  wire [31:0] xIREG;
  input sys_clk_i;
  input sys_rst_i;
  wire grst;assign grst = sys_rst_i;
  wire gclk;assign gclk = sys_clk_i;
  wire gena;assign gena = !(dwb_stb_o ^ dwb_ack_i | fsl_stb_o ^ fsl_ack_i | !iwb_ack_i) & !rSTALL;
  wire oena;assign oena = dwb_stb_o ^ dwb_ack_i | fsl_stb_o ^ fsl_ack_i | !iwb_ack_i;

  aeMB_ibuf
  ibuf
  (
    .rIMM(rIMM[15:0]),
    .rRA(rRA[4:0]),
    .rRD(rRD[4:0]),
    .rRB(rRB[4:0]),
    .rALT(rALT[10:0]),
    .rOPC(rOPC[5:0]),
    .rSIMM(rSIMM[31:0]),
    .xIREG(xIREG[31:0]),
    .rSTALL(rSTALL),
    .iwb_stb_o(iwb_stb_o),
    .rBRA(rBRA),
    .rMSR_IE(rMSR_IE),
    .rMSR_BIP(rMSR_BIP),
    .iwb_dat_i(iwb_dat_i[31:0]),
    .iwb_ack_i(iwb_ack_i),
    .sys_int_i(sys_int_i),
    .gclk(gclk),
    .grst(grst),
    .gena(gena),
    .oena(oena)
  );


  aeMB_ctrl
  ctrl
  (
    .rMXDST(rMXDST[1:0]),
    .rMXSRC(rMXSRC[1:0]),
    .rMXTGT(rMXTGT[1:0]),
    .rMXALT(rMXALT[1:0]),
    .rMXALU(rMXALU[2:0]),
    .rRW(rRW[4:0]),
    .dwb_stb_o(dwb_stb_o),
    .dwb_wre_o(dwb_wre_o),
    .fsl_stb_o(fsl_stb_o),
    .fsl_wre_o(fsl_wre_o),
    .rDLY(rDLY),
    .rIMM(rIMM[15:0]),
    .rALT(rALT[10:0]),
    .rOPC(rOPC[5:0]),
    .rRD(rRD[4:0]),
    .rRA(rRA[4:0]),
    .rRB(rRB[4:0]),
    .rPC(rPC[31:2]),
    .rBRA(rBRA),
    .rMSR_IE(rMSR_IE),
    .xIREG(xIREG[31:0]),
    .dwb_ack_i(dwb_ack_i),
    .iwb_ack_i(iwb_ack_i),
    .fsl_ack_i(fsl_ack_i),
    .gclk(gclk),
    .grst(grst),
    .gena(gena)
  );


  aeMB_bpcu
  #(
    IW
  )
  bpcu
  (
    .iwb_adr_o(iwb_adr_o[IW-1:2]),
    .rPC(rPC[31:2]),
    .rPCLNK(rPCLNK[31:2]),
    .rBRA(rBRA),
    .rDLY(rDLY),
    .rMXALT(rMXALT[1:0]),
    .rOPC(rOPC[5:0]),
    .rRD(rRD[4:0]),
    .rRA(rRA[4:0]),
    .rRESULT(rRESULT[31:0]),
    .rDWBDI(rDWBDI[31:0]),
    .rREGA(rREGA[31:0]),
    .gclk(gclk),
    .grst(grst),
    .gena(gena)
  );


  aeMB_regf
  regf
  (
    .rREGA(rREGA[31:0]),
    .rREGB(rREGB[31:0]),
    .rDWBDI(rDWBDI[31:0]),
    .dwb_dat_o(dwb_dat_o[31:0]),
    .fsl_dat_o(fsl_dat_o[31:0]),
    .rOPC(rOPC[5:0]),
    .rRA(rRA[4:0]),
    .rRB(rRB[4:0]),
    .rRW(rRW[4:0]),
    .rRD(rRD[4:0]),
    .rMXDST(rMXDST[1:0]),
    .rPCLNK(rPCLNK[31:2]),
    .rRESULT(rRESULT[31:0]),
    .rDWBSEL(rDWBSEL[3:0]),
    .rBRA(rBRA),
    .rDLY(rDLY),
    .dwb_dat_i(dwb_dat_i[31:0]),
    .fsl_dat_i(fsl_dat_i[31:0]),
    .gclk(gclk),
    .grst(grst),
    .gena(gena)
  );


  aeMB_xecu
  #(
    DW,
    MUL,
    BSF
  )
  xecu
  (
    .dwb_adr_o(dwb_adr_o[DW-1:2]),
    .dwb_sel_o(dwb_sel_o[3:0]),
    .fsl_adr_o(fsl_adr_o[3:2]),
    .fsl_tag_o(fsl_tag_o[1:0]),
    .rRESULT(rRESULT[31:0]),
    .rDWBSEL(rDWBSEL[3:0]),
    .rMSR_IE(rMSR_IE),
    .rMSR_BIP(rMSR_BIP),
    .rREGA(rREGA[31:0]),
    .rREGB(rREGB[31:0]),
    .rMXSRC(rMXSRC[1:0]),
    .rMXTGT(rMXTGT[1:0]),
    .rRA(rRA[4:0]),
    .rRB(rRB[4:0]),
    .rMXALU(rMXALU[2:0]),
    .rBRA(rBRA),
    .rDLY(rDLY),
    .rALT(rALT[10:0]),
    .rSTALL(rSTALL),
    .rSIMM(rSIMM[31:0]),
    .rIMM(rIMM[15:0]),
    .rOPC(rOPC[5:0]),
    .rRD(rRD[4:0]),
    .rDWBDI(rDWBDI[31:0]),
    .rPC(rPC[31:2]),
    .gclk(gclk),
    .grst(grst),
    .gena(gena)
  );


endmodule

