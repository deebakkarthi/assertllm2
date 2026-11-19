

module omsp_sfr
(
  cpu_id,
  nmi_pnd,
  nmi_wkup,
  per_dout,
  wdtie,
  wdtifg_sw_clr,
  wdtifg_sw_set,
  cpu_nr_inst,
  cpu_nr_total,
  mclk,
  nmi,
  nmi_acc,
  per_addr,
  per_din,
  per_en,
  per_we,
  puc_rst,
  scan_mode,
  wdtifg,
  wdtnmies
);

  output [31:0] cpu_id;
  output nmi_pnd;
  output nmi_wkup;
  output [15:0] per_dout;
  output wdtie;
  output wdtifg_sw_clr;
  output wdtifg_sw_set;
  input [7:0] cpu_nr_inst;
  input [7:0] cpu_nr_total;
  input mclk;
  input nmi;
  input nmi_acc;
  input [13:0] per_addr;
  input [15:0] per_din;
  input per_en;
  input [1:0] per_we;
  input puc_rst;
  input scan_mode;
  input wdtifg;
  input wdtnmies;
  parameter [14:0] BASE_ADDR = 15'h0000;
  parameter DEC_WD = 4;
  parameter [DEC_WD-1:0] IE1 = 'h0;parameter [DEC_WD-1:0] IFG1 = 'h2;parameter [DEC_WD-1:0] CPU_ID_LO = 'h4;parameter [DEC_WD-1:0] CPU_ID_HI = 'h6;parameter [DEC_WD-1:0] CPU_NR = 'h8;
  parameter DEC_SZ = 1 << DEC_WD;
  parameter [DEC_SZ-1:0] BASE_REG = { { DEC_SZ - 1{ 1'b0 } }, 1'b1 };
  parameter [DEC_SZ-1:0] IE1_D = BASE_REG << IE1;parameter [DEC_SZ-1:0] IFG1_D = BASE_REG << IFG1;parameter [DEC_SZ-1:0] CPU_ID_LO_D = BASE_REG << CPU_ID_LO;parameter [DEC_SZ-1:0] CPU_ID_HI_D = BASE_REG << CPU_ID_HI;parameter [DEC_SZ-1:0] CPU_NR_D = BASE_REG << CPU_NR;
  wire reg_sel;assign reg_sel = per_en & (per_addr[13:DEC_WD-1] == BASE_ADDR[14:DEC_WD]);
  wire [DEC_WD-1:0] reg_addr;assign reg_addr = { 1'b0, per_addr[DEC_WD-2:0] };
  wire [DEC_SZ-1:0] reg_dec;assign reg_dec = IE1_D & { DEC_SZ{ reg_addr == (IE1 >> 1) } } | IFG1_D & { DEC_SZ{ reg_addr == (IFG1 >> 1) } } | CPU_ID_LO_D & { DEC_SZ{ reg_addr == (CPU_ID_LO >> 1) } } | CPU_ID_HI_D & { DEC_SZ{ reg_addr == (CPU_ID_HI >> 1) } } | CPU_NR_D & { DEC_SZ{ reg_addr == (CPU_NR >> 1) } };
  wire reg_lo_write;assign reg_lo_write = per_we[0] & reg_sel;
  wire reg_hi_write;assign reg_hi_write = per_we[1] & reg_sel;
  wire reg_read;assign reg_read = ~|per_we & reg_sel;
  wire [DEC_SZ-1:0] reg_hi_wr;assign reg_hi_wr = reg_dec & { DEC_SZ{ reg_hi_write } };
  wire [DEC_SZ-1:0] reg_lo_wr;assign reg_lo_wr = reg_dec & { DEC_SZ{ reg_lo_write } };
  wire [DEC_SZ-1:0] reg_rd;assign reg_rd = reg_dec & { DEC_SZ{ reg_read } };
  wire [7:0] ie1;
  wire ie1_wr;assign ie1_wr = (IE1[0])? reg_hi_wr[IE1] : reg_lo_wr[IE1];
  wire [7:0] ie1_nxt;assign ie1_nxt = (IE1[0])? per_din[15:8] : per_din[7:0];
  reg nmie;

  always @(posedge mclk or posedge puc_rst) if(puc_rst) nmie <= 1'b0; 
  else if(nmi_acc) nmie <= 1'b0; 
  else if(ie1_wr) nmie <= ie1_nxt[4]; 

  reg wdtie;

  always @(posedge mclk or posedge puc_rst) if(puc_rst) wdtie <= 1'b0; 
  else if(ie1_wr) wdtie <= ie1_nxt[0]; 

  assign ie1 = { 3'b000, nmie, 3'b000, wdtie };
  wire [7:0] ifg1;
  wire ifg1_wr;assign ifg1_wr = (IFG1[0])? reg_hi_wr[IFG1] : reg_lo_wr[IFG1];
  wire [7:0] ifg1_nxt;assign ifg1_nxt = (IFG1[0])? per_din[15:8] : per_din[7:0];
  reg nmiifg;
  wire nmi_edge;

  always @(posedge mclk or posedge puc_rst) if(puc_rst) nmiifg <= 1'b0; 
  else if(nmi_edge) nmiifg <= 1'b1; 
  else if(ifg1_wr) nmiifg <= ifg1_nxt[4]; 

  assign wdtifg_sw_clr = ifg1_wr & ~ifg1_nxt[0];
  assign wdtifg_sw_set = ifg1_wr & ifg1_nxt[0];
  assign ifg1 = { 3'b000, nmiifg, 3'b000, wdtifg };
  wire [2:0] cpu_version;assign cpu_version = 3'h3;
  wire cpu_asic;assign cpu_asic = 1'b1;
  wire [4:0] user_version;assign user_version = 5'b00000;
  wire [6:0] per_space;assign per_space = 512 >> 9;
  wire mpy_info;assign mpy_info = 1'b1;
  wire [8:0] dmem_size;assign dmem_size = 1024 >> 7;
  wire [5:0] pmem_size;assign pmem_size = 4096 >> 10;
  assign cpu_id = { pmem_size, dmem_size, mpy_info, per_space, user_version, cpu_asic, cpu_version };
  wire [15:0] cpu_nr;assign cpu_nr = { cpu_nr_inst, cpu_nr_total };
  wire [15:0] ie1_rd;assign ie1_rd = { 8'h00, ie1 & { 8{ reg_rd[IE1] } } } << (8 & { 4{ IE1[0] } });
  wire [15:0] ifg1_rd;assign ifg1_rd = { 8'h00, ifg1 & { 8{ reg_rd[IFG1] } } } << (8 & { 4{ IFG1[0] } });
  wire [15:0] cpu_id_lo_rd;assign cpu_id_lo_rd = cpu_id[15:0] & { 16{ reg_rd[CPU_ID_LO] } };
  wire [15:0] cpu_id_hi_rd;assign cpu_id_hi_rd = cpu_id[31:16] & { 16{ reg_rd[CPU_ID_HI] } };
  wire [15:0] cpu_nr_rd;assign cpu_nr_rd = cpu_nr & { 16{ reg_rd[CPU_NR] } };
  wire [15:0] per_dout;assign per_dout = ie1_rd | ifg1_rd | cpu_id_lo_rd | cpu_id_hi_rd | cpu_nr_rd;
  wire nmi_pol;assign nmi_pol = nmi ^ wdtnmies;
  reg nmi_capture_rst;

  always @(posedge mclk or posedge puc_rst) if(puc_rst) nmi_capture_rst <= 1'b1; 
  else nmi_capture_rst <= ifg1_wr & ~ifg1_nxt[4];

  wire nmi_capture;

  omsp_wakeup_cell
  wakeup_cell_nmi
  (
    .wkup_out(nmi_capture),
    .scan_clk(mclk),
    .scan_mode(scan_mode),
    .scan_rst(puc_rst),
    .wkup_clear(nmi_capture_rst),
    .wkup_event(nmi_pol)
  );

  wire nmi_s;

  omsp_sync_cell
  sync_cell_nmi
  (
    .data_out(nmi_s),
    .data_in(nmi_capture),
    .clk(mclk),
    .rst(puc_rst)
  );

  reg nmi_dly;

  always @(posedge mclk or posedge puc_rst) if(puc_rst) nmi_dly <= 1'b0; 
  else nmi_dly <= nmi_s;

  assign nmi_edge = ~nmi_dly & nmi_s;
  wire nmi_pnd;assign nmi_pnd = nmiifg & nmie;
  wire nmi_wkup;

  omsp_and_gate
  and_nmi_wkup
  (
    .y(nmi_wkup),
    .a(nmi_capture ^ nmi_dly),
    .b(nmie)
  );

  wire [7:0] UNUSED_per_din_15_8;assign UNUSED_per_din_15_8 = per_din[15:8];

endmodule

