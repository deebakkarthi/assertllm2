

module uart2bus_top
(
  clock,
  reset,
  ser_in,
  ser_out,
  int_address,
  int_wr_data,
  int_write,
  int_rd_data,
  int_read,
  int_req,
  int_gnt
);

  input clock;
  input reset;
  input ser_in;
  output ser_out;
  output [15:0] int_address;
  output [7:0] int_wr_data;
  output int_write;
  output int_read;
  input [7:0] int_rd_data;
  output int_req;
  input int_gnt;
  wire [7:0] tx_data;
  wire new_tx_data;
  wire tx_busy;
  wire [7:0] rx_data;
  wire new_rx_data;
  wire [11:0] baud_freq;
  wire [15:0] baud_limit;
  wire baud_clk;

  uart_top
  uart1
  (
    .clock(clock),
    .reset(reset),
    .ser_in(ser_in),
    .ser_out(ser_out),
    .rx_data(tx_data),
    .new_rx_data(new_rx_data),
    .tx_data(rx_data),
    .new_tx_data(new_tx_data),
    .tx_busy(tx_busy),
    .baud_freq(baud_freq),
    .baud_limit(baud_limit),
    .baud_clk(baud_clk)
  );

  assign baud_freq = 12'h90;
  assign baud_limit = 16'h0ba5;

  uart_parser
  #(
    16
  )
  uart_parser1
  (
    .clock(clock),
    .reset(reset),
    .rx_data(rx_data),
    .new_rx_data(new_rx_data),
    .tx_data(tx_data),
    .new_tx_data(new_tx_data),
    .tx_busy(tx_busy),
    .int_address(int_address),
    .int_wr_data(int_wr_data),
    .int_write(int_write),
    .int_rd_data(int_rd_data),
    .int_read(int_read),
    .int_req(int_req),
    .int_gnt(int_gnt)
  );


endmodule

