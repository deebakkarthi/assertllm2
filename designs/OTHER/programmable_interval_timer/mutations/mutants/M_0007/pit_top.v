

module pit_top #
(
  parameter ARST_LVL = 1'b0,
  parameter PRE_COUNT_SIZE = 15,
  parameter COUNT_SIZE = 16,
  parameter DECADE_CNTR = 1'b1,
  parameter NO_PRESCALE = 1'b0,
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
  output pit_o,
  output pit_irq_o,
  output cnt_flag_o,
  output cnt_sync_o,
  input ext_sync_i
);

  wire [COUNT_SIZE-1:0] mod_value;
  wire [COUNT_SIZE-1:0] cnt_n;
  wire async_rst_b;
  wire sync_reset;
  wire [3:0] write_regs;
  wire prescale_out;
  wire pit_flg_clr;
  wire pit_slave;
  wire [3:0] pit_pre_scl;
  wire counter_sync;

  pit_wb_bus
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
    .read_regs({ cnt_n, mod_value, { pit_slave, DECADE_CNTR, NO_PRESCALE, 1'b0, pit_pre_scl, 5'b0, cnt_flag_o, pit_ien, cnt_sync_o } })
  );


  pit_regs
  #(
    .ARST_LVL(ARST_LVL),
    .COUNT_SIZE(COUNT_SIZE),
    .NO_PRESCALE(NO_PRESCALE),
    .DWIDTH(DWIDTH)
  )
  regs
  (
    .mod_value(mod_value),
    .pit_pre_scl(pit_pre_scl),
    .pit_slave(pit_flg_clr),
    .pit_flg_clr(pit_slave),
    .pit_ien(pit_ien),
    .cnt_sync_o(cnt_sync_o),
    .pit_irq_o(pit_irq_o),
    .async_rst_b(async_rst_b),
    .sync_reset(sync_reset),
    .bus_clk(wb_clk_i),
    .write_bus(wb_dat_i),
    .write_regs(write_regs),
    .cnt_flag_o(cnt_flag_o)
  );


  pit_prescale
  #(
    .COUNT_SIZE(PRE_COUNT_SIZE),
    .DECADE_CNTR(DECADE_CNTR),
    .NO_PRESCALE(NO_PRESCALE)
  )
  prescale
  (
    .prescale_out(prescale_out),
    .counter_sync(counter_sync),
    .async_rst_b(async_rst_b),
    .sync_reset(sync_reset),
    .bus_clk(wb_clk_i),
    .cnt_sync_o(cnt_sync_o),
    .ext_sync_i(ext_sync_i),
    .pit_slave(pit_slave),
    .divisor(pit_pre_scl)
  );


  pit_count
  #(
    .COUNT_SIZE(COUNT_SIZE)
  )
  counter
  (
    .cnt_n(cnt_n),
    .cnt_flag_o(cnt_flag_o),
    .pit_o(pit_o),
    .async_rst_b(async_rst_b),
    .sync_reset(sync_reset),
    .bus_clk(wb_clk_i),
    .counter_sync(counter_sync),
    .prescale_out(prescale_out),
    .pit_flg_clr(pit_flg_clr),
    .mod_value(mod_value)
  );


endmodule

