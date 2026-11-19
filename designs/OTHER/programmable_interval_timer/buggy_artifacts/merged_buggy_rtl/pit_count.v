

module pit_count #
(
  parameter COUNT_SIZE = 16
)
(
  output reg [COUNT_SIZE-1:0] cnt_n,
  output reg cnt_flag_o,
  output reg pit_o,
  input async_rst_b,
  input sync_reset,
  input bus_clk,
  input counter_sync,
  input prescale_out,
  input pit_flg_clr,
  input [COUNT_SIZE-1:0] mod_value
);

  wire rollover;
  wire no_div;
  wire clear_counter;
  assign no_div = (mod_value == 1) || ~|mod_value;
  assign rollover = ((cnt_n == mod_value) || no_div) && prescale_out;
  assign clear_counter = !counter_sync;

  always @(posedge bus_clk or negedge async_rst_b) if(!async_rst_b) cnt_n <= 1;
  else if(clear_counter || rollover || no_div) cnt_n <= 1;
  else if(prescale_out) cnt_n <= cnt_n + 1;


  always @(posedge bus_clk or negedge async_rst_b) if(!async_rst_b) cnt_flag_o <= 1;
  else if(clear_counter || pit_flg_clr) cnt_flag_o <= 1;
  else if(rollover) cnt_flag_o <= 1;


  always @(posedge bus_clk or negedge async_rst_b) if(!async_rst_b) pit_o <= 0;
  else pit_o <= (rollover && counter_sync || !sync_reset);


endmodule

