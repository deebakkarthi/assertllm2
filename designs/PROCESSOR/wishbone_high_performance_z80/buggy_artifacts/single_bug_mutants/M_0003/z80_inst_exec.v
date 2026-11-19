

module z80_inst_exec
(
  br_eq0,
  cr_eq0,
  upd_ar,
  upd_br,
  upd_cr,
  upd_dr,
  upd_er,
  upd_hr,
  upd_lr,
  upd_fr,
  ar,
  fr,
  br,
  cr,
  dr,
  er,
  hr,
  lr,
  intr,
  ixr,
  iyr,
  add16,
  alu8_out,
  sh_alu,
  bit_alu,
  exec_ir2,
  exec_decbc,
  exec_decb,
  adr_alu,
  blk_mv_upd_hl,
  blk_mv_upd_de,
  ir2,
  clk,
  rst,
  nn,
  sp,
  ir2dd,
  ir2fd
);

  output br_eq0;
  output cr_eq0;
  output upd_ar;output upd_br;output upd_cr;output upd_dr;output upd_er;output upd_hr;output upd_lr;output upd_fr;
  output [7:0] ar;output [7:0] fr;output [7:0] br;output [7:0] cr;output [7:0] dr;output [7:0] er;output [7:0] hr;output [7:0] lr;output [7:0] intr;
  output [15:0] ixr;output [15:0] iyr;
  output [15:0] add16;
  output [7:0] alu8_out;
  output [7:0] sh_alu;
  output [7:0] bit_alu;
  input exec_ir2;
  input exec_decbc;
  input exec_decb;
  input [9:0] ir2;
  input clk;
  input rst;
  input [15:0] nn;input [15:0] sp;
  input ir2dd;
  input ir2fd;
  input [15:0] adr_alu;
  input blk_mv_upd_hl;
  input blk_mv_upd_de;
  parameter NOP = 10'h00;parameter LDsBC_NN = 10'h01;parameter LDs6BC7_A = 10'h02;parameter INCsBC = 10'h03;parameter INCsB = 10'h04;parameter DECsB = 10'h05;parameter LDsB_N = 10'h06;parameter RLCA = 10'h07;parameter EXsAF_AFp = 10'h08;parameter ADDsHL_BC = 10'h09;parameter LDsA_6BC7 = 10'h0A;parameter DECsBC = 10'h0B;parameter INCsC = 10'h0C;parameter DECsC = 10'h0D;parameter LDsC_N = 10'h0E;parameter RRCA = 10'h0F;parameter DJNZs$t2 = 10'h10;parameter LDsDE_NN = 10'h11;parameter LDs6DE7_A = 10'h12;parameter INCsDE = 10'h13;parameter INCsD = 10'h14;parameter DECsD = 10'h15;parameter LDsD_N = 10'h16;parameter RLA = 10'h17;parameter JRs$t2 = 10'h18;parameter ADDsHL_DE = 10'h19;parameter LDsA_6DE7 = 10'h1A;parameter DECsDE = 10'h1B;parameter INCsE = 10'h1C;parameter DECsE = 10'h1D;parameter LDsE_N = 10'h1E;parameter RRA = 10'h1F;parameter JRsNZ_$t2 = 10'h20;parameter LDsHL_NN = 10'h21;parameter LDs6NN7_HL = 10'h22;parameter INCsHL = 10'h23;parameter INCsH = 10'h24;parameter DECsH = 10'h25;parameter LDsH_N = 10'h26;parameter DAA = 10'h27;parameter JRsZ_$t2 = 10'h28;parameter ADDsHL_HL = 10'h29;parameter LDsHL_6NN7 = 10'h2A;parameter DECsHL = 10'h2B;parameter INCsL = 10'h2C;parameter DECsL = 10'h2D;parameter LDsL_N = 10'h2E;parameter CPL = 10'h2F;parameter JRsNC_$t2 = 10'h30;parameter LDsSP_NN = 10'h31;parameter LDs6NN7_A = 10'h32;parameter INCsSP = 10'h33;parameter INCs6HL7 = 10'h34;parameter DECs6HL7 = 10'h35;parameter LDs6HL7_N = 10'h36;parameter SCF = 10'h37;parameter JRsC_$t2 = 10'h38;parameter ADDsHL_SP = 10'h39;parameter LDsA_6NN7 = 10'h3A;parameter DECsSP = 10'h3B;parameter INCsA = 10'h3C;parameter DECsA = 10'h3D;parameter LDsA_N = 10'h3E;parameter CCF = 10'h3F;parameter LDsB_B = 10'h40;parameter LDsB_C = 10'h41;parameter LDsB_D = 10'h42;parameter LDsB_E = 10'h43;parameter LDsB_H = 10'h44;parameter LDsB_L = 10'h45;parameter LDsB_6HL7 = 10'h46;parameter LDsB_A = 10'h47;parameter LDsC_B = 10'h48;parameter LDsC_C = 10'h49;parameter LDsC_D = 10'h4A;parameter LDsC_E = 10'h4B;parameter LDsC_H = 10'h4C;parameter LDsC_L = 10'h4D;parameter LDsC_6HL7 = 10'h4E;parameter LDsC_A = 10'h4F;parameter LDsD_B = 10'h50;parameter LDsD_C = 10'h51;parameter LDsD_D = 10'h52;parameter LDsD_E = 10'h53;parameter LDsD_H = 10'h54;parameter LDsD_L = 10'h55;parameter LDsD_6HL7 = 10'h56;parameter LDsD_A = 10'h57;parameter LDsE_B = 10'h58;parameter LDsE_C = 10'h59;parameter LDsE_D = 10'h5A;parameter LDsE_E = 10'h5B;parameter LDsE_H = 10'h5C;parameter LDsE_L = 10'h5D;parameter LDsE_6HL7 = 10'h5E;parameter LDsE_A = 10'h5F;parameter LDsH_B = 10'h60;parameter LDsH_C = 10'h61;parameter LDsH_D = 10'h62;parameter LDsH_E = 10'h63;parameter LDsH_H = 10'h64;parameter LDsH_L = 10'h65;parameter LDsH_6HL7 = 10'h66;parameter LDsH_A = 10'h67;parameter LDsL_B = 10'h68;parameter LDsL_C = 10'h69;parameter LDsL_D = 10'h6A;parameter LDsL_E = 10'h6B;parameter LDsL_H = 10'h6C;parameter LDsL_L = 10'h6D;parameter LDsL_6HL7 = 10'h6E;parameter LDsL_A = 10'h6F;parameter LDs6HL7_B = 10'h70;parameter LDs6HL7_C = 10'h71;parameter LDs6HL7_D = 10'h72;parameter LDs6HL7_E = 10'h73;parameter LDs6HL7_H = 10'h74;parameter LDs6HL7_L = 10'h75;parameter HALT = 10'h76;parameter LDs6HL7_A = 10'h77;parameter LDsA_B = 10'h78;parameter LDsA_C = 10'h79;parameter LDsA_D = 10'h7A;parameter LDsA_E = 10'h7B;parameter LDsA_H = 10'h7C;parameter LDsA_L = 10'h7D;parameter LDsA_6HL7 = 10'h7E;parameter LDsA_A = 10'h7F;parameter ADDsA_B = 10'h80;parameter ADDsA_C = 10'h81;parameter ADDsA_D = 10'h82;parameter ADDsA_E = 10'h83;parameter ADDsA_H = 10'h84;parameter ADDsA_L = 10'h85;parameter ADDsA_6HL7 = 10'h86;parameter ADDsA_A = 10'h87;parameter ADCsA_B = 10'h88;parameter ADCsA_C = 10'h89;parameter ADCsA_D = 10'h8A;parameter ADCsA_E = 10'h8B;parameter ADCsA_H = 10'h8C;parameter ADCsA_L = 10'h8D;parameter ADCsA_6HL7 = 10'h8E;parameter ADCsA_A = 10'h8F;parameter SUBsB = 10'h90;parameter SUBsC = 10'h91;parameter SUBsD = 10'h92;parameter SUBsE = 10'h93;parameter SUBsH = 10'h94;parameter SUBsL = 10'h95;parameter SUBs6HL7 = 10'h96;parameter SUBsA = 10'h97;parameter SBCsB = 10'h98;parameter SBCsC = 10'h99;parameter SBCsD = 10'h9A;parameter SBCsE = 10'h9B;parameter SBCsH = 10'h9C;parameter SBCsL = 10'h9D;parameter SBCs6HL7 = 10'h9E;parameter SBCsA = 10'h9F;parameter ANDsB = 10'hA0;parameter ANDsC = 10'hA1;parameter ANDsD = 10'hA2;parameter ANDsE = 10'hA3;parameter ANDsH = 10'hA4;parameter ANDsL = 10'hA5;parameter ANDs6HL7 = 10'hA6;parameter ANDsA = 10'hA7;parameter XORsB = 10'hA8;parameter XORsC = 10'hA9;parameter XORsD = 10'hAA;parameter XORsE = 10'hAB;parameter XORsH = 10'hAC;parameter XORsL = 10'hAD;parameter XORs6HL7 = 10'hAE;parameter XORsA = 10'hAF;parameter ORsB = 10'hB0;parameter ORsC = 10'hB1;parameter ORsD = 10'hB2;parameter ORsE = 10'hB3;parameter ORsH = 10'hB4;parameter ORsL = 10'hB5;parameter ORs6HL7 = 10'hB6;parameter ORsA = 10'hB7;parameter CPsB = 10'hB8;parameter CPsC = 10'hB9;parameter CPsD = 10'hBA;parameter CPsE = 10'hBB;parameter CPsH = 10'hBC;parameter CPsL = 10'hBD;parameter CPs6HL7 = 10'hBE;parameter CPsA = 10'hBF;parameter RETsNZ = 10'hC0;parameter POPsBC = 10'hC1;parameter JPsNZ = 10'hC2;parameter JP = 10'hC3;parameter CALLsNZ_NN = 10'hC4;parameter PUSHsBC = 10'hC5;parameter ADDsA_N = 10'hC6;parameter RSTs0 = 10'hC7;parameter RETsZ = 10'hC8;parameter RET = 10'hC9;parameter JPsZ = 10'hCA;parameter CALLsZ_NN = 10'hCC;parameter CBgrp = 10'hCB;parameter CALLsNN = 10'hCD;parameter ADCsA_N = 10'hCE;parameter RSTs8H = 10'hCF;parameter RETsNC = 10'hD0;parameter POPsDE = 10'hD1;parameter JPsNC = 10'hD2;parameter OUTs6N7_A = 10'hD3;parameter CALLsNC_NN = 10'hD4;parameter PUSHsDE = 10'hD5;parameter SUBsN = 10'hD6;parameter RSTs10H = 10'hD7;parameter RETsC = 10'hD8;parameter EXX = 10'hD9;parameter JPsC = 10'hDA;parameter INsA_6N7 = 10'hDB;parameter CALLsC_NN = 10'hDC;parameter DDgrp = 10'hDD;parameter SBCsA_N = 10'hDE;parameter RSTs18H = 10'hDF;parameter RETsPO = 10'hE0;parameter POPsHL = 10'hE1;parameter JPsPO = 10'hE2;parameter EXs6SP7_HL = 10'hE3;parameter CALLsPO_NN = 10'hE4;parameter PUSHsHL = 10'hE5;parameter ANDsN = 10'hE6;parameter RSTs20H = 10'hE7;parameter RETsPE = 10'hE8;parameter JPsHL = 10'hE9;parameter JPsPE = 10'hEA;parameter EXsDE_HL = 10'hEB;parameter CALLsPE_NN = 10'hEC;parameter EDgrp = 10'hED;parameter XORsN = 10'hEE;parameter RSTs28H = 10'hEF;parameter RETsP = 10'hF0;parameter POPsAF = 10'hF1;parameter JPsP = 10'hF2;parameter DI = 10'hF3;parameter CALLsP_NN = 10'hF4;parameter PUSHsAF = 10'hF5;parameter ORsN = 10'hF6;parameter RSTs30H = 10'hF7;parameter RETsM = 10'hF8;parameter LDsSP_HL = 10'hF9;parameter JPsM = 10'hFA;parameter EI = 10'hFB;parameter CALLsM_NN = 10'hFC;parameter FDgrp = 10'hFD;parameter CPsN = 10'hFE;parameter RSTs38H = 10'hFF;parameter CB_RLC = 7'b01_00_000;parameter CB_RRC = 7'b01_00_001;parameter CB_RL = 7'b01_00_010;parameter CB_RR = 7'b01_00_011;parameter CB_SLA = 7'b01_00_100;parameter CB_SRA = 7'b01_00_101;parameter CB_SLL = 7'b01_00_110;parameter CB_SRL = 7'b01_00_111;parameter CB_BIT = 4'b01_01;parameter CB_RES = 4'b01_10;parameter CB_SET = 4'b01_11;parameter CB_MEM = 3'b110;parameter ED_IMs0 = 10'h246;parameter ED_LDsI_A = 10'h247;parameter ED_IMs1 = 10'h256;parameter ED_LDsA_I = 10'h257;parameter ED_IMs2 = 10'h25E;parameter ED_RRD = 10'h267;parameter ED_RLD = 10'h26F;parameter ED_LDI = 10'h2A0;parameter ED_CPI = 10'h2A1;parameter ED_INI = 10'h2A2;parameter ED_OUTI = 10'h2A3;parameter ED_LDD = 10'h2A8;parameter ED_CPD = 10'h2A9;parameter ED_IND = 10'h2AA;parameter ED_OUTD = 10'h2AB;parameter ED_LDIR = 10'h2B0;parameter ED_CPIR = 10'h2B1;parameter ED_INIR = 10'h2B2;parameter ED_OTIR = 10'h2B3;parameter ED_LDDR = 10'h2B8;parameter ED_CPDR = 10'h2B9;parameter ED_INDR = 10'h2BA;parameter ED_OTDR = 10'h2BB;parameter ED_INsREG_6C7 = 7'b1001___000;parameter ED_OUTs6C7_REG = 7'b1001___001;parameter ED_SBCsHL_REG = 8'b1001__0010;parameter ED_ADCsHL_REG = 8'b1001__1010;parameter ED_LDs6NN7_REG = 8'b1001__0011;parameter ED_LDsREG_6NN7 = 8'b1001__1011;parameter ED_NEG = 7'b1001___100;parameter ED_RETN = 7'b1001___101;parameter ED_RETI = 10'h24D;parameter DBL_REG_BC = 2'b00;parameter DBL_REG_DE = 2'b01;parameter DBL_REG_HL = 2'b10;parameter DBL_REG_SP = 2'b11;parameter REG8_B = 3'b000;parameter REG8_C = 3'b001;parameter REG8_D = 3'b010;parameter REG8_E = 3'b011;parameter REG8_H = 3'b100;parameter REG8_L = 3'b101;parameter REG8_MEM = 3'b110;parameter REG8_A = 3'b111;
  wire [7:0] src_hr;
  wire [7:0] src_lr;
  wire [15:0] src_a;wire [15:0] src_b;
  wire [15:0] add16;
  wire sf;wire zf;wire f5f;wire hf;wire f3f;wire pvf;wire nf;wire cf;
  wire [7:0] daa_alu;
  wire daa_cry;
  wire upd_ar;wire upd_br;wire upd_cr;wire upd_dr;wire upd_er;wire upd_fr;wire upd_hr;wire upd_lr;
  wire c_8out3;
  wire [7:0] add_8bit;
  wire [15:0] src_dblhr;
  wire [7:0] src_pqr20;
  wire [7:0] src_pqr53;
  wire [15:0] src_dbl;
  wire [7:0] alu8_fr;
  wire alu8_nf;
  wire c_8out7;
  wire alu8_cry;
  wire alu8_pvf;
  wire alu8_hcry;
  wire [7:0] alu8_out;
  wire add16_ofl;
  wire c_16out7;
  wire c_16out11;
  wire c_16out15;
  wire c_16in0;
  wire sh_cry;
  wire [7:0] sh_alu;
  wire sh_alu_act;
  wire bit_alu_act;
  wire [7:0] bit_alu;
  wire [7:0] decc_alu;
  wire [7:0] decb_alu;
  wire upd_a_alu8;
  wire up_a_sh_alu;
  wire up_a_src_pqr;
  wire up_a_n;
  wire upd_b_alu8;
  wire up_b_src_pqr;
  wire up_b_add16;
  wire [7:0] sh_src;
  wire up_c_add16;
  wire upd_c_alu8;
  wire up_c_src_pqr;
  wire up_d_add16;
  wire upd_d_alu8;
  wire up_d_src_pqr;
  wire up_e_add16;
  wire upd_e_alu8;
  wire up_e_src_pqr;
  wire up_h_add16;
  wire upd_h_alu8;
  wire upd_h_src_pqr;
  wire up_l_add16;
  wire upd_l_alu8;
  wire upd_l_src_pqr;
  wire upd_bc_cpi;
  wire upd_fr_alu8;
  wire upd_fr_add16;
  wire upd_fr_edadd16;
  wire upd_fr_sh;
  wire upd_fr_cbsh;
  wire ed_blk_cp;
  wire c_8in0;
  reg [7:0] ar;reg [7:0] fr;reg [7:0] br;reg [7:0] cr;reg [7:0] dr;reg [7:0] er;reg [7:0] hr;reg [7:0] lr;reg [7:0] intr;
  reg [7:0] ap;reg [7:0] fp;reg [7:0] bp;reg [7:0] cp;reg [7:0] dp;reg [7:0] ep;reg [7:0] hp;reg [7:0] lp;
  reg [15:0] ixr;reg [15:0] iyr;
  assign src_hr = (ir2dd)? ixr[15:8] : 
                  (ir2fd)? iyr[15:8] : hr;
  assign src_lr = (ir2dd)? ixr[7:0] : 
                  (ir2fd)? iyr[7:0] : lr;
  assign src_dblhr = (ir2dd)? ixr : 
                     (ir2fd)? iyr : { hr, lr };
  assign br_eq0 = ~|br;
  assign cr_eq0 = ~|cr;
  assign src_pqr20 = { 8{ ir2[2:0] == REG8_B } } & br | { 8{ ir2[2:0] == REG8_C } } & cr | { 8{ ir2[2:0] == REG8_D } } & dr | { 8{ ir2[2:0] == REG8_E } } & er | { 8{ ir2[2:0] == REG8_H } } & src_hr | { 8{ ir2[2:0] == REG8_L } } & src_lr | { 8{ ir2[2:0] == REG8_MEM } } & nn[15:8] | { 8{ ir2[2:0] == REG8_A } } & ar;
  assign src_pqr53 = { 8{ ir2[5:3] == REG8_B } } & br | { 8{ ir2[5:3] == REG8_C } } & cr | { 8{ ir2[5:3] == REG8_D } } & dr | { 8{ ir2[5:3] == REG8_E } } & er | { 8{ ir2[5:3] == REG8_H } } & src_hr | { 8{ ir2[5:3] == REG8_L } } & src_lr | { 8{ ir2[5:3] == REG8_MEM } } & nn[15:8] | { 8{ ir2[5:3] == REG8_A } } & ar;
  assign src_dbl = { 16{ ir2[5:4] == 2'b00 } } & { br, cr } | { 16{ ir2[5:4] == 2'b01 } } & { dr, er } | { 16{ ir2[5:4] == 2'b10 } } & src_dblhr | { 16{ ir2[5:4] == 2'b11 } } & sp;
  assign sh_src = (ir2[8] & ir2dd)? nn[15:8] : 
                  (ir2[8] & ir2fd)? nn[15:8] : 
                  (ir2[8])? src_pqr20 : ar;
  wire [7:0] src_pqri;
  wire [7:0] src_aor_cnst;assign src_aor_cnst = (ed_blk_cp)? ar : 
                        (ir2[9])? 8'h0 : 
                        (ir2[7])? ar : 
                        (ir2[0])? 8'hff : 8'h00;
  assign alu8_fr = { alu8_out[7], ~|alu8_out, alu8_out[5], alu8_hcry, alu8_out[3], alu8_pvf, alu8_nf, alu8_cry };
  assign alu8_pvf = (ir2[7] & ((ir2[5:3] == 7'b100) | (ir2[5:3] == 7'b101) | (ir2[5:3] == 7'b110)))? ~^alu8_out : (src_aor_cnst[7] == src_pqri[7]) & (src_aor_cnst[7] != alu8_out[7]);
  assign alu8_nf = (ir2[7:3] == 5'b10010) | (ir2[7:3] == 5'b10011) | (ir2[7:6] == 2'b00) & ir2[0] | ir2[9];
  assign { c_8out3, add_8bit[3:0] } = { 1'b0, src_aor_cnst[3:0] } + { 1'b0, src_pqri[3:0] } + { 4'b0, c_8in0 };
  assign { c_8out7, add_8bit[7:4] } = { 1'b0, src_aor_cnst[7:4] } + { 1'b0, src_pqri[7:4] } + { 4'b0, c_8out3 };
  assign { alu8_cry, alu8_hcry, alu8_out, src_pqri, c_8in0 } = (ed_blk_cp)? { c_8out7, c_8out3, add_8bit, ~nn[15:8], 1'h1 } : { 19{ ir2[7] & (ir2[5:3] == 3'b000) } } & { c_8out7, c_8out3, add_8bit, src_pqr20, 1'b0 } | { 19{ ir2[7] & (ir2[5:3] == 5'b001) } } & { c_8out7, c_8out3, add_8bit, src_pqr20, cf } | { 19{ ir2[7] & (ir2[5:3] == 5'b010) } } & { ~c_8out7, c_8out3, add_8bit, ~src_pqr20, 1'h1 } | { 19{ ir2[7] & (ir2[5:3] == 5'b011) } } & { ~c_8out7, c_8out3, add_8bit, ~src_pqr20, ~cf } | { 19{ ir2[7] & (ir2[5:3] == 5'b100) } } & { 1'b0, 1'b1, ar & src_pqr20, src_pqr20, 1'b0 } | { 19{ ir2[7] & (ir2[5:3] == 5'b101) } } & { 1'b0, 1'b0, ar ^ src_pqr20, src_pqr20, 1'b0 } | { 19{ ir2[7] & (ir2[5:3] == 5'b110) } } & { 1'b0, 1'b0, ar | src_pqr20, src_pqr20, 1'b0 } | { 19{ ir2[7] & (ir2[5:3] == 5'b111) } } & { ~c_8out7, c_8out3, add_8bit, ~src_pqr20, 1'h1 } | { 19{ (ir2[7:6] == 2'b00) & ~ir2[0] } } & { cf, c_8out3, add_8bit, src_pqr53, 1'h1 } | { 19{ (ir2[7:6] == 2'b00) & ir2[0] } } & { cf, c_8out3, add_8bit, src_pqr53, 1'h0 } | { 19{ ir2[7:6] == 2'b01 } } & { ~c_8out7, c_8out3, add_8bit, ~ar, 1'h1 };
  assign add16_ofl = (src_a[15] == src_b[15]) & (src_a[15] != add16[15]);
  assign { c_16out7, add16[7:0] } = { 1'b0, src_a[7:0] } + { 1'b0, src_b[7:0] } + { 8'b0, c_16in0 };
  assign { c_16out11, add16[11:8] } = { 1'b0, src_a[11:8] } + { 1'b0, src_b[11:8] } + { 4'b0, c_16out7 };
  assign { c_16out15, add16[15:12] } = { 1'b0, src_a[15:12] } + { 1'b0, src_b[15:12] } + { 4'b0, c_16out11 };
  assign { src_a, src_b, c_16in0 } = { 33{ ir2[3:0] == 4'h9 } } & { src_dblhr, src_dbl, 1'b0 } | { 33{ ir2[3:0] == 4'hb } } & { 16'hffff, src_dbl, 1'b0 } | { 33{ ir2[3:0] == 4'h3 } } & { 16'h0001, src_dbl, 1'b0 } | { 33{ ir2[3:0] == 4'h2 } } & { src_dblhr, ~src_dbl, ~cf } | { 33{ ir2[3:0] == 4'ha } } & { src_dblhr, src_dbl, cf };
  assign { sh_cry, sh_alu } = { 9{ ir2[5:3] == 3'b000 } } & { sh_src, sh_src[7] } | { 9{ ir2[5:3] == 3'b001 } } & { sh_src[0], sh_src[0], sh_src[7:1] } | { 9{ ir2[5:3] == 3'b010 } } & { sh_src, cf } | { 9{ ir2[5:3] == 3'b011 } } & { sh_src[0], cf, sh_src[7:1] } | { 9{ ir2[5:3] == 3'b100 } } & { sh_src, 1'b0 } | { 9{ ir2[5:3] == 3'b101 } } & { sh_src[0], sh_src[7], sh_src[7:1] } | { 9{ ir2[5:3] == 3'b110 } } & { sh_src, 1'b1 } | { 9{ ir2[5:3] == 3'b111 } } & { sh_src[0], 1'b0, sh_src[7:1] };
  assign sh_alu_act = ir2[9:6] == 4'b0100;
  assign bit_alu_act = (ir2[9:6] == CB_RES) | (ir2[9:6] == CB_SET);
  wire [7:0] bit_decode;assign bit_decode = { 8{ ir2[5:3] == 3'h0 } } & 8'h01 | { 8{ ir2[5:3] == 3'h1 } } & 8'h02 | { 8{ ir2[5:3] == 3'h2 } } & 8'h04 | { 8{ ir2[5:3] == 3'h3 } } & 8'h08 | { 8{ ir2[5:3] == 3'h4 } } & 8'h10 | { 8{ ir2[5:3] == 3'h5 } } & 8'h20 | { 8{ ir2[5:3] == 3'h6 } } & 8'h40 | { 8{ ir2[5:3] == 3'h7 } } & 8'h80;
  assign bit_alu = { 8{ ir2[9:6] == CB_BIT } } & (sh_src & bit_decode) | { 8{ ir2[9:6] == CB_RES } } & (sh_src & ~bit_decode) | { 8{ ir2[9:6] == CB_SET } } & (sh_src | bit_decode);
  assign decc_alu = cr + 8'hff;
  assign decb_alu = br + ((exec_decb)? 8'hff : 
                    (cr_eq0)? 8'hff : 8'h00);
  wire [3:0] ls_nbl;assign ls_nbl = (!nf & hf)? 4'h6 : 
                  (!nf & (ar[3:0] > 4'h9))? 4'h6 : 
                  (nf & hf)? 4'ha : 4'h0;
  wire [4:0] ms_nbl;assign ms_nbl = (!nf & cf)? 5'h16 : 
                  (!nf & (ar[3:0] > 4'h9))? 5'h16 : 
                  (!nf & (ar[3:0] == 4'h9) & (ar[3:0] > 4'h9))? 5'h16 : 
                  (nf & !cf & hf)? 5'h0f : 
                  (nf & cf & !hf)? 5'h1a : 
                  (nf & cf & hf)? 5'h19 : 5'h00;
  assign { daa_cry, daa_alu } = { ms_nbl[4], { ar + { ms_nbl[3:0], ls_nbl } } };
  assign upd_a_alu8 = (ADDsA_B == ir2) | (SUBsB == ir2) | (ANDsB == ir2) | (ORsB == ir2) | (ADDsA_C == ir2) | (SUBsC == ir2) | (ANDsC == ir2) | (ORsC == ir2) | (ADDsA_D == ir2) | (SUBsD == ir2) | (ANDsD == ir2) | (ORsD == ir2) | (ADDsA_E == ir2) | (SUBsE == ir2) | (ANDsE == ir2) | (ORsE == ir2) | (ADDsA_H == ir2) | (SUBsH == ir2) | (ANDsH == ir2) | (ORsH == ir2) | (ADDsA_L == ir2) | (SUBsL == ir2) | (ANDsL == ir2) | (ORsL == ir2) | (ADDsA_6HL7 == ir2) | (SUBs6HL7 == ir2) | (ANDs6HL7 == ir2) | (ORs6HL7 == ir2) | (ADDsA_A == ir2) | (SUBsA == ir2) | (ANDsA == ir2) | (ORsA == ir2) | (ADCsA_B == ir2) | (SBCsB == ir2) | (XORsB == ir2) | (ADCsA_C == ir2) | (SBCsC == ir2) | (XORsC == ir2) | (INCsA == ir2) | (ADCsA_D == ir2) | (SBCsD == ir2) | (XORsD == ir2) | (DECsA == ir2) | (ADCsA_E == ir2) | (SBCsE == ir2) | (XORsE == ir2) | (ADCsA_H == ir2) | (SBCsH == ir2) | (XORsH == ir2) | (ADCsA_L == ir2) | (SBCsL == ir2) | (XORsL == ir2) | (ADCsA_6HL7 == ir2) | (SBCs6HL7 == ir2) | (XORs6HL7 == ir2) | (ADCsA_A == ir2) | (SBCsA == ir2) | (XORsA == ir2) | (ADDsA_N == ir2) | (ADCsA_N == ir2) | (SUBsN == ir2) | (SBCsA_N == ir2) | (ANDsN == ir2) | (XORsN == ir2) | (ORsN == ir2);
  assign up_a_sh_alu = (RLCA == ir2) | (RRCA == ir2) | (RRA == ir2) | (RLA == ir2);
  assign up_a_src_pqr = (LDsA_B == ir2) | (LDsA_C == ir2) | (LDsA_D == ir2) | (LDsA_E == ir2) | (LDsA_H == ir2) | (LDsA_L == ir2) | (LDsA_6HL7 == ir2) | (LDsA_A == ir2);
  assign up_a_n = (LDsA_N == ir2) | (LDsA_6BC7 == ir2) | (LDsA_6DE7 == ir2) | (LDsA_6NN7 == ir2) | (INsA_6N7 == ir2) | (ED_INsREG_6C7 == { ir2[9:6], ir2[2:0] }) & (ir2[5:3] == REG8_A);
  assign upd_ar = upd_a_alu8 | up_a_sh_alu | up_a_src_pqr | up_a_n | (ir2 == EXsAF_AFp) | (ir2 == EXX) | (ir2 == DAA) | (ir2 == CPL) | (ir2 == POPsAF) | (ir2[2:0] == REG8_A) & bit_alu_act | (ir2[2:0] == REG8_A) & sh_alu_act | (ir2 == ED_RRD) | ({ ir2[9:6], ir2[2:0] } == ED_NEG) | (ir2 == ED_LDsA_I);

  always @(posedge clk) begin
    if(upd_a_alu8 & exec_ir2) ar <= alu8_out; 
    if(up_a_sh_alu & exec_ir2) ar <= sh_alu; 
    if(up_a_src_pqr & exec_ir2) ar <= src_pqr20; 
    if(up_a_n & exec_ir2) ar <= nn[15:8]; 
    if((ir2 == EXsAF_AFp) & exec_ir2) ar <= ap; 
    if((ir2 == EXX) & exec_ir2) ar <= ap; 
    if((ir2 == DAA) & exec_ir2) ar <= daa_alu; 
    if((ir2 == CPL) & exec_ir2) ar <= ~ar; 
    if((ir2 == POPsAF) & exec_ir2) ar <= nn[15:8]; 
    if((ir2[2:0] == REG8_A) & bit_alu_act & exec_ir2) ar <= bit_alu; 
    if((ir2[2:0] == REG8_A) & sh_alu_act & exec_ir2) ar <= sh_alu; 
    if((ir2 == ED_RRD) & exec_ir2) ar[3:0] <= nn[11:8]; 
    if((ir2 == ED_RLD) & exec_ir2) ar[3:0] <= nn[15:12]; 
    if(({ ir2[9:6], ir2[2:0] } == ED_NEG) & exec_ir2) ar <= alu8_out; 
    if((ir2 == ED_LDsA_I) & exec_ir2) ar <= intr; 
  end

  assign upd_b_alu8 = (INCsB == ir2) | (DECsB == ir2);
  assign up_b_src_pqr = (LDsB_B == ir2) | (LDsB_C == ir2) | (LDsB_D == ir2) | (LDsB_E == ir2) | (LDsB_H == ir2) | (LDsB_L == ir2) | (LDsB_6HL7 == ir2) | (LDsB_A == ir2);
  assign up_b_add16 = (INCsBC == ir2) | (DECsBC == ir2);
  assign upd_bc_cpi = ed_blk_cp & exec_ir2;
  assign upd_br = upd_b_alu8 | up_b_src_pqr | up_b_add16 | (LDsBC_NN == ir2) | (POPsBC == ir2) | (EXX == ir2) | (LDsB_N == ir2) | (ir2[2:0] == REG8_B) & bit_alu_act | (ir2[2:0] == REG8_B) & sh_alu_act | (DJNZs$t2 == ir2) | (ED_INsREG_6C7 == { ir2[9:6], ir2[2:0] }) & (ir2[5:3] == REG8_B) | (ED_LDsREG_6NN7 == { ir2[9:6], ir2[3:0] }) & (ir2[5:4] == DBL_REG_BC);

  always @(posedge clk) begin
    if(upd_b_alu8 & exec_ir2) br <= alu8_out; 
    if(up_b_src_pqr & exec_ir2) br <= src_pqr20; 
    if(up_b_add16 & exec_ir2) br <= add16[15:8]; 
    if((LDsBC_NN == ir2) & exec_ir2) br <= nn[15:8]; 
    if((POPsBC == ir2) & exec_ir2) br <= nn[15:8]; 
    if((EXX == ir2) & exec_ir2) br <= bp; 
    if((LDsB_N == ir2) & exec_ir2) br <= nn[15:8]; 
    if((ir2[2:0] == REG8_B) & bit_alu_act & exec_ir2) br <= bit_alu; 
    if((ir2[2:0] == REG8_B) & sh_alu_act & exec_ir2) br <= sh_alu; 
    if((DJNZs$t2 == ir2) & exec_ir2) br <= br + 8'hff; 
    if(exec_decb | exec_decbc | upd_bc_cpi) br <= decb_alu; 
    if((ED_INsREG_6C7 == { ir2[9:6], ir2[2:0] }) & (ir2[5:3] == REG8_B) & exec_ir2) br <= nn[15:8]; 
    if((ED_LDsREG_6NN7 == { ir2[9:6], ir2[3:0] }) & (ir2[5:4] == DBL_REG_BC) & exec_ir2) br <= nn[15:8]; 
  end

  assign up_c_add16 = (INCsBC == ir2) | (DECsBC == ir2);
  assign upd_c_alu8 = (INCsC == ir2) | (DECsC == ir2);
  assign up_c_src_pqr = (LDsC_B == ir2) | (LDsC_C == ir2) | (LDsC_D == ir2) | (LDsC_E == ir2) | (LDsC_H == ir2) | (LDsC_L == ir2) | (LDsC_6HL7 == ir2) | (LDsC_A == ir2);
  assign upd_cr = upd_c_alu8 | up_c_src_pqr | up_c_add16 | (LDsBC_NN == ir2) | (POPsBC == ir2) | (EXX == ir2) | (LDsC_N == ir2) | (ir2[2:0] == REG8_C) & bit_alu_act | (ir2[2:0] == REG8_C) & sh_alu_act | (ED_INsREG_6C7 == { ir2[9:6], ir2[2:0] }) & (ir2[5:3] == REG8_C) | (ED_LDsREG_6NN7 == { ir2[9:6], ir2[3:0] }) & (ir2[5:4] == DBL_REG_BC);

  always @(posedge clk) begin
    if(upd_c_alu8 & exec_ir2) cr <= alu8_out; 
    if(up_c_src_pqr & exec_ir2) cr <= src_pqr20; 
    if(up_c_add16 & exec_ir2) cr <= add16[7:0]; 
    if((LDsBC_NN == ir2) & exec_ir2) cr <= nn[7:0]; 
    if((POPsBC == ir2) & exec_ir2) cr <= nn[7:0]; 
    if((EXX == ir2) & exec_ir2) cr <= cp; 
    if((LDsC_N == ir2) & exec_ir2) cr <= nn[15:8]; 
    if((ir2[2:0] == REG8_C) & bit_alu_act & exec_ir2) cr <= bit_alu; 
    if((ir2[2:0] == REG8_C) & sh_alu_act & exec_ir2) cr <= sh_alu; 
    if(exec_decbc | upd_bc_cpi) cr <= decc_alu; 
    if((ED_INsREG_6C7 == { ir2[9:6], ir2[2:0] }) & (ir2[5:3] == REG8_C) & exec_ir2) cr <= nn[15:8]; 
    if((ED_LDsREG_6NN7 == { ir2[9:6], ir2[3:0] }) & (ir2[5:4] == DBL_REG_BC) & exec_ir2) cr <= nn[7:0]; 
  end

  assign up_d_add16 = (INCsDE == ir2) | (DECsDE == ir2);
  assign upd_d_alu8 = (INCsD == ir2) | (DECsD == ir2);
  assign up_d_src_pqr = (LDsD_B == ir2) | (LDsD_C == ir2) | (LDsD_D == ir2) | (LDsD_E == ir2) | (LDsD_H == ir2) | (LDsD_L == ir2) | (LDsD_6HL7 == ir2) | (LDsD_A == ir2);
  assign upd_dr = upd_d_alu8 | up_d_src_pqr | up_d_add16 | (LDsDE_NN == ir2) | (POPsDE == ir2) | (EXX == ir2) | (EXsDE_HL == ir2) | (LDsD_N == ir2) | (ir2[2:0] == REG8_D) & bit_alu_act | (ir2[2:0] == REG8_D) & sh_alu_act | (ED_INsREG_6C7 == { ir2[9:6], ir2[2:0] }) & (ir2[5:3] == REG8_D) | (ED_LDsREG_6NN7 == { ir2[9:6], ir2[3:0] }) & (ir2[5:4] == DBL_REG_DE);
  wire ed_ld_dereg;assign ed_ld_dereg = (ED_LDsREG_6NN7 == { ir2[9:6], ir2[3:0] }) & (ir2[5:4] == DBL_REG_DE);

  always @(posedge clk) begin
    if(upd_d_alu8 & exec_ir2) dr <= alu8_out; 
    if(up_d_src_pqr & exec_ir2) dr <= src_pqr20; 
    if(up_d_add16 & exec_ir2) dr <= add16[15:8]; 
    if((LDsDE_NN == ir2) & exec_ir2) dr <= nn[15:8]; 
    if((POPsDE == ir2) & exec_ir2) dr <= nn[15:8]; 
    if((EXX == ir2) & exec_ir2) dr <= dp; 
    if((EXsDE_HL == ir2) & exec_ir2) dr <= hr; 
    if((LDsD_N == ir2) & exec_ir2) dr <= nn[15:8]; 
    if((ir2[2:0] == REG8_D) & bit_alu_act & exec_ir2) dr <= bit_alu; 
    if((ir2[2:0] == REG8_D) & sh_alu_act & exec_ir2) dr <= sh_alu; 
    if((ED_INsREG_6C7 == { ir2[9:6], ir2[2:0] }) & (ir2[5:3] == REG8_D) & exec_ir2) dr <= nn[15:8]; 
    if(ed_ld_dereg & exec_ir2) dr <= nn[15:8]; 
    if(blk_mv_upd_de) dr <= adr_alu[15:8]; 
  end

  assign up_e_add16 = (INCsDE == ir2) | (DECsDE == ir2);
  assign upd_e_alu8 = (INCsE == ir2) | (DECsE == ir2);
  assign up_e_src_pqr = (LDsE_B == ir2) | (LDsE_C == ir2) | (LDsE_D == ir2) | (LDsE_E == ir2) | (LDsE_H == ir2) | (LDsE_L == ir2) | (LDsE_6HL7 == ir2) | (LDsE_A == ir2);
  assign upd_er = upd_e_alu8 | up_e_src_pqr | up_e_add16 | (LDsDE_NN == ir2) | (POPsDE == ir2) | (EXX == ir2) | (EXsDE_HL == ir2) | (LDsE_N == ir2) | (ir2[2:0] == REG8_E) & bit_alu_act | (ir2[2:0] == REG8_E) & sh_alu_act | (ED_INsREG_6C7 == { ir2[9:6], ir2[2:0] }) & (ir2[5:3] == REG8_E) | (ED_LDsREG_6NN7 == { ir2[9:6], ir2[3:0] }) & (ir2[5:4] == DBL_REG_DE);

  always @(posedge clk) begin
    if(upd_e_alu8 & exec_ir2) er <= alu8_out; 
    if(up_e_src_pqr & exec_ir2) er <= src_pqr20; 
    if(up_e_add16 & exec_ir2) er <= add16[7:0]; 
    if((LDsDE_NN == ir2) & exec_ir2) er <= nn[7:0]; 
    if((POPsDE == ir2) & exec_ir2) er <= nn[7:0]; 
    if((EXX == ir2) & exec_ir2) er <= ep; 
    if((EXsDE_HL == ir2) & exec_ir2) er <= lr; 
    if((LDsE_N == ir2) & exec_ir2) er <= nn[15:8]; 
    if((ir2[2:0] == REG8_E) & bit_alu_act & exec_ir2) er <= bit_alu; 
    if((ir2[2:0] == REG8_E) & sh_alu_act & exec_ir2) er <= sh_alu; 
    if((ED_INsREG_6C7 == { ir2[9:6], ir2[2:0] }) & (ir2[5:3] == REG8_E) & exec_ir2) er <= nn[15:8]; 
    if(ed_ld_dereg & exec_ir2) er <= nn[7:0]; 
    if(blk_mv_upd_de) er <= adr_alu[7:0]; 
  end

  assign up_h_add16 = (ADDsHL_BC == ir2) | (ADDsHL_DE == ir2) | (ADDsHL_HL == ir2) | (ADDsHL_SP == ir2) | (ED_SBCsHL_REG == { ir2[9:6], ir2[3:0] }) | (ED_ADCsHL_REG == { ir2[9:6], ir2[3:0] }) | (INCsHL == ir2) | (DECsHL == ir2);
  assign upd_h_alu8 = (INCsH == ir2) | (DECsH == ir2);
  assign upd_h_src_pqr = (LDsH_B == ir2) | (LDsH_C == ir2) | (LDsH_D == ir2) | (LDsH_E == ir2) | (LDsH_H == ir2) | (LDsH_L == ir2) | (LDsH_6HL7 == ir2) | (LDsH_A == ir2);
  assign upd_hr = upd_h_alu8 | upd_h_src_pqr | up_h_add16 | (LDsHL_NN == ir2) | (LDsHL_6NN7 == ir2) | (POPsHL == ir2) | (EXX == ir2) | (EXsDE_HL == ir2) | (LDsH_N == ir2) | (ir2[2:0] == REG8_H) & bit_alu_act | (ir2[2:0] == REG8_H) & sh_alu_act | (ED_INsREG_6C7 == { ir2[9:6], ir2[2:0] }) & (ir2[5:3] == REG8_H) | (ED_LDsREG_6NN7 == { ir2[9:6], ir2[3:0] }) & (ir2[5:4] == DBL_REG_HL);
  wire exec_hlir2;assign exec_hlir2 = exec_ir2 & !(ir2dd | ir2fd);

  always @(posedge clk) begin
    if(upd_h_alu8 & exec_hlir2) hr <= alu8_out; 
    if(upd_h_src_pqr & exec_hlir2) hr <= src_pqr20; 
    if(up_h_add16 & exec_hlir2) hr <= add16[15:8]; 
    if((LDsHL_NN == ir2) & exec_hlir2) hr <= nn[15:8]; 
    if((LDsHL_6NN7 == ir2) & exec_hlir2) hr <= nn[15:8]; 
    if((POPsHL == ir2) & exec_hlir2) hr <= nn[15:8]; 
    if((EXs6SP7_HL == ir2) & exec_hlir2) hr <= nn[15:8]; 
    if((EXX == ir2) & exec_ir2) hr <= hp; 
    if((EXsDE_HL == ir2) & exec_ir2) hr <= dr; 
    if((LDsH_N == ir2) & exec_hlir2) hr <= nn[15:8]; 
    if((ir2[2:0] == REG8_H) & bit_alu_act & exec_hlir2) hr <= bit_alu; 
    if((ir2[2:0] == REG8_H) & sh_alu_act & exec_hlir2) hr <= sh_alu; 
    if((ED_INsREG_6C7 == { ir2[9:6], ir2[2:0] }) & (ir2[5:3] == REG8_H) & exec_ir2) hr <= nn[15:8]; 
    if((ED_LDsREG_6NN7 == { ir2[9:6], ir2[3:0] }) & (ir2[5:4] == DBL_REG_HL) & exec_ir2) hr <= nn[15:8]; 
    if(blk_mv_upd_hl) hr <= adr_alu[14:7]; 
  end

  assign up_l_add16 = (ADDsHL_BC == ir2) | (ADDsHL_DE == ir2) | (ADDsHL_HL == ir2) | (ADDsHL_SP == ir2) | (ED_SBCsHL_REG == { ir2[9:6], ir2[3:0] }) | (ED_ADCsHL_REG == { ir2[9:6], ir2[3:0] }) | (INCsHL == ir2) | (DECsHL == ir2);
  assign upd_l_alu8 = (INCsL == ir2) | (DECsL == ir2);
  assign upd_l_src_pqr = (LDsL_B == ir2) | (LDsL_C == ir2) | (LDsL_D == ir2) | (LDsL_E == ir2) | (LDsL_H == ir2) | (LDsL_L == ir2) | (LDsL_6HL7 == ir2) | (LDsL_A == ir2);
  assign upd_lr = upd_l_alu8 | upd_l_src_pqr | up_l_add16 | (LDsHL_NN == ir2) | (LDsHL_6NN7 == ir2) | (POPsHL == ir2) | (EXX == ir2) | (EXsDE_HL == ir2) | (LDsL_N == ir2) | (ir2[2:0] == REG8_L) & bit_alu_act | (ir2[2:0] == REG8_L) & sh_alu_act | (ED_INsREG_6C7 == { ir2[9:6], ir2[2:0] }) & (ir2[5:3] == REG8_L) | (ED_LDsREG_6NN7 == { ir2[9:6], ir2[3:0] }) & (ir2[5:4] == DBL_REG_HL);

  always @(posedge clk) begin
    if(upd_l_alu8 & exec_hlir2) lr <= alu8_out; 
    if(upd_l_src_pqr & exec_hlir2) lr <= src_pqr20; 
    if(up_l_add16 & exec_hlir2) lr <= add16[7:0]; 
    if((LDsHL_NN == ir2) & exec_hlir2) lr <= nn[7:0]; 
    if((LDsHL_6NN7 == ir2) & exec_hlir2) lr <= nn[7:0]; 
    if((POPsHL == ir2) & exec_hlir2) lr <= nn[7:0]; 
    if((EXs6SP7_HL == ir2) & exec_hlir2) lr <= nn[7:0]; 
    if((EXX == ir2) & exec_ir2) lr <= lp; 
    if((EXsDE_HL == ir2) & exec_ir2) lr <= er; 
    if((LDsL_N == ir2) & exec_hlir2) lr <= nn[15:8]; 
    if((ir2[2:0] == REG8_L) & bit_alu_act & exec_hlir2) lr <= bit_alu; 
    if((ir2[2:0] == REG8_L) & sh_alu_act & exec_hlir2) lr <= sh_alu; 
    if((ED_INsREG_6C7 == { ir2[9:6], ir2[2:0] }) & (ir2[5:3] == REG8_L) & exec_ir2) lr <= nn[15:8]; 
    if((ED_LDsREG_6NN7 == { ir2[9:6], ir2[3:0] }) & (ir2[5:4] == DBL_REG_HL) & exec_ir2) lr <= nn[7:0]; 
    if(blk_mv_upd_hl) lr <= adr_alu[7:0]; 
  end

  wire exec_ixir2;assign exec_ixir2 = exec_ir2 & ir2dd;

  always @(posedge clk) begin
    if(upd_l_alu8 & exec_ixir2) ixr[7:0] <= alu8_out; 
    if(upd_l_src_pqr & exec_ixir2) ixr[7:0] <= src_pqr20; 
    if(up_l_add16 & exec_ixir2) ixr[7:0] <= add16[7:0]; 
    if((LDsHL_NN == ir2) & exec_ixir2) ixr[7:0] <= nn[7:0]; 
    if((LDsHL_6NN7 == ir2) & exec_ixir2) ixr[7:0] <= nn[7:0]; 
    if((POPsHL == ir2) & exec_ixir2) ixr[7:0] <= nn[7:0]; 
    if((EXs6SP7_HL == ir2) & exec_ixir2) ixr[7:0] <= nn[7:0]; 
    if((LDsL_N == ir2) & exec_ixir2) ixr[7:0] <= nn[15:8]; 
    if((ir2[2:0] == REG8_L) & bit_alu_act & exec_ixir2) ixr[7:0] <= bit_alu; 
    if((ir2[2:0] == REG8_L) & sh_alu_act & exec_ixir2) ixr[7:0] <= sh_alu; 
  end


  always @(posedge clk) begin
    if(upd_h_alu8 & exec_ixir2) ixr[15:8] <= alu8_out; 
    if(upd_h_src_pqr & exec_ixir2) ixr[15:8] <= src_pqr20; 
    if(up_h_add16 & exec_ixir2) ixr[15:8] <= add16[15:8]; 
    if((LDsHL_NN == ir2) & exec_ixir2) ixr[15:8] <= nn[15:8]; 
    if((LDsHL_6NN7 == ir2) & exec_ixir2) ixr[15:8] <= nn[15:8]; 
    if((POPsHL == ir2) & exec_ixir2) ixr[15:8] <= nn[15:8]; 
    if((EXs6SP7_HL == ir2) & exec_ixir2) ixr[15:8] <= nn[15:8]; 
    if((LDsH_N == ir2) & exec_ixir2) ixr[15:8] <= nn[15:8]; 
    if((ir2[2:0] == REG8_H) & bit_alu_act & exec_ixir2) ixr[15:8] <= bit_alu; 
    if((ir2[2:0] == REG8_H) & sh_alu_act & exec_ixir2) ixr[15:8] <= sh_alu; 
  end

  wire exec_iyir2;assign exec_iyir2 = exec_ir2 & ir2fd;

  always @(posedge clk) begin
    if(upd_l_alu8 & exec_iyir2) iyr[7:0] <= alu8_out; 
    if(upd_l_src_pqr & exec_iyir2) iyr[7:0] <= src_pqr20; 
    if(up_l_add16 & exec_iyir2) iyr[7:0] <= add16[7:0]; 
    if((LDsHL_NN == ir2) & exec_iyir2) iyr[7:0] <= nn[7:0]; 
    if((LDsHL_6NN7 == ir2) & exec_iyir2) iyr[7:0] <= nn[7:0]; 
    if((POPsHL == ir2) & exec_iyir2) iyr[7:0] <= nn[7:0]; 
    if((EXs6SP7_HL == ir2) & exec_iyir2) iyr[7:0] <= nn[7:0]; 
    if((LDsL_N == ir2) & exec_iyir2) iyr[7:0] <= nn[15:8]; 
    if((ir2[2:0] == REG8_L) & bit_alu_act & exec_iyir2) iyr[7:0] <= bit_alu; 
    if((ir2[2:0] == REG8_L) & sh_alu_act & exec_iyir2) iyr[7:0] <= sh_alu; 
  end


  always @(posedge clk) begin
    if(upd_h_alu8 & exec_iyir2) iyr[15:8] <= alu8_out; 
    if(upd_h_src_pqr & exec_iyir2) iyr[15:8] <= src_pqr20; 
    if(up_h_add16 & exec_iyir2) iyr[15:8] <= add16[15:8]; 
    if((LDsHL_NN == ir2) & exec_iyir2) iyr[15:8] <= nn[15:8]; 
    if((LDsHL_6NN7 == ir2) & exec_iyir2) iyr[15:8] <= nn[15:8]; 
    if((POPsHL == ir2) & exec_iyir2) iyr[15:8] <= nn[15:8]; 
    if((EXs6SP7_HL == ir2) & exec_iyir2) iyr[15:8] <= nn[15:8]; 
    if((LDsH_N == ir2) & exec_iyir2) iyr[15:8] <= nn[15:8]; 
    if((ir2[2:0] == REG8_H) & bit_alu_act & exec_iyir2) iyr[15:8] <= bit_alu; 
    if((ir2[2:0] == REG8_H) & sh_alu_act & exec_iyir2) iyr[15:8] <= sh_alu; 
  end


  always @(posedge clk) begin
    if((ir2 == EXsAF_AFp) & exec_ir2) begin
      ap <= ar;
      fp <= fr;
    end 
    if((ir2 == EXX) & exec_ir2) begin
      ap <= ar;
      fp <= fr;
      bp <= br;
      cp <= cr;
      dp <= dr;
      ep <= er;
      hp <= hr;
      lp <= lr;
    end 
  end

  assign upd_fr_alu8 = (ADCsA_A == ir2) | (ANDsA == ir2) | (ORsA == ir2) | (SUBsA == ir2) | (DECsA == ir2) | (ADCsA_B == ir2) | (ANDsB == ir2) | (ORsB == ir2) | (SUBsB == ir2) | (DECsB == ir2) | (ADCsA_C == ir2) | (ANDsC == ir2) | (ORsC == ir2) | (SUBsC == ir2) | (DECsC == ir2) | (ADCsA_D == ir2) | (ANDsD == ir2) | (ORsD == ir2) | (SUBsD == ir2) | (DECsD == ir2) | (ADCsA_E == ir2) | (ANDsE == ir2) | (ORsE == ir2) | (SUBsE == ir2) | (DECsE == ir2) | (ADCsA_H == ir2) | (ANDsH == ir2) | (ORsH == ir2) | (SUBsH == ir2) | (DECsH == ir2) | (ADCsA_L == ir2) | (ANDsL == ir2) | (ORsL == ir2) | (SUBsL == ir2) | (DECsL == ir2) | (ADCsA_6HL7 == ir2) | (ANDs6HL7 == ir2) | (ORs6HL7 == ir2) | (SUBs6HL7 == ir2) | (INCsA == ir2) | (ADDsA_A == ir2) | (CPsA == ir2) | (SBCsA == ir2) | (XORsA == ir2) | (INCsB == ir2) | (ADDsA_B == ir2) | (CPsB == ir2) | (SBCs6HL7 == ir2) | (XORsB == ir2) | (INCsC == ir2) | (ADDsA_C == ir2) | (CPsC == ir2) | (SBCsB == ir2) | (XORsC == ir2) | (INCsD == ir2) | (ADDsA_D == ir2) | (CPsD == ir2) | (SBCsC == ir2) | (XORsD == ir2) | (INCsE == ir2) | (ADDsA_E == ir2) | (CPsE == ir2) | (SBCsD == ir2) | (XORsE == ir2) | (INCsH == ir2) | (ADDsA_H == ir2) | (CPsH == ir2) | (SBCsE == ir2) | (XORsH == ir2) | (INCsL == ir2) | (ADDsA_L == ir2) | (CPsL == ir2) | (SBCsH == ir2) | (XORsL == ir2) | (INCs6HL7 == ir2) | (ADDsA_6HL7 == ir2) | (CPs6HL7 == ir2) | (SBCsL == ir2) | (XORs6HL7 == ir2) | (DECs6HL7 == ir2) | (ADDsA_N == ir2) | (SUBsN == ir2) | (ANDsN == ir2) | (ORsN == ir2) | (ADCsA_N == ir2) | (SBCsA_N == ir2) | (XORsN == ir2) | (CPsN == ir2) | (ED_NEG == { ir2[9:6], ir2[2:0] });
  assign upd_fr_add16 = (ADDsHL_BC == ir2) | (ADDsHL_DE == ir2) | (ADDsHL_HL == ir2) | (ADDsHL_SP == ir2);
  assign upd_fr_edadd16 = (ED_SBCsHL_REG == { ir2[9:6], ir2[3:0] }) | (ED_ADCsHL_REG == { ir2[9:6], ir2[3:0] });
  wire borrow;assign borrow = ED_SBCsHL_REG == { ir2[9:6], ir2[3:0] };
  assign upd_fr_sh = (RLA == ir2) | (RLCA == ir2) | (RRA == ir2) | (RRCA == ir2);
  assign upd_fr_cbsh = (CB_RLC == ir2[9:3]) | (CB_RRC == ir2[9:3]) | (CB_RL == ir2[9:3]) | (CB_RR == ir2[9:3]) | (CB_SLA == ir2[9:3]) | (CB_SRA == ir2[9:3]) | (CB_SLL == ir2[9:3]) | (CB_SRL == ir2[9:3]);
  assign ed_blk_cp = (ED_CPI == ir2) | (ED_CPD == ir2) | (ED_CPIR == ir2) | (ED_CPDR == ir2);
  assign { sf, zf, f5f, hf, f3f, pvf, nf, cf } = fr;
  assign upd_fr = exec_ir2 & (upd_fr_alu8 | upd_fr_add16 | upd_fr_edadd16 | upd_fr_sh | upd_fr_cbsh | (CB_BIT == ir2[9:6]) | ed_blk_cp | (ED_INsREG_6C7 == { ir2[9:6], ir2[2:0] }) | (CCF == ir2) | (CPL == ir2) | (DAA == ir2) | (SCF == ir2) | (ED_RRD == ir2) | (ED_RLD == ir2) | (ED_LDsA_I == ir2) | (ir2 == EXsAF_AFp) | (ir2 == EXX));
  wire iff2;assign iff2 = 1'b0;
  wire upd_fr_ed_in;assign upd_fr_ed_in = ED_INsREG_6C7 == { ir2[9:6], ir2[2:0] };
  wire bc_eq1;assign bc_eq1 = { br, cr } == 16'h1;

  always @(posedge clk) begin
    if(exec_ir2) begin
      if(upd_fr_alu8) fr <= alu8_fr; 
      if(upd_fr_add16) fr <= { sf, zf, add16[13], c_16out11, add16[11], pvf, 1'b0, c_16out15 }; 
      if(upd_fr_edadd16) fr <= { add16[15], ~|add16, add16[13], c_16out11, add16[11], add16_ofl, ~ir2[3], borrow ^ c_16out15 }; 
      if(upd_fr_sh) fr <= { sf, zf, sh_alu[5], 1'b0, sh_alu[3], pvf, 1'b0, sh_cry }; 
      if(upd_fr_cbsh) fr <= { sh_alu[7], ~|sh_alu, sh_alu[5], 1'b0, sh_alu[3], ~^sh_alu, 1'b0, sh_cry }; 
      if(CB_BIT == ir2[9:6]) fr <= { bit_alu[7], ~|bit_alu, bit_alu[5], 1'b1, bit_alu[3], ~|bit_alu, 1'b0, cf }; 
      if(ed_blk_cp) fr <= { alu8_out[7], ~|alu8_out, alu8_out[5], alu8_hcry, alu8_out[3], ~bc_eq1, 1'b1, cf }; 
      if(upd_fr_ed_in) fr <= { nn[15], ~|nn[15:8], nn[13], 1'b0, nn[11], ~^nn[15:8], 1'b0, cf }; 
      if(CCF == ir2) fr <= { sf, zf, f5f, cf, f3f, pvf, nf, ~cf }; 
      if(CPL == ir2) fr <= { sf, zf, ar[5], 1'b1, ar[3], pvf, 1'b1, cf }; 
      if(DAA == ir2) fr <= { daa_alu[7], ~|daa_alu, daa_alu[5], 1'b0, daa_alu[3], ~^daa_alu, nf, daa_cry }; 
      if(SCF == ir2) fr <= { sf, zf, ar[5], 1'b0, ar[3], pvf, 1'b0, 1'b1 }; 
      if(ED_RRD == ir2) fr <= { ar[7], ~|{ ar[7:4], nn[11:8] }, ar[5], 1'b0, ar[3], ~^{ ar[7:4], nn[11:8] }, 1'b0, cf }; 
      if(ED_RLD == ir2) fr <= { ar[7], ~|{ ar[7:4], nn[15:12] }, ar[5], 1'b0, ar[3], ~^{ ar[7:4], nn[15:12] }, 1'b0, cf }; 
      if(ED_LDsA_I == ir2) fr <= { intr[7], ~|intr, intr[5], 1'b0, intr[3], iff2, 1'b0, cf }; 
      if(ir2 == EXsAF_AFp) fr <= fp; 
      if(ir2 == EXX) fr <= fp; 
      if(ir2 == POPsAF) fr <= nn[7:0]; 
    end 
    if(exec_decb) fr <= { decb_alu[7], ~|decb_alu, decb_alu[5], hf, decb_alu[3], pvf, 1'b0, cf }; 
    if(exec_decbc) fr[5:1] <= { decb_alu[5], 1'b0, decb_alu[3], |decb_alu | |decc_alu, 1'b0 }; 
  end


  always @(posedge clk or posedge rst) if(rst) intr <= 8'h0; 
  else if((ED_LDsI_A == ir2) & exec_ir2) intr <= ar; 


endmodule

