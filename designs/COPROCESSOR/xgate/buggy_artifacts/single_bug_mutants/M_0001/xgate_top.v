

module xgate_top #
(
  parameter ARST_LVL = 1'b0,
  parameter DWIDTH = 16,
  parameter SINGLE_CYCLE = 1'b0,
  parameter MAX_CHANNEL = 127,
  parameter WB_RD_DEFAULT = 0
)
(
  output [DWIDTH-1:0] wbs_dat_o,
  output wbs_ack_o,
  output wbs_err_o,
  input wbs_clk_i,
  input wbs_rst_i,
  input arst_i,
  input [6:1] wbs_adr_i,
  input [DWIDTH-1:0] wbs_dat_i,
  input wbs_we_i,
  input wbs_stb_i,
  input wbs_cyc_i,
  input [1:0] wbs_sel_i,
  output [DWIDTH-1:0] wbm_dat_o,
  output wbm_we_o,
  output wbm_stb_o,
  output wbm_cyc_o,
  output [1:0] wbm_sel_o,
  output [15:0] wbm_adr_o,
  input [DWIDTH-1:0] wbm_dat_i,
  input wbm_ack_i,
  output [7:0] xgswt,
  output xg_sw_irq,
  output [MAX_CHANNEL:1] xgif,
  input [MAX_CHANNEL:1] chan_req_i,
  input risc_clk,
  input debug_mode_i,
  input secure_mode_i,
  input scantestmode
);

  wire zero_flag;
  wire negative_flag;
  wire carry_flag;
  wire overflow_flag;
  wire [15:0] xgr1;
  wire [15:0] xgr2;
  wire [15:0] xgr3;
  wire [15:0] xgr4;
  wire [15:0] xgr5;
  wire [15:0] xgr6;
  wire [15:0] xgr7;
  wire write_xgmctl;
  wire write_xgchid;
  wire [1:0] write_xgvbr;
  wire [1:0] write_xgif_7;
  wire [1:0] write_xgif_6;
  wire [1:0] write_xgif_5;
  wire [1:0] write_xgif_4;
  wire [1:0] write_xgif_3;
  wire [1:0] write_xgif_2;
  wire [1:0] write_xgif_1;
  wire [1:0] write_xgif_0;
  wire [1:0] write_irw_en_7;
  wire [1:0] write_irw_en_6;
  wire [1:0] write_irw_en_5;
  wire [1:0] write_irw_en_4;
  wire [1:0] write_irw_en_3;
  wire [1:0] write_irw_en_2;
  wire [1:0] write_irw_en_1;
  wire [1:0] write_irw_en_0;
  wire write_xgswt;
  wire write_xgsem;
  wire write_xgccr;
  wire [1:0] write_xgpc;
  wire [1:0] write_xgr7;
  wire [1:0] write_xgr6;
  wire [1:0] write_xgr5;
  wire [1:0] write_xgr4;
  wire [1:0] write_xgr3;
  wire [1:0] write_xgr2;
  wire [1:0] write_xgr1;
  wire clear_xgif_7;
  wire clear_xgif_6;
  wire clear_xgif_5;
  wire clear_xgif_4;
  wire clear_xgif_3;
  wire clear_xgif_2;
  wire clear_xgif_1;
  wire clear_xgif_0;
  wire [15:0] clear_xgif_data;
  wire [MAX_CHANNEL:1] chan_bypass;
  wire xge;
  wire xgfrz;
  wire xgdbg_set;
  wire xgdbg_clear;
  wire xgfact;
  wire xgss;
  wire xgsweif_c;
  wire xgie;
  wire [6:0] int_req;
  wire [6:0] xgchid;
  wire [127:1] xgif_status;
  wire [127:1] irq_bypass;
  wire [15:1] xgvbr;
  wire brk_irq_ena;
  wire [15:0] xgate_address;
  wire [15:0] write_mem_data;
  wire [15:0] read_mem_data;
  wire mem_access;
  wire mem_req_ack;
  wire debug_active;
  wire debug_ack;
  wire single_step;
  wire ss_mem_ack;
  wire [7:0] host_semap;
  wire write_mem_strb_l;
  wire write_mem_strb_h;
  wire sync_reset;
  wire async_rst_b;

  xgate_wbs_bus
  #(
    .ARST_LVL(ARST_LVL),
    .SINGLE_CYCLE(SINGLE_CYCLE),
    .WB_RD_DEFAULT(WB_RD_DEFAULT)
  )
  wishbone_s
  (
    .wbs_dat_o(wbs_dat_o),
    .wbs_ack_o(wbs_ack_o),
    .wbs_err_o(wbs_err_o),
    .wbs_clk_i(wbs_clk_i),
    .wbs_rst_i(wbs_rst_i),
    .arst_i(arst_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_we_i(wbs_we_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_sel_i(wbs_sel_i),
    .sync_reset(sync_reset),
    .write_xgmctl(write_xgmctl),
    .write_xgchid(write_xgchid),
    .write_xgvbr(write_xgvbr),
    .write_xgif_7(write_xgif_7),
    .write_xgif_6(write_xgif_6),
    .write_xgif_5(write_xgif_5),
    .write_xgif_4(write_xgif_4),
    .write_xgif_3(write_xgif_3),
    .write_xgif_2(write_xgif_2),
    .write_xgif_1(write_xgif_1),
    .write_xgif_0(write_xgif_0),
    .write_xgswt(write_xgswt),
    .write_xgsem(write_xgsem),
    .write_xgccr(write_xgccr),
    .write_xgpc(write_xgpc),
    .write_xgr7(write_xgr7),
    .write_xgr6(write_xgr6),
    .write_xgr5(write_xgr5),
    .write_xgr4(write_xgr4),
    .write_xgr3(write_xgr3),
    .write_xgr2(write_xgr2),
    .write_xgr1(write_xgr1),
    .write_irw_en_7(write_irw_en_7),
    .write_irw_en_6(write_irw_en_6),
    .write_irw_en_5(write_irw_en_5),
    .write_irw_en_4(write_irw_en_4),
    .write_irw_en_3(write_irw_en_3),
    .write_irw_en_2(write_irw_en_2),
    .write_irw_en_1(write_irw_en_1),
    .write_irw_en_0(write_irw_en_0),
    .async_rst_b(async_rst_b),
    .read_risc_regs({ xgr7, xgr6, xgr5, xgr4, xgr3, xgr2, xgr1, 16'b0, xgate_address, { 12'h000, negative_flag, zero_flag, overflow_flag, carry_flag }, 16'b0, { 8'h00, host_semap }, { 8'h00, xgswt }, { xgif_status[14:1], 1'b0 }, xgif_status[31:16], xgif_status[47:32], xgif_status[63:48], xgif_status[79:64], xgif_status[95:80], xgif_status[111:96], xgif_status[127:112], { xgvbr[15:1], 1'b0 }, 16'b0, 16'b0, { 8'b0, 1'b0, xgchid }, { 8'b0, xge, xgfrz, debug_active, 1'b0, xgfact, brk_irq_ena, xg_sw_irq, xgie } }),
    .irq_bypass(irq_bypass)
  );


  xgate_regs
  #(
    .ARST_LVL(ARST_LVL),
    .MAX_CHANNEL(MAX_CHANNEL)
  )
  regs
  (
    .xge(xge),
    .xgfrz(xgfrz),
    .xgdbg_set(xgdbg_set),
    .xgdbg_clear(xgdbg_clear),
    .xgfact(xgfact),
    .xgss(xgss),
    .xgsweif_c(xgsweif_c),
    .xgie(xgie),
    .brk_irq_ena(brk_irq_ena),
    .xgvbr(xgvbr),
    .xgswt(xgswt),
    .clear_xgif_7(clear_xgif_7),
    .clear_xgif_6(clear_xgif_6),
    .clear_xgif_5(clear_xgif_5),
    .clear_xgif_4(clear_xgif_4),
    .clear_xgif_3(clear_xgif_3),
    .clear_xgif_2(clear_xgif_2),
    .clear_xgif_1(clear_xgif_1),
    .clear_xgif_0(clear_xgif_0),
    .clear_xgif_data(clear_xgif_data),
    .irq_bypass(irq_bypass),
    .chan_bypass(chan_bypass),
    .async_rst_b(async_rst_b),
    .sync_reset(sync_reset),
    .bus_clk(wbs_clk_i),
    .write_bus(wbs_dat_i),
    .write_xgmctl(write_xgmctl),
    .write_xgvbr(write_xgvbr),
    .write_xgif_7(write_xgif_7),
    .write_xgif_6(write_xgif_6),
    .write_xgif_5(write_xgif_5),
    .write_xgif_4(write_xgif_4),
    .write_xgif_3(write_xgif_3),
    .write_xgif_2(write_xgif_2),
    .write_xgif_1(write_xgif_1),
    .write_xgif_0(write_xgif_0),
    .write_irw_en_7(write_irw_en_7),
    .write_irw_en_6(write_irw_en_6),
    .write_irw_en_5(write_irw_en_5),
    .write_irw_en_4(write_irw_en_4),
    .write_irw_en_3(write_irw_en_3),
    .write_irw_en_2(write_irw_en_2),
    .write_irw_en_1(write_irw_en_1),
    .write_irw_en_0(write_irw_en_0),
    .write_xgswt(write_xgswt),
    .debug_ack(debug_ack)
  );


  xgate_risc
  #(
    .MAX_CHANNEL(MAX_CHANNEL)
  )
  risc
  (
    .xgate_address(xgate_address),
    .write_mem_strb_l(write_mem_strb_l),
    .write_mem_strb_h(write_mem_strb_h),
    .write_mem_data(write_mem_data),
    .zero_flag(zero_flag),
    .negative_flag(negative_flag),
    .carry_flag(carry_flag),
    .overflow_flag(overflow_flag),
    .xgchid(xgchid),
    .host_semap(host_semap),
    .xgr1(xgr1),
    .xgr2(xgr2),
    .xgr3(xgr3),
    .xgr4(xgr4),
    .xgr5(xgr5),
    .xgr6(xgr6),
    .xgr7(xgr7),
    .xgif_status(xgif_status),
    .debug_active(debug_active),
    .debug_ack(debug_ack),
    .xg_sw_irq(xg_sw_irq),
    .mem_access(mem_access),
    .single_step(single_step),
    .risc_clk(risc_clk),
    .perif_data(wbs_dat_i),
    .async_rst_b(async_rst_b),
    .read_mem_data(read_mem_data),
    .mem_req_ack(mem_req_ack),
    .ss_mem_ack(ss_mem_ack),
    .xge(xge),
    .xgdbg_set(xgdbg_set),
    .xgdbg_clear(xgdbg_clear),
    .debug_mode_i(debug_mode_i),
    .xgss(xgss),
    .xgvbr(xgvbr),
    .int_req(int_req),
    .xgie(xgie),
    .brk_irq_ena(brk_irq_ena),
    .write_xgsem(write_xgsem),
    .write_xgchid(write_xgchid),
    .write_xgccr(write_xgccr),
    .write_xgpc(write_xgpc),
    .write_xgr7(write_xgr7),
    .write_xgr6(write_xgr6),
    .write_xgr5(write_xgr5),
    .write_xgr4(write_xgr4),
    .write_xgr3(write_xgr3),
    .write_xgr2(write_xgr2),
    .write_xgr1(write_xgr1),
    .clear_xgif_7(clear_xgif_7),
    .clear_xgif_6(clear_xgif_6),
    .clear_xgif_5(clear_xgif_5),
    .clear_xgif_4(clear_xgif_4),
    .clear_xgif_3(clear_xgif_3),
    .clear_xgif_2(clear_xgif_2),
    .clear_xgif_1(clear_xgif_1),
    .clear_xgif_0(clear_xgif_0),
    .xgsweif_c(xgsweif_c),
    .clear_xgif_data(clear_xgif_data)
  );


  xgate_irq_encode
  #(
    .MAX_CHANNEL(MAX_CHANNEL)
  )
  irq_encode
  (
    .xgif(xgif),
    .int_req(int_req),
    .chan_req_i(chan_req_i),
    .chan_bypass(chan_bypass),
    .xgif_status(xgif_status)
  );


  xgate_wbm_bus
  #(
    .ARST_LVL(ARST_LVL)
  )
  wishbone_m
  (
    .wbm_dat_o(wbm_dat_o),
    .wbm_we_o(wbm_we_o),
    .wbm_stb_o(wbm_stb_o),
    .wbm_cyc_o(wbm_cyc_o),
    .wbm_sel_o(wbm_sel_o),
    .wbm_adr_o(wbm_adr_o),
    .wbm_dat_i(wbm_dat_i),
    .wbm_ack_i(wbm_ack_i),
    .risc_clk(risc_clk),
    .async_rst_b(async_rst_b),
    .xge(xge),
    .mem_access(mem_access),
    .single_step(single_step),
    .ss_mem_ack(ss_mem_ack),
    .read_mem_data(read_mem_data),
    .xgate_address(xgate_address),
    .mem_req_ack(mem_req_ack),
    .write_mem_strb_l(write_mem_strb_l),
    .write_mem_strb_h(write_mem_strb_h),
    .write_mem_data(write_mem_data)
  );


endmodule

