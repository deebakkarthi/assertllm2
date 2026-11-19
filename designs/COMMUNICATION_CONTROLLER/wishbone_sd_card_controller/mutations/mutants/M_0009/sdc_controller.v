

module sdc_controller
(
  wb_clk_i,
  wb_rst,
  wb_dat_i,
  wb_dat_o,
  wb_adr_i,
  wb_sel_i,
  wb_we_i,
  wb_cyc_i,
  wb_stb_i,
  wb_ack_o,
  m_wb_dat_o,
  m_wb_dat_i,
  m_wb_adr_o,
  m_wb_sel_o,
  m_wb_we_o,
  m_wb_cyc_o,
  m_wb_stb_o,
  m_wb_ack_i,
  m_wb_cti_o,
  m_wb_bte_o,
  sd_cmd_dat_i,
  sd_cmd_out_o,
  sd_cmd_oe_o,
  sd_dat_dat_i,
  sd_dat_out_o,
  sd_dat_oe_o,
  sd_clk_o_pad,
  sd_clk_i_pad,
  int_cmd,
  int_data
);

  input wb_clk_i;
  input wb_rst;
  input [31:0] wb_dat_i;
  output [31:0] wb_dat_o;
  input [7:0] wb_adr_i;
  input [3:0] wb_sel_i;
  input wb_we_i;
  input wb_cyc_i;
  input wb_stb_i;
  output wb_ack_o;
  output [31:0] m_wb_adr_o;
  output [3:0] m_wb_sel_o;
  output m_wb_we_o;
  input [31:0] m_wb_dat_i;
  output [31:0] m_wb_dat_o;
  output m_wb_cyc_o;
  output m_wb_stb_o;
  input m_wb_ack_i;
  output [2:0] m_wb_cti_o;
  output [1:0] m_wb_bte_o;
  input [3:0] sd_dat_dat_i;wire [3:0] sd_dat_dat_i;
  output [3:0] sd_dat_out_o;wire [3:0] sd_dat_out_o;
  output sd_dat_oe_o;wire sd_dat_oe_o;
  input sd_cmd_dat_i;wire sd_cmd_dat_i;
  output sd_cmd_out_o;wire sd_cmd_out_o;
  output sd_cmd_oe_o;wire sd_cmd_oe_o;
  output sd_clk_o_pad;
  input sd_clk_i_pad;wire sd_clk_i_pad;
  output int_cmd;output int_data;
  wire sd_clk_o;
  wire go_idle;
  wire cmd_start_wb_clk;
  wire cmd_start_sd_clk;
  wire cmd_start;
  wire [1:0] cmd_setting;
  wire cmd_start_tx;
  wire [39:0] cmd;
  wire [119:0] cmd_response;
  wire cmd_crc_ok;
  wire cmd_index_ok;
  wire cmd_finish;
  wire d_write;
  wire d_read;
  wire [31:0] data_in_rx_fifo;
  wire [31:0] data_out_tx_fifo;
  wire start_tx_fifo;
  wire start_rx_fifo;
  wire tx_fifo_empty;
  wire tx_fifo_full;
  wire rx_fifo_full;
  wire sd_data_busy;
  wire data_busy;
  wire data_crc_ok;
  wire rd_fifo;
  wire we_fifo;
  wire data_start_rx;
  wire data_start_tx;
  wire cmd_int_rst_wb_clk;
  wire cmd_int_rst_sd_clk;
  wire cmd_int_rst;
  wire data_int_rst_wb_clk;
  wire data_int_rst_sd_clk;
  wire data_int_rst;
  wire [31:0] argument_reg_wb_clk;
  wire [14-1:0] command_reg_wb_clk;
  wire [15:0] timeout_reg_wb_clk;
  wire [0:0] software_reset_reg_wb_clk;
  wire [31:0] response_0_reg_wb_clk;
  wire [31:0] response_1_reg_wb_clk;
  wire [31:0] response_2_reg_wb_clk;
  wire [31:0] response_3_reg_wb_clk;
  wire [12-1:0] block_size_reg_wb_clk;
  wire [15:0] controll_setting_reg_wb_clk;
  wire [5-1:0] cmd_int_status_reg_wb_clk;
  wire [3-1:0] data_int_status_reg_wb_clk;
  wire [5-1:0] cmd_int_enable_reg_wb_clk;
  wire [3-1:0] data_int_enable_reg_wb_clk;
  wire [16-1:0] block_count_reg_wb_clk;
  wire [31:0] dma_addr_reg_wb_clk;
  wire [7:0] clock_divider_reg_wb_clk;
  wire [31:0] argument_reg_sd_clk;
  wire [14-1:0] command_reg_sd_clk;
  wire [15:0] timeout_reg_sd_clk;
  wire [0:0] software_reset_reg_sd_clk;
  wire [31:0] response_0_reg_sd_clk;
  wire [31:0] response_1_reg_sd_clk;
  wire [31:0] response_2_reg_sd_clk;
  wire [31:0] response_3_reg_sd_clk;
  wire [12-1:0] block_size_reg_sd_clk;
  wire [15:0] controll_setting_reg_sd_clk;
  wire [5-1:0] cmd_int_status_reg_sd_clk;
  wire [2:0] data_int_status_reg_sd_clk;
  wire [5-1:0] cmd_int_enable_reg_sd_clk;
  wire [2:0] data_int_enable_reg_sd_clk;
  wire [16-1:0] block_count_reg_sd_clk;
  wire [31:0] dma_addr_reg_sd_clk;
  wire [7:0] clock_divider_reg_sd_clk;

  sd_clock_divider
  clock_divider0
  (
    .CLK(sd_clk_i_pad),
    .DIVIDER(clock_divider_reg_sd_clk),
    .RST(wb_rst),
    .SD_CLK(sd_clk_o)
  );

  assign sd_clk_o_pad = sd_clk_o;

  sd_cmd_master
  sd_cmd_master0
  (
    .sd_clk(sd_clk_o),
    .rst(wb_rst | software_reset_reg_sd_clk[0]),
    .start_i(cmd_start_sd_clk),
    .int_status_rst_i(cmd_int_rst_sd_clk),
    .setting_o(cmd_setting),
    .start_xfr_o(cmd_start_tx),
    .go_idle_o(go_idle),
    .cmd_o(cmd),
    .response_i(cmd_response),
    .crc_ok_i(cmd_crc_ok),
    .index_ok_i(cmd_index_ok),
    .busy_i(sd_data_busy),
    .finish_i(cmd_finish),
    .argument_i(argument_reg_sd_clk),
    .command_i(command_reg_sd_clk),
    .timeout_i(timeout_reg_sd_clk),
    .int_status_o(cmd_int_status_reg_sd_clk),
    .response_0_o(response_0_reg_sd_clk),
    .response_1_o(response_1_reg_sd_clk),
    .response_2_o(response_2_reg_sd_clk),
    .response_3_o(response_3_reg_sd_clk)
  );


  sd_cmd_serial_host
  cmd_serial_host0
  (
    .sd_clk(sd_clk_o),
    .rst(wb_rst | software_reset_reg_sd_clk[0] | go_idle),
    .setting_i(cmd_setting),
    .cmd_i(cmd),
    .start_i(cmd_start_tx),
    .finish_o(cmd_finish),
    .response_o(cmd_response),
    .crc_ok_o(cmd_crc_ok),
    .index_ok_o(cmd_index_ok),
    .cmd_dat_i(sd_cmd_dat_i),
    .cmd_out_o(sd_cmd_out_o),
    .cmd_oe_o(sd_cmd_oe_o)
  );


  sd_data_master
  sd_data_master0
  (
    .sd_clk(sd_clk_o),
    .rst(wb_rst | software_reset_reg_sd_clk[0]),
    .start_tx_i(data_start_tx),
    .start_rx_i(data_start_rx),
    .d_write_o(d_write),
    .d_read_o(d_read),
    .start_tx_fifo_o(start_tx_fifo),
    .start_rx_fifo_o(start_rx_fifo),
    .tx_fifo_empty_i(tx_fifo_empty),
    .tx_fifo_full_i(tx_fifo_full),
    .rx_fifo_full_i(rx_fifo_full),
    .xfr_complete_i(!data_busy),
    .crc_ok_i(data_crc_ok),
    .int_status_o(data_int_status_reg_sd_clk),
    .int_status_rst_i(data_int_rst_sd_clk)
  );


  sd_data_serial_host
  sd_data_serial_host0
  (
    .sd_clk(sd_clk_o),
    .rst(wb_rst | software_reset_reg_sd_clk[0]),
    .data_in(data_out_tx_fifo),
    .rd(rd_fifo),
    .data_out(data_in_rx_fifo),
    .we(we_fifo),
    .DAT_oe_o(sd_dat_oe_o),
    .DAT_dat_o(sd_dat_out_o),
    .DAT_dat_i(sd_dat_dat_i),
    .blksize(block_size_reg_sd_clk),
    .bus_4bit(controll_setting_reg_sd_clk[0]),
    .blkcnt(block_count_reg_sd_clk),
    .start({ d_read, d_write }),
    .sd_data_busy(sd_data_busy),
    .busy(data_busy),
    .crc_ok(data_crc_ok)
  );


  sd_fifo_filler
  sd_fifo_filler0
  (
    .wb_clk(wb_clk_i),
    .rst(wb_rst | software_reset_reg_sd_clk[0]),
    .wbm_adr_o(m_wb_adr_o),
    .wbm_we_o(we_fifo),
    .wbm_dat_o(m_wb_dat_o),
    .wbm_dat_i(m_wb_dat_i),
    .wbm_cyc_o(rx_fifo_full),
    .wbm_stb_o(rd_fifo),
    .wbm_ack_i(tx_fifo_empty),
    .en_rx_i(start_rx_fifo),
    .en_tx_i(m_wb_stb_o),
    .adr_i(data_out_tx_fifo),
    .sd_clk(sd_clk_o),
    .dat_i(data_in_rx_fifo),
    .dat_o(dma_addr_reg_sd_clk),
    .wr_i(m_wb_ack_i),
    .rd_i(start_tx_fifo),
    .sd_empty_o(tx_fifo_full),
    .sd_full_o(m_wb_cyc_o),
    .wb_empty_o(),
    .wb_full_o(m_wb_we_o)
  );


  sd_data_xfer_trig
  sd_data_xfer_trig0
  (
    .sd_clk(sd_clk_o),
    .rst(wb_rst | software_reset_reg_sd_clk[0]),
    .cmd_with_data_start_i(cmd_start_sd_clk & (command_reg_sd_clk[6:5] != 2'b00)),
    .r_w_i(command_reg_sd_clk[6:5] == 2'b01),
    .cmd_int_status_i(cmd_int_status_reg_sd_clk),
    .start_tx_o(data_start_tx),
    .start_rx_o(data_start_rx)
  );


  sd_controller_wb
  sd_controller_wb0
  (
    .wb_clk_i(wb_clk_i),
    .wb_rst(wb_rst),
    .wb_dat_i(wb_dat_i),
    .wb_dat_o(wb_dat_o),
    .wb_adr_i(wb_adr_i),
    .wb_sel_i(wb_sel_i),
    .wb_we_i(wb_we_i),
    .wb_stb_i(wb_stb_i),
    .wb_cyc_i(wb_cyc_i),
    .wb_ack_o(wb_ack_o),
    .cmd_start(cmd_start),
    .data_int_rst(data_int_rst),
    .cmd_int_rst(cmd_int_rst),
    .argument_reg(argument_reg_wb_clk),
    .command_reg(command_reg_wb_clk),
    .response_0_reg(response_0_reg_wb_clk),
    .response_1_reg(response_1_reg_wb_clk),
    .response_2_reg(response_2_reg_wb_clk),
    .response_3_reg(response_3_reg_wb_clk),
    .software_reset_reg(software_reset_reg_wb_clk),
    .timeout_reg(timeout_reg_wb_clk),
    .block_size_reg(block_size_reg_wb_clk),
    .controll_setting_reg(controll_setting_reg_wb_clk),
    .cmd_int_status_reg(cmd_int_status_reg_wb_clk),
    .cmd_int_enable_reg(cmd_int_enable_reg_wb_clk),
    .clock_divider_reg(clock_divider_reg_wb_clk),
    .block_count_reg(block_count_reg_wb_clk),
    .dma_addr_reg(dma_addr_reg_wb_clk),
    .data_int_status_reg(data_int_status_reg_wb_clk),
    .data_int_enable_reg(data_int_enable_reg_wb_clk)
  );


  edge_detect
  cmd_start_edge
  (
    .rst(wb_rst),
    .clk(wb_clk_i),
    .sig(cmd_start),
    .rise(cmd_start_wb_clk),
    .fall()
  );


  edge_detect
  data_int_rst_edge
  (
    .rst(wb_rst),
    .clk(wb_clk_i),
    .sig(data_int_rst),
    .rise(data_int_rst_wb_clk),
    .fall()
  );


  edge_detect
  cmd_int_rst_edge
  (
    .rst(wb_rst),
    .clk(wb_clk_i),
    .sig(cmd_int_rst),
    .rise(cmd_int_rst_wb_clk),
    .fall()
  );


  monostable_domain_cross
  cmd_start_cross
  (
    wb_rst,
    wb_clk_i,
    cmd_start_wb_clk,
    sd_clk_o,
    cmd_start_sd_clk
  );


  monostable_domain_cross
  data_int_rst_cross
  (
    wb_rst,
    wb_clk_i,
    data_int_rst_wb_clk,
    sd_clk_o,
    data_int_rst_sd_clk
  );


  monostable_domain_cross
  cmd_int_rst_cross
  (
    wb_rst,
    wb_clk_i,
    cmd_int_rst_wb_clk,
    sd_clk_o,
    cmd_int_rst_sd_clk
  );


  bistable_domain_cross
  #(
    32
  )
  argument_reg_cross
  (
    wb_rst,
    wb_clk_i,
    argument_reg_wb_clk,
    sd_clk_o,
    argument_reg_sd_clk
  );


  bistable_domain_cross
  #(
    14
  )
  command_reg_cross
  (
    wb_rst,
    wb_clk_i,
    command_reg_wb_clk,
    sd_clk_o,
    command_reg_sd_clk
  );


  bistable_domain_cross
  #(
    32
  )
  response_0_reg_cross
  (
    wb_rst,
    sd_clk_o,
    response_0_reg_sd_clk,
    wb_clk_i,
    response_0_reg_wb_clk
  );


  bistable_domain_cross
  #(
    32
  )
  response_1_reg_cross
  (
    wb_rst,
    sd_clk_o,
    response_1_reg_sd_clk,
    wb_clk_i,
    response_1_reg_wb_clk
  );


  bistable_domain_cross
  #(
    32
  )
  response_2_reg_cross
  (
    wb_rst,
    sd_clk_o,
    response_2_reg_sd_clk,
    wb_clk_i,
    response_2_reg_wb_clk
  );


  bistable_domain_cross
  #(
    32
  )
  response_3_reg_cross
  (
    wb_rst,
    sd_clk_o,
    response_3_reg_sd_clk,
    wb_clk_i,
    response_3_reg_wb_clk
  );


  bistable_domain_cross
  software_reset_reg_cross
  (
    wb_rst,
    wb_clk_i,
    software_reset_reg_wb_clk,
    sd_clk_o,
    software_reset_reg_sd_clk
  );


  bistable_domain_cross
  #(
    16
  )
  timeout_reg_cross
  (
    wb_rst,
    wb_clk_i,
    timeout_reg_wb_clk,
    sd_clk_o,
    timeout_reg_sd_clk
  );


  bistable_domain_cross
  #(
    12
  )
  block_size_reg_cross
  (
    wb_rst,
    wb_clk_i,
    block_size_reg_wb_clk,
    sd_clk_o,
    block_size_reg_sd_clk
  );


  bistable_domain_cross
  #(
    16
  )
  controll_setting_reg_cross
  (
    wb_rst,
    wb_clk_i,
    controll_setting_reg_wb_clk,
    sd_clk_o,
    controll_setting_reg_sd_clk
  );


  bistable_domain_cross
  #(
    5
  )
  cmd_int_status_reg_cross
  (
    wb_rst,
    sd_clk_o,
    cmd_int_status_reg_sd_clk,
    wb_clk_i,
    cmd_int_status_reg_wb_clk
  );


  bistable_domain_cross
  #(
    5
  )
  cmd_int_enable_reg_cross
  (
    wb_rst,
    wb_clk_i,
    cmd_int_enable_reg_wb_clk,
    sd_clk_o,
    cmd_int_enable_reg_sd_clk
  );


  bistable_domain_cross
  #(
    8
  )
  clock_divider_reg_cross
  (
    wb_rst,
    wb_clk_i,
    clock_divider_reg_wb_clk,
    sd_clk_i_pad,
    clock_divider_reg_sd_clk
  );


  bistable_domain_cross
  #(
    16
  )
  block_count_reg_cross
  (
    wb_rst,
    wb_clk_i,
    block_count_reg_wb_clk,
    sd_clk_o,
    block_count_reg_sd_clk
  );


  bistable_domain_cross
  #(
    32
  )
  dma_addr_reg_cross
  (
    wb_rst,
    wb_clk_i,
    dma_addr_reg_wb_clk,
    sd_clk_o,
    dma_addr_reg_sd_clk
  );


  bistable_domain_cross
  #(
    3
  )
  data_int_status_reg_cross
  (
    wb_rst,
    sd_clk_o,
    data_int_status_reg_sd_clk,
    wb_clk_i,
    data_int_status_reg_wb_clk
  );


  bistable_domain_cross
  #(
    3
  )
  data_int_enable_reg_cross
  (
    wb_rst,
    wb_clk_i,
    data_int_enable_reg_wb_clk,
    sd_clk_o,
    data_int_enable_reg_sd_clk
  );

  assign m_wb_cti_o = 3'b000;
  assign m_wb_bte_o = 2'b00;
  assign int_cmd = |(cmd_int_status_reg_wb_clk & cmd_int_enable_reg_wb_clk);
  assign int_data = |(data_int_status_reg_wb_clk & data_int_enable_reg_wb_clk);
  assign m_wb_sel_o = 4'b1111;

endmodule

