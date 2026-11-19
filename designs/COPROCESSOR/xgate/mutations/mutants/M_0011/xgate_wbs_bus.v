

module xgate_wbs_bus #
(
  parameter ARST_LVL = 1'b0,
  parameter DWIDTH = 16,
  parameter WB_RD_DEFAULT = 0,
  parameter SINGLE_CYCLE = 1'b0
)
(
  output [DWIDTH-1:0] wbs_dat_o,
  output wbs_ack_o,
  output wbs_err_o,
  input wbs_clk_i,
  input wbs_rst_i,
  input arst_i,
  input [6:1] wbs_adr_i,
  input wbs_we_i,
  input wbs_stb_i,
  input wbs_cyc_i,
  input [1:0] wbs_sel_i,
  output reg write_xgmctl,
  output reg write_xgchid,
  output reg write_xgisp74,
  output reg write_xgisp30,
  output reg [1:0] write_xgvbr,
  output reg [1:0] write_xgif_7,
  output reg [1:0] write_xgif_6,
  output reg [1:0] write_xgif_5,
  output reg [1:0] write_xgif_4,
  output reg [1:0] write_xgif_3,
  output reg [1:0] write_xgif_2,
  output reg [1:0] write_xgif_1,
  output reg [1:0] write_xgif_0,
  output reg write_xgswt,
  output reg write_xgsem,
  output reg write_xgccr,
  output reg [1:0] write_xgpc,
  output reg [1:0] write_xgr7,
  output reg [1:0] write_xgr6,
  output reg [1:0] write_xgr5,
  output reg [1:0] write_xgr4,
  output reg [1:0] write_xgr3,
  output reg [1:0] write_xgr2,
  output reg [1:0] write_xgr1,
  output reg [1:0] write_irw_en_7,
  output reg [1:0] write_irw_en_6,
  output reg [1:0] write_irw_en_5,
  output reg [1:0] write_irw_en_4,
  output reg [1:0] write_irw_en_3,
  output reg [1:0] write_irw_en_2,
  output reg [1:0] write_irw_en_1,
  output reg [1:0] write_irw_en_0,
  output async_rst_b,
  output sync_reset,
  input [415:0] read_risc_regs,
  input [127:1] irq_bypass
);

  reg bus_wait_state;
  reg [5:0] addr_latch;
  reg write_reserv1;
  reg write_reserv2;
  reg [DWIDTH-1:0] read_mux_irq;
  wire module_sel;
  wire wbs_wacc;
  wire wbs_racc;
  wire [5:0] address;
  reg [DWIDTH-1:0] read_mux_risc;
  assign async_rst_b = arst_i ^ ARST_LVL;
  assign sync_reset = wbs_rst_i;
  assign module_sel = wbs_cyc_i && wbs_stb_i;
  assign wbs_wacc = module_sel && wbs_we_i && (wbs_ack_o || SINGLE_CYCLE);
  assign wbs_racc = module_sel && !wbs_we_i;
  assign wbs_ack_o = (SINGLE_CYCLE)? module_sel : bus_wait_state && module_sel;
  assign wbs_err_o = !SINGLE_CYCLE && !module_sel && bus_wait_state;
  assign address = (SINGLE_CYCLE)? wbs_adr_i : addr_latch;
  assign wbs_dat_o = read_mux_risc | read_mux_irq;

  always @(posedge wbs_clk_i or negedge async_rst_b) if(!async_rst_b) bus_wait_state <= 1'b0; 
  else if(sync_reset) bus_wait_state <= 1'b0; 
  else bus_wait_state <= module_sel && !bus_wait_state;


  always @(posedge wbs_clk_i) if(module_sel) addr_latch <= wbs_adr_i; 


  always @(*) case({ wbs_racc, address })
    7'b100_0000: read_mux_risc = read_risc_regs[15:0];
    7'b100_0001: read_mux_risc = read_risc_regs[31:16];
    7'b100_0010: read_mux_risc = read_risc_regs[47:32];
    7'b100_0011: read_mux_risc = read_risc_regs[63:48];
    7'b100_0100: read_mux_risc = read_risc_regs[79:64];
    7'b100_0101: read_mux_risc = read_risc_regs[95:80];
    7'b100_0110: read_mux_risc = read_risc_regs[111:96];
    7'b100_0111: read_mux_risc = read_risc_regs[127:112];
    7'b100_1000: read_mux_risc = read_risc_regs[143:128];
    7'b100_1001: read_mux_risc = read_risc_regs[159:144];
    7'b100_1010: read_mux_risc = read_risc_regs[175:160];
    7'b100_1011: read_mux_risc = read_risc_regs[191:176];
    7'b100_1100: read_mux_risc = read_risc_regs[207:192];
    7'b100_1101: read_mux_risc = read_risc_regs[223:208];
    7'b100_1110: read_mux_risc = read_risc_regs[239:224];
    7'b100_1111: read_mux_risc = read_risc_regs[255:240];
    7'b101_0000: read_mux_risc = read_risc_regs[271:256];
    7'b101_0001: read_mux_risc = read_risc_regs[287:272];
    7'b101_0010: read_mux_risc = read_risc_regs[303:288];
    7'b101_0011: read_mux_risc = read_risc_regs[319:304];
    7'b101_0100: read_mux_risc = read_risc_regs[335:320];
    7'b101_0101: read_mux_risc = read_risc_regs[351:336];
    7'b101_0110: read_mux_risc = read_risc_regs[367:352];
    7'b101_0111: read_mux_risc = read_risc_regs[383:368];
    7'b101_1000: read_mux_risc = read_risc_regs[399:384];
    7'b101_1001: read_mux_risc = read_risc_regs[415:400];
    default: read_mux_risc = { DWIDTH{ WB_RD_DEFAULT } };
  endcase


  always @(*) begin
    write_reserv1 = 1'b0;
    write_reserv2 = 1'b0;
    write_xgmctl = 1'b0;
    write_xgchid = 1'b0;
    write_xgisp74 = 1'b0;
    write_xgisp30 = 1'b0;
    write_xgvbr = 2'b00;
    write_xgif_7 = 2'b00;
    write_xgif_6 = 2'b00;
    write_xgif_5 = 2'b00;
    write_xgif_4 = 2'b00;
    write_xgif_3 = 2'b00;
    write_xgif_2 = 2'b00;
    write_xgif_1 = 2'b00;
    write_xgif_0 = 2'b00;
    write_xgswt = 1'b0;
    write_xgsem = 1'b0;
    write_xgccr = 1'b0;
    write_xgpc = 2'b00;
    write_xgr7 = 2'b00;
    write_xgr6 = 2'b00;
    write_xgr5 = 2'b00;
    write_xgr4 = 2'b00;
    write_xgr3 = 2'b00;
    write_xgr2 = 2'b00;
    write_xgr1 = 2'b00;
    if(wbs_wacc) case(address)
      6'b00_0000: write_xgmctl = &wbs_sel_i;
      6'b00_0001: write_xgchid = wbs_sel_i[0];
      6'b00_0010: write_xgisp74 = 1'b1;
      6'b00_0011: write_xgisp30 = 1'b1;
      6'b00_0100: write_xgvbr = wbs_sel_i;
      6'b00_0101: write_xgif_7 = wbs_sel_i;
      6'b00_0110: write_xgif_6 = wbs_sel_i;
      6'b00_0111: write_xgif_5 = wbs_sel_i;
      6'b00_1000: write_xgif_4 = wbs_sel_i;
      6'b00_1001: write_xgif_3 = wbs_sel_i;
      6'b00_1010: write_xgif_2 = wbs_sel_i;
      6'b00_1011: write_xgif_1 = wbs_sel_i;
      6'b00_1100: write_xgif_0 = wbs_sel_i;
      6'b00_1101: write_xgswt = &wbs_sel_i;
      6'b00_1110: write_xgsem = &wbs_sel_i;
      6'b00_1111: write_reserv1 = 1'b1;
      6'b01_0000: write_xgccr = wbs_sel_i[0];
      6'b01_0001: write_xgpc = wbs_sel_i;
      6'b01_0010: write_reserv2 = 1'b1;
      6'b01_0011: write_xgr1 = wbs_sel_i;
      6'b01_0100: write_xgr2 = wbs_sel_i;
      6'b01_0101: write_xgr3 = wbs_sel_i;
      6'b01_0110: write_xgr4 = wbs_sel_i;
      6'b01_0111: write_xgr5 = wbs_sel_i;
      6'b01_1000: write_xgr6 = wbs_sel_i;
      6'b01_1001: write_xgr7 = wbs_sel_i;
      default: ;
    endcase 
  end


  always @(*) case({ wbs_racc, address })
    7'b110_0000: read_mux_irq = { irq_bypass[15:1], 1'b0 };
    7'b110_0001: read_mux_irq = irq_bypass[31:17];
    7'b110_0010: read_mux_irq = irq_bypass[47:32];
    7'b110_0011: read_mux_irq = irq_bypass[63:48];
    7'b110_0100: read_mux_irq = irq_bypass[79:64];
    7'b110_0101: read_mux_irq = irq_bypass[95:80];
    7'b110_0110: read_mux_irq = irq_bypass[111:96];
    7'b110_0111: read_mux_irq = irq_bypass[127:112];
    default: read_mux_irq = { DWIDTH{ WB_RD_DEFAULT } };
  endcase


  always @(*) begin
    write_irw_en_7 = 2'b00;
    write_irw_en_6 = 2'b00;
    write_irw_en_5 = 2'b00;
    write_irw_en_4 = 2'b00;
    write_irw_en_3 = 2'b00;
    write_irw_en_2 = 2'b00;
    write_irw_en_1 = 2'b00;
    write_irw_en_0 = 2'b00;
    if(wbs_wacc) case(address)
      6'b10_0000: write_irw_en_0 = wbs_sel_i;
      6'b10_0001: write_irw_en_1 = wbs_sel_i;
      6'b10_0010: write_irw_en_2 = wbs_sel_i;
      6'b10_0011: write_irw_en_3 = wbs_sel_i;
      6'b10_0100: write_irw_en_4 = wbs_sel_i;
      6'b10_0101: write_irw_en_5 = wbs_sel_i;
      6'b10_0110: write_irw_en_6 = wbs_sel_i;
      6'b10_0111: write_irw_en_7 = wbs_sel_i;
      default: ;
    endcase 
  end


endmodule

