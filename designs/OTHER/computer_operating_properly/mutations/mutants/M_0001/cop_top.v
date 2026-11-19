

module cop_top #
(
  parameter ARST_LVL = 1'b0,
  parameter INIT_ENA = 1'b1,
  parameter SERV_WD_0 = 16'h5555,
  parameter SERV_WD_1 = 16'haaaa,
  parameter COUNT_SIZE = 16,
  parameter SINGLE_CYCLE = 1'b0,
  parameter DWIDTH = 16
)
(
  output [DWIDTH-1:0] wb_dat_o,
  output wb_ack_o,
  input wb_clk_i,
  input wb_rst_i,
  input arst_i,
  input [2:0] wb_adr_i,
  input [DWIDTH-1:0] wb_dat_i,
  input wb_we_i,
  input wb_stb_i,
  input wb_cyc_i,
  input [1:0] wb_sel_i,
  output cop_rst_o,
  output cop_irq_o,
  input por_reset_i,
  input startup_osc_i,
  input stop_mode_i,
  input wait_mode_i,
  input debug_mode_i,
  input scantestmode
);

  wire cop_event;
  wire [1:0] cop_irq_en;
  wire [COUNT_SIZE-1:0] cop_counter;
  wire [COUNT_SIZE-1:0] cop_capture;
  wire async_rst_b;
  wire sync_reset;
  wire [4:0] write_regs;
  wire prescale_out;
  wire stop_ena;
  wire debug_ena;
  wire wait_ena;
  wire cop_ena;
  wire cwp;
  wire clck;
  wire reload_count;
  wire clear_event;
  wire [COUNT_SIZE-1:0] timeout_value;
  wire counter_sync;

  cop_wb_bus
  #(
    .ARST_LVL(ARST_LVL),
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .DWIDTH(DWIDTH)
  )
  wishbone
  (
    .wb_dat_o(wb_dat_o),
    .wb_ack_o(wb_ack_o),
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .arst_i(arst_i),
    .wb_adr_i(wb_adr_i),
    .wb_dat_i(wb_dat_i),
    .wb_we_i(wb_we_i),
    .wb_stb_i(wb_stb_i),
    .wb_cyc_i(wb_cyc_i),
    .wb_sel_i(wb_sel_i),
    .write_regs(write_regs),
    .sync_reset(sync_reset),
    .async_rst_b(async_rst_b),
    .irq_source(cnt_flag_o),
    .read_regs({ cop_capture, timeout_value, { 7'b0, cop_event, cop_irq_en, debug_ena, stop_ena, wait_ena, cop_ena, cwp, clck } })
  );


  cop_regs
  #(
    .ARST_LVL(ARST_LVL),
    .INIT_ENA(INIT_ENA),
    .SERV_WD_0(SERV_WD_0),
    .SERV_WD_1(SERV_WD_1),
    .COUNT_SIZE(COUNT_SIZE),
    .DWIDTH(DWIDTH)
  )
  regs
  (
    .cop_irq_en(cop_irq_en),
    .timeout_value(timeout_value),
    .debug_ena(cwp),
    .stop_ena(stop_ena),
    .wait_ena(wait_ena),
    .cop_ena(cop_ena),
    .cwp(debug_ena),
    .clck(clck),
    .reload_count(reload_count),
    .clear_event(clear_event),
    .async_rst_b(async_rst_b),
    .sync_reset(sync_reset),
    .bus_clk(wb_clk_i),
    .write_bus(wb_dat_i),
    .write_regs(write_regs)
  );


  cop_count
  #(
    .COUNT_SIZE(COUNT_SIZE)
  )
  counter
  (
    .cop_counter(cop_counter),
    .cop_capture(cop_capture),
    .cop_rst_o(cop_rst_o),
    .cop_irq_o(cop_irq_o),
    .cop_event(cop_event),
    .por_reset_i(por_reset_i),
    .async_rst_b(async_rst_b),
    .sync_reset(sync_reset),
    .startup_osc_i(startup_osc_i),
    .bus_clk(wb_clk_i),
    .reload_count(reload_count),
    .clear_event(clear_event),
    .debug_ena(debug_ena),
    .debug_mode_i(debug_mode_i),
    .wait_ena(wait_ena),
    .wait_mode_i(wait_mode_i),
    .stop_ena(stop_ena),
    .stop_mode_i(stop_mode_i),
    .cop_ena(cop_ena),
    .cop_irq_en(cop_irq_en),
    .timeout_value(timeout_value),
    .scantestmode(scantestmode)
  );


endmodule

