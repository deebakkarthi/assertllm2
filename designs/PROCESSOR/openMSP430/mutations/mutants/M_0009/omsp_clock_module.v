

module omsp_clock_module
(
  aclk,
  aclk_en,
  cpu_en_s,
  cpu_mclk,
  dma_mclk,
  dbg_clk,
  dbg_en_s,
  dbg_rst,
  dco_enable,
  dco_wkup,
  lfxt_enable,
  lfxt_wkup,
  per_dout,
  por,
  puc_pnd_set,
  puc_rst,
  smclk,
  smclk_en,
  cpu_en,
  cpuoff,
  dbg_cpu_reset,
  dbg_en,
  dco_clk,
  lfxt_clk,
  mclk_dma_enable,
  mclk_dma_wkup,
  mclk_enable,
  mclk_wkup,
  oscoff,
  per_addr,
  per_din,
  per_en,
  per_we,
  reset_n,
  scan_enable,
  scan_mode,
  scg0,
  scg1,
  wdt_reset
);

  output aclk;
  output aclk_en;
  output cpu_en_s;
  output cpu_mclk;
  output dma_mclk;
  output dbg_clk;
  output dbg_en_s;
  output dbg_rst;
  output dco_enable;
  output dco_wkup;
  output lfxt_enable;
  output lfxt_wkup;
  output [15:0] per_dout;
  output por;
  output puc_pnd_set;
  output puc_rst;
  output smclk;
  output smclk_en;
  input cpu_en;
  input cpuoff;
  input dbg_cpu_reset;
  input dbg_en;
  input dco_clk;
  input lfxt_clk;
  input mclk_dma_enable;
  input mclk_dma_wkup;
  input mclk_enable;
  input mclk_wkup;
  input oscoff;
  input [13:0] per_addr;
  input [15:0] per_din;
  input per_en;
  input [1:0] per_we;
  input reset_n;
  input scan_enable;
  input scan_mode;
  input scg0;
  input scg1;
  input wdt_reset;
  parameter [14:0] BASE_ADDR = 15'h0050;
  parameter DEC_WD = 4;
  parameter [DEC_WD-1:0] BCSCTL1 = 'h7;parameter [DEC_WD-1:0] BCSCTL2 = 'h8;
  parameter DEC_SZ = 1 << DEC_WD;
  parameter [DEC_SZ-1:0] BASE_REG = { { DEC_SZ - 1{ 1'b0 } }, 1'b1 };
  parameter [DEC_SZ-1:0] BCSCTL1_D = BASE_REG << BCSCTL1;parameter [DEC_SZ-1:0] BCSCTL2_D = BASE_REG << BCSCTL2;
  wire nodiv_mclk;
  wire nodiv_smclk;
  wire reg_sel;assign reg_sel = per_en & (per_addr[13:DEC_WD-1] == BASE_ADDR[14:DEC_WD]);
  wire [DEC_WD-1:0] reg_addr;assign reg_addr = { 1'b0, per_addr[DEC_WD-2:0] };
  wire [DEC_SZ-1:0] reg_dec;assign reg_dec = BCSCTL1_D & { DEC_SZ{ reg_addr == (BCSCTL1 >> 1) } } | BCSCTL2_D & { DEC_SZ{ reg_addr == (BCSCTL2 >> 1) } };
  wire reg_lo_write;assign reg_lo_write = per_we[0] & reg_sel;
  wire reg_hi_write;assign reg_hi_write = per_we[1] & reg_sel;
  wire reg_read;assign reg_read = ~|per_we & reg_sel;
  wire [DEC_SZ-1:0] reg_hi_wr;assign reg_hi_wr = reg_dec & { DEC_SZ{ reg_hi_write } };
  wire [DEC_SZ-1:0] reg_lo_wr;assign reg_lo_wr = reg_dec & { DEC_SZ{ reg_lo_write } };
  wire [DEC_SZ-1:0] reg_rd;assign reg_rd = reg_dec & { DEC_SZ{ reg_read } };
  reg [7:0] bcsctl1;
  wire bcsctl1_wr;assign bcsctl1_wr = (BCSCTL1[0])? reg_hi_wr[BCSCTL1] : reg_lo_wr[BCSCTL1];
  wire [7:0] bcsctl1_nxt;assign bcsctl1_nxt = (BCSCTL1[0])? per_din[15:8] : per_din[7:0];
  wire [7:0] divax_mask;assign divax_mask = 8'h30;
  wire [7:0] dma_cpuoff_mask;assign dma_cpuoff_mask = 8'h01;
  wire [7:0] dma_oscoff_mask;assign dma_oscoff_mask = 8'h02;
  wire [7:0] dma_scg0_mask;assign dma_scg0_mask = 8'h04;
  wire [7:0] dma_scg1_mask;assign dma_scg1_mask = 8'h08;

  always @(posedge dma_mclk or posedge puc_rst) if(puc_rst) bcsctl1 <= 8'h00; 
  else if(bcsctl1_wr) bcsctl1 <= bcsctl1_nxt & (divax_mask | dma_cpuoff_mask | dma_oscoff_mask | dma_scg0_mask | dma_scg1_mask); 

  reg [7:0] bcsctl2;
  wire bcsctl2_wr;assign bcsctl2_wr = (BCSCTL2[0])? reg_hi_wr[BCSCTL2] : reg_lo_wr[BCSCTL2];
  wire [7:0] bcsctl2_nxt;assign bcsctl2_nxt = (BCSCTL2[0])? per_din[15:8] : per_din[7:0];
  wire [7:0] selmx_mask;assign selmx_mask = 8'h00;
  wire [7:0] divmx_mask;assign divmx_mask = 8'h30;
  wire [7:0] sels_mask;assign sels_mask = 8'h00;
  wire [7:0] divsx_mask;assign divsx_mask = 8'h06;

  always @(posedge dma_mclk or posedge puc_rst) if(puc_rst) bcsctl2 <= 8'h00; 
  else if(bcsctl2_wr) bcsctl2 <= bcsctl2_nxt & (sels_mask | divsx_mask | selmx_mask | divmx_mask); 

  wire [15:0] bcsctl1_rd;assign bcsctl1_rd = { 8'h00, bcsctl1 & { 8{ reg_rd[BCSCTL1] } } } << (8 & { 4{ BCSCTL1[0] } });
  wire [15:0] bcsctl2_rd;assign bcsctl2_rd = { 8'h00, bcsctl2 & { 8{ reg_rd[BCSCTL2] } } } << (8 & { 4{ BCSCTL2[0] } });
  wire [15:0] per_dout;assign per_dout = bcsctl1_rd | bcsctl2_rd;
  wire cpuoff_and_mclk_enable;
  wire cpuoff_and_mclk_dma_enable;
  wire cpuoff_and_mclk_dma_wkup;

  omsp_and_gate
  and_cpuoff_mclk_en
  (
    .y(cpuoff_and_mclk_enable),
    .a(cpuoff),
    .b(mclk_enable)
  );


  omsp_and_gate
  and_cpuoff_mclk_dma_en
  (
    .y(bcsctl1[0]),
    .a(cpuoff_and_mclk_dma_enable),
    .b(mclk_dma_enable)
  );


  omsp_and_gate
  and_cpuoff_mclk_dma_wkup
  (
    .y(cpuoff_and_mclk_dma_wkup),
    .a(bcsctl1[0]),
    .b(mclk_dma_wkup)
  );

  wire scg0_and_mclk_dma_enable;
  wire scg0_and_mclk_dma_wkup;

  omsp_and_gate
  and_scg0_mclk_dma_en
  (
    .y(scg0_and_mclk_dma_enable),
    .a(bcsctl1[2]),
    .b(mclk_dma_enable)
  );


  omsp_and_gate
  and_scg0_mclk_dma_wkup
  (
    .y(scg0_and_mclk_dma_wkup),
    .a(bcsctl1[2]),
    .b(mclk_dma_wkup)
  );

  wire scg1_and_mclk_dma_enable;
  wire scg1_and_mclk_dma_wkup;

  omsp_and_gate
  and_scg1_mclk_dma_en
  (
    .y(scg1_and_mclk_dma_enable),
    .a(bcsctl1[3]),
    .b(mclk_dma_enable)
  );


  omsp_and_gate
  and_scg1_mclk_dma_wkup
  (
    .y(scg1_and_mclk_dma_wkup),
    .a(bcsctl1[3]),
    .b(mclk_dma_wkup)
  );

  wire oscoff_and_mclk_dma_enable;
  wire oscoff_and_mclk_dma_wkup;

  omsp_and_gate
  and_oscoff_mclk_dma_en
  (
    .y(oscoff_and_mclk_dma_enable),
    .a(bcsctl1[1]),
    .b(mclk_dma_enable)
  );


  omsp_and_gate
  and_oscoff_mclk_dma_wkup
  (
    .y(oscoff_and_mclk_dma_wkup),
    .a(bcsctl1[1]),
    .b(mclk_dma_wkup)
  );

  wire por_a;
  wire dco_wkup;
  wire cpu_en_wkup;
  wire cpu_enabled_with_dco;
  wire dco_not_enabled_by_dbg;
  wire dco_disable_by_scg0;
  wire dco_disable_by_cpu_en;
  wire dco_enable_nxt;

  omsp_and_gate
  and_dco_dis1
  (
    .y(cpu_enabled_with_dco),
    .a(~bcsctl2[7]),
    .b(cpuoff_and_mclk_enable)
  );


  omsp_and_gate
  and_dco_dis2
  (
    .y(dco_not_enabled_by_dbg),
    .a(~dbg_en_s),
    .b(~(cpu_enabled_with_dco | scg0_and_mclk_dma_enable))
  );


  omsp_and_gate
  and_dco_dis3
  (
    .y(dco_disable_by_scg0),
    .a(scg0),
    .b(dco_not_enabled_by_dbg)
  );


  omsp_and_gate
  and_dco_dis4
  (
    .y(dco_disable_by_cpu_en),
    .a(~cpu_en_s),
    .b(~mclk_enable)
  );


  omsp_and_gate
  and_dco_dis5
  (
    .y(dco_enable_nxt),
    .a(~dco_disable_by_scg0),
    .b(~dco_disable_by_cpu_en)
  );

  reg dco_disable;
  wire dco_wkup_set_scan_observe;

  always @(posedge nodiv_mclk or posedge por) if(por) dco_disable <= 1'b1; 
  else dco_disable <= ~dco_enable_nxt | dco_wkup_set_scan_observe;

  wire dco_clk_n;
  assign dco_clk_n = ~dco_clk;
  wire nodiv_mclk_n;
  assign nodiv_mclk_n = ~nodiv_mclk;
  reg dco_enable;

  always @(posedge nodiv_mclk_n or posedge por) if(por) dco_enable <= 1'b0; 
  else dco_enable <= ~dco_disable;

  wire dco_mclk_wkup;
  wire dco_en_wkup;

  omsp_and_gate
  and_dco_mclk_wkup
  (
    .y(dco_mclk_wkup),
    .a(mclk_wkup),
    .b(~bcsctl2[7])
  );


  omsp_and_gate
  and_dco_en_wkup
  (
    .y(dco_en_wkup),
    .a(~dco_enable),
    .b(dco_enable_nxt)
  );

  wire dco_wkup_set;assign dco_wkup_set = dco_mclk_wkup | scg0_and_mclk_dma_wkup | dco_en_wkup | cpu_en_wkup;
  wire dco_wkup_set_scan;

  omsp_scan_mux
  scan_mux_dco_wkup
  (
    .scan_mode(scan_mode),
    .data_in_scan(por_a),
    .data_in_func(dco_wkup_set | por),
    .data_out(dco_wkup_set_scan)
  );


  omsp_scan_mux
  scan_mux_dco_wkup_observe
  (
    .scan_mode(scan_mode),
    .data_in_scan(dco_wkup_set),
    .data_in_func(1'b0),
    .data_out(dco_wkup_set_scan_observe)
  );

  wire dco_wkup_n;

  omsp_sync_cell
  sync_cell_dco_wkup
  (
    .data_out(dco_wkup_n),
    .data_in(1'b1),
    .clk(dco_clk_n),
    .rst(dco_wkup_set_scan)
  );


  omsp_and_gate
  and_dco_wkup
  (
    .y(dco_wkup),
    .a(~dco_wkup_n),
    .b(cpu_en)
  );

  wire cpu_enabled_with_lfxt;
  wire lfxt_not_enabled_by_dbg;
  wire lfxt_disable_by_oscoff;
  wire lfxt_disable_by_cpu_en;
  wire lfxt_enable_nxt;

  omsp_and_gate
  and_lfxt_dis1
  (
    .y(cpu_enabled_with_lfxt),
    .a(bcsctl2[7]),
    .b(cpuoff_and_mclk_enable)
  );


  omsp_and_gate
  and_lfxt_dis2
  (
    .y(lfxt_not_enabled_by_dbg),
    .a(~dbg_en_s),
    .b(~(cpu_enabled_with_lfxt | oscoff_and_mclk_dma_enable))
  );


  omsp_and_gate
  and_lfxt_dis3
  (
    .y(lfxt_disable_by_oscoff),
    .a(oscoff),
    .b(lfxt_not_enabled_by_dbg)
  );


  omsp_and_gate
  and_lfxt_dis4
  (
    .y(lfxt_disable_by_cpu_en),
    .a(~cpu_en_s),
    .b(~mclk_enable)
  );


  omsp_and_gate
  and_lfxt_dis5
  (
    .y(lfxt_enable_nxt),
    .a(~lfxt_disable_by_oscoff),
    .b(~lfxt_disable_by_cpu_en)
  );

  reg lfxt_disable;
  wire lfxt_wkup_set_scan_observe;

  always @(posedge nodiv_mclk or posedge por) if(por) lfxt_disable <= 1'b1; 
  else lfxt_disable <= ~lfxt_enable_nxt | lfxt_wkup_set_scan_observe;

  wire lfxt_clk_n;
  assign lfxt_clk_n = ~lfxt_clk;

  omsp_sync_cell
  sync_cell_lfxt_disable
  (
    .data_out(lfxt_enable),
    .data_in(~lfxt_disable),
    .clk(lfxt_clk_n),
    .rst(por)
  );

  wire lfxt_mclk_wkup;
  wire lfxt_en_wkup;

  omsp_and_gate
  and_lfxt_mclk_wkup
  (
    .y(lfxt_mclk_wkup),
    .a(mclk_wkup),
    .b(bcsctl2[7])
  );


  omsp_and_gate
  and_lfxt_en_wkup
  (
    .y(lfxt_en_wkup),
    .a(~lfxt_enable),
    .b(lfxt_enable_nxt)
  );

  wire lfxt_wkup_set;assign lfxt_wkup_set = lfxt_mclk_wkup | oscoff_and_mclk_dma_wkup | lfxt_en_wkup | cpu_en_wkup;
  wire lfxt_wkup_set_scan;

  omsp_scan_mux
  scan_mux_lfxt_wkup
  (
    .scan_mode(scan_mode),
    .data_in_scan(por_a),
    .data_in_func(lfxt_wkup_set | por),
    .data_out(lfxt_wkup_set_scan)
  );


  omsp_scan_mux
  scan_mux_lfxt_wkup_observe
  (
    .scan_mode(scan_mode),
    .data_in_scan(lfxt_wkup_set),
    .data_in_func(1'b0),
    .data_out(lfxt_wkup_set_scan_observe)
  );

  wire lfxt_wkup_n;

  omsp_sync_cell
  sync_cell_lfxt_wkup
  (
    .data_out(lfxt_wkup_n),
    .data_in(1'b1),
    .clk(lfxt_clk_n),
    .rst(lfxt_wkup_set_scan)
  );


  omsp_and_gate
  and_lfxt_wkup
  (
    .y(lfxt_wkup),
    .a(~lfxt_wkup_n),
    .b(cpu_en)
  );

  assign cpu_en_s = cpu_en;
  assign cpu_en_wkup = 1'b0;
  wire cpu_en_aux_s;

  omsp_sync_cell
  sync_cell_cpu_aux_en
  (
    .data_out(cpu_en_aux_s),
    .data_in(cpu_en),
    .clk(lfxt_clk),
    .rst(por)
  );

  wire cpu_en_sm_s;assign cpu_en_sm_s = cpu_en_s;
  assign nodiv_mclk = dco_clk;
  wire cpuoff_and_mclk_dma_wkup_s;
  wire mclk_wkup_s;

  omsp_sync_cell
  sync_cell_mclk_dma_wkup
  (
    .data_out(cpuoff_and_mclk_dma_wkup_s),
    .data_in(cpuoff_and_mclk_dma_wkup),
    .clk(nodiv_mclk),
    .rst(puc_rst)
  );


  omsp_sync_cell
  sync_cell_mclk_wkup
  (
    .data_out(mclk_wkup_s),
    .data_in(mclk_wkup),
    .clk(nodiv_mclk),
    .rst(puc_rst)
  );

  wire mclk_active;assign mclk_active = mclk_enable | mclk_wkup_s | dbg_en_s & cpu_en_s;
  wire mclk_dma_active;assign mclk_dma_active = cpuoff_and_mclk_dma_enable | cpuoff_and_mclk_dma_wkup_s | mclk_active;
  reg [2:0] mclk_div;

  always @(posedge nodiv_mclk or posedge puc_rst) if(puc_rst) mclk_div <= 3'h0; 
  else if(bcsctl2[5:4] != 2'b00) mclk_div <= mclk_div + 3'h1; 

  wire mclk_div_sel;assign mclk_div_sel = (bcsctl2[5:4] == 2'b00)? 1'b1 : 
                        (bcsctl2[5:4] == 2'b01)? mclk_div[0] : 
                        (bcsctl2[5:4] == 2'b10)? &mclk_div[1:0] : &mclk_div[2:0];
  wire mclk_div_en;assign mclk_div_en = mclk_active & mclk_div_sel;
  wire mclk_dma_div_en;assign mclk_dma_div_en = mclk_dma_active & mclk_div_sel;

  omsp_clock_gate
  clock_gate_mclk
  (
    .gclk(cpu_mclk),
    .clk(nodiv_mclk),
    .enable(mclk_div_en),
    .scan_enable(scan_enable)
  );


  omsp_clock_gate
  clock_gate_dma_mclk
  (
    .gclk(dma_mclk),
    .clk(nodiv_mclk),
    .enable(mclk_dma_div_en),
    .scan_enable(scan_enable)
  );

  wire nodiv_aclk;assign nodiv_aclk = lfxt_clk;
  wire puc_lfxt_noscan_n;
  wire puc_lfxt_rst;

  omsp_sync_cell
  sync_cell_puc_lfxt
  (
    .data_out(puc_lfxt_noscan_n),
    .data_in(1'b1),
    .clk(nodiv_aclk),
    .rst(puc_rst)
  );


  omsp_scan_mux
  scan_mux_puc_lfxt
  (
    .scan_mode(scan_mode),
    .data_in_scan(por_a),
    .data_in_func(~puc_lfxt_noscan_n),
    .data_out(puc_lfxt_rst)
  );

  wire oscoff_s;

  omsp_sync_cell
  sync_cell_oscoff
  (
    .data_out(oscoff_s),
    .data_in(oscoff),
    .clk(nodiv_aclk),
    .rst(puc_lfxt_rst)
  );

  reg [1:0] divax_s;
  reg [1:0] divax_ss;

  always @(posedge nodiv_aclk or posedge puc_lfxt_rst) if(puc_lfxt_rst) begin
    divax_s <= 2'h0;
    divax_ss <= 2'h0;
  end else begin
    divax_s <= bcsctl1[5:4];
    divax_ss <= divax_s;
  end

  wire oscoff_and_mclk_dma_enable_s;

  omsp_sync_cell
  sync_cell_aclk_dma_wkup
  (
    .data_out(oscoff_and_mclk_dma_enable_s),
    .data_in(oscoff_and_mclk_dma_wkup | oscoff_and_mclk_dma_enable),
    .clk(nodiv_aclk),
    .rst(puc_lfxt_rst)
  );

  wire aclk_active;assign aclk_active = cpu_en_aux_s & (~oscoff_s | oscoff_and_mclk_dma_enable_s);
  reg [2:0] aclk_div;

  always @(posedge nodiv_aclk or posedge puc_lfxt_rst) if(puc_lfxt_rst) aclk_div <= 3'h0; 
  else if(divax_ss != 2'b00) aclk_div <= aclk_div + 3'h1; 

  wire aclk_div_sel;assign aclk_div_sel = (divax_ss == 2'b00)? 1'b1 : 
                        (divax_ss == 2'b01)? aclk_div[0] : 
                        (divax_ss == 2'b10)? &aclk_div[1:0] : &aclk_div[2:0];
  wire aclk_div_en;assign aclk_div_en = aclk_active & aclk_div_sel;

  omsp_clock_gate
  clock_gate_aclk
  (
    .gclk(aclk),
    .clk(nodiv_aclk),
    .enable(aclk_div_en),
    .scan_enable(scan_enable)
  );

  assign aclk_en = 1'b1;
  assign nodiv_smclk = dco_clk;
  wire puc_sm_rst;assign puc_sm_rst = puc_rst;
  wire [1:0] divsx_ss;assign divsx_ss = bcsctl2[2:1];
  wire scg1_s;assign scg1_s = scg1;
  wire scg1_and_mclk_dma_enable_s;
  wire scg1_and_mclk_dma_wkup_s;

  omsp_sync_cell
  sync_cell_smclk_dma_wkup
  (
    .data_out(scg1_and_mclk_dma_wkup_s),
    .data_in(scg1_and_mclk_dma_wkup),
    .clk(nodiv_smclk),
    .rst(puc_sm_rst)
  );

  assign scg1_and_mclk_dma_enable_s = scg1_and_mclk_dma_wkup_s | scg1_and_mclk_dma_enable;
  wire smclk_active;assign smclk_active = cpu_en_sm_s & (~scg1_s | scg1_and_mclk_dma_enable_s);
  reg [2:0] smclk_div;

  always @(posedge nodiv_smclk or posedge puc_sm_rst) if(puc_sm_rst) smclk_div <= 3'h0; 
  else if(divsx_ss != 2'b00) smclk_div <= smclk_div + 3'h1; 

  wire smclk_div_sel;assign smclk_div_sel = (divsx_ss == 2'b00)? 1'b1 : 
                         (divsx_ss == 2'b01)? smclk_div[0] : 
                         (divsx_ss == 2'b10)? &smclk_div[1:0] : &smclk_div[2:0];
  wire smclk_div_en;assign smclk_div_en = smclk_active & smclk_div_sel;

  omsp_clock_gate
  clock_gate_smclk
  (
    .gclk(smclk),
    .clk(nodiv_smclk),
    .enable(smclk_div_en),
    .scan_enable(scan_enable)
  );

  assign smclk_en = 1'b1;
  assign dbg_en_s = dbg_en;
  wire dbg_rst_nxt;assign dbg_rst_nxt = ~dbg_en;

  omsp_clock_gate
  clock_gate_dbg_clk
  (
    .gclk(dbg_clk),
    .clk(cpu_mclk),
    .enable(dbg_en_s),
    .scan_enable(scan_enable)
  );

  assign por_a = !reset_n;
  wire por_noscan;

  omsp_sync_reset
  sync_reset_por
  (
    .rst_s(por_noscan),
    .clk(nodiv_mclk),
    .rst_a(por_a)
  );


  omsp_scan_mux
  scan_mux_por
  (
    .scan_mode(scan_mode),
    .data_in_scan(por_a),
    .data_in_func(por_noscan),
    .data_out(por)
  );

  reg dbg_rst_noscan;

  always @(posedge cpu_mclk or posedge por) if(por) dbg_rst_noscan <= 1'b1; 
  else dbg_rst_noscan <= dbg_rst_nxt;


  omsp_scan_mux
  scan_mux_dbg_rst
  (
    .scan_mode(scan_mode),
    .data_in_scan(por_a),
    .data_in_func(dbg_rst_noscan),
    .data_out(dbg_rst)
  );

  wire puc_noscan_n;
  wire puc_a_scan;
  wire puc_a;assign puc_a = por | wdt_reset;
  wire puc_s;assign puc_s = dbg_cpu_reset | dbg_en_s & dbg_rst_noscan & ~puc_noscan_n;

  omsp_scan_mux
  scan_mux_puc_rst_a
  (
    .scan_mode(scan_mode),
    .data_in_scan(por_a),
    .data_in_func(puc_a),
    .data_out(puc_a_scan)
  );


  omsp_sync_cell
  sync_cell_puc
  (
    .data_out(puc_noscan_n),
    .data_in(~puc_s),
    .clk(cpu_mclk),
    .rst(puc_a_scan)
  );


  omsp_scan_mux
  scan_mux_puc_rst
  (
    .scan_mode(scan_mode),
    .data_in_scan(por_a),
    .data_in_func(~puc_noscan_n),
    .data_out(puc_rst)
  );

  assign puc_pnd_set = ~puc_noscan_n;

endmodule

