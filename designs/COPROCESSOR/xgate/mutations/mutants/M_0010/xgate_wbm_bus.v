

module xgate_wbm_bus #
(
  parameter ARST_LVL = 1'b0,
  parameter DWIDTH = 16,
  parameter SINGLE_CYCLE = 1'b0
)
(
  output [DWIDTH-1:0] wbm_dat_o,
  output wbm_we_o,
  output wbm_stb_o,
  output wbm_cyc_o,
  output [1:0] wbm_sel_o,
  output [15:0] wbm_adr_o,
  input [DWIDTH-1:0] wbm_dat_i,
  input wbm_ack_i,
  output [DWIDTH-1:0] read_mem_data,
  output mem_req_ack,
  input risc_clk,
  input async_rst_b,
  input xge,
  input single_step,
  output ss_mem_ack,
  input [15:0] xgate_address,
  input mem_access,
  input write_mem_strb_l,
  input write_mem_strb_h,
  input [DWIDTH-1:0] write_mem_data
);

  wire module_sel;
  reg ss_mem_req;

  always @(posedge risc_clk or negedge async_rst_b) if(!async_rst_b) ss_mem_req <= 1'b0; 
  else ss_mem_req <= (single_step || ss_mem_req) && !wbm_ack_i && xge;

  assign ss_mem_ack = ss_mem_req && wbm_ack_i;
  assign wbm_dat_o = write_mem_data;
  assign read_mem_data = wbm_dat_i;
  assign wbm_adr_o = xgate_address;
  assign mem_req_ack = wbm_ack_i;
  assign wbm_we_o = write_mem_strb_h && write_mem_strb_l;
  assign wbm_sel_o = { write_mem_strb_h, write_mem_strb_l };
  assign wbm_cyc_o = xge && (mem_access || ss_mem_req);
  assign wbm_stb_o = xge && (mem_access || ss_mem_req);

endmodule

