

module uart_parser
(
  clock,
  reset,
  rx_data,
  new_rx_data,
  tx_data,
  new_tx_data,
  tx_busy,
  int_address,
  int_wr_data,
  int_write,
  int_rd_data,
  int_read,
  int_req,
  int_gnt
);

  parameter AW = 8;
  input clock;
  input reset;
  output [7:0] tx_data;
  output new_tx_data;
  input tx_busy;
  input [7:0] rx_data;
  input new_rx_data;
  output [AW-1:0] int_address;
  output [7:0] int_wr_data;
  output int_write;
  output int_read;
  input [7:0] int_rd_data;
  output int_req;
  input int_gnt;
  reg [7:0] tx_data;
  reg new_tx_data;
  reg [AW-1:0] int_address;
  reg [7:0] int_wr_data;
  reg write_req;reg read_req;reg int_write;reg int_read;
  reg [3:0] main_sm;
  reg read_op;
  reg write_op;
  reg data_in_hex_range;
  reg [7:0] data_param;
  reg [15:0] addr_param;
  reg [3:0] data_nibble;
  reg read_done;
  reg read_done_s;
  reg [7:0] read_data_s;
  reg [3:0] tx_nibble;
  reg [7:0] tx_char;
  reg [2:0] tx_sm;
  reg s_tx_busy;
  reg bin_read_op;
  reg bin_write_op;
  reg addr_auto_inc;
  reg send_stat_flag;
  reg [7:0] bin_byte_count;
  wire bin_last_byte;
  wire tx_end_p;

  always @(posedge clock or posedge reset) begin
    if(reset) main_sm <= 4'b0000; 
    else if(new_rx_data) begin
      case(main_sm)
        4'b0000: if(rx_data == 8'h0) main_sm <= 4'b1000; 
        else if((rx_data == 8'h72) | (rx_data == 8'h52)) main_sm <= 4'b0011; 
        else if((rx_data == 8'h77) | (rx_data == 8'h57)) main_sm <= 4'b0001; 
        else if((rx_data == 8'h0d) | (rx_data == 8'h0a)) main_sm <= 4'b0000; 
        else main_sm <= 4'b0101;
        4'b0001: if((rx_data == 8'h20) | (rx_data == 8'h09)) main_sm <= 4'b0001; 
        else if(data_in_hex_range) main_sm <= 4'b0010; 
        else if((rx_data == 8'h0d) | (rx_data == 8'h0a)) main_sm <= 4'b0000; 
        else main_sm <= 4'b0101;
        4'b0010: if(data_in_hex_range) main_sm <= 4'b0010; 
        else if((rx_data == 8'h20) | (rx_data == 8'h09)) main_sm <= 4'b0011; 
        else if((rx_data == 8'h0d) | (rx_data == 8'h0a)) main_sm <= 4'b0000; 
        else main_sm <= 4'b0101;
        4'b0011: if((rx_data == 8'h20) | (rx_data == 8'h09)) main_sm <= 4'b0011; 
        else if(data_in_hex_range) main_sm <= 4'b0100; 
        else if((rx_data == 8'h0d) | (rx_data == 8'h0a)) main_sm <= 4'b0000; 
        else main_sm <= 4'b0101;
        4'b0100: if(data_in_hex_range) main_sm <= 4'b0100; 
        else if((rx_data == 8'h0d) | (rx_data == 8'h0a)) main_sm <= 4'b0000; 
        else main_sm <= 4'b0101;
        4'b0101: if((rx_data == 8'h0d) | (rx_data == 8'h0a)) main_sm <= 4'b0000; 
        4'b1000: if(rx_data[5:4] == 2'b00) main_sm <= 4'b0000; 
        else main_sm <= 4'b1001;
        4'b1001: main_sm <= 4'b1010;
        4'b1010: main_sm <= 4'b1011;
        4'b1011: if(bin_write_op) main_sm <= 4'b1100; 
        else main_sm <= 4'b0000;
        4'b1100: if(bin_last_byte) main_sm <= 4'b0000; 
        default: main_sm <= 4'b0000;
      endcase
    end 
  end


  always @(rx_data) begin
    if((rx_data >= 8'h30) && (rx_data <= 8'h39) || (rx_data >= 8'h41) && (rx_data <= 8'h46) || (rx_data >= 8'h61) && (rx_data <= 8'h66)) data_in_hex_range <= 1'b1; 
    else data_in_hex_range <= 1'b0;
  end


  always @(posedge clock or posedge reset) begin
    if(reset) read_op <= 1'b0; 
    else if((main_sm == 4'b0000) && new_rx_data) begin
      if((rx_data == 8'h72) | (rx_data == 8'h52)) read_op <= 1'b1; 
      else read_op <= 1'b0;
    end 
  end


  always @(posedge clock or posedge reset) begin
    if(reset) write_op <= 1'b0; 
    else if((main_sm == 4'b0000) & new_rx_data) begin
      if((rx_data == 8'h77) | (rx_data == 8'h57)) write_op <= 1'b1; 
      else write_op <= 1'b0;
    end 
  end


  always @(posedge clock or posedge reset) begin
    if(reset) bin_read_op <= 1'b0; 
    else if((main_sm == 4'b1000) && new_rx_data && (rx_data[5:4] == 2'b01)) bin_read_op <= 1'b1; 
    else if(bin_read_op && tx_end_p && bin_last_byte) bin_read_op <= 1'b0; 
  end


  always @(posedge clock or posedge reset) begin
    if(reset) bin_write_op <= 1'b0; 
    else if((main_sm == 4'b1000) && new_rx_data && (rx_data[5:4] == 2'b10)) bin_write_op <= 1'b1; 
    else if((main_sm == 4'b1100) && new_rx_data && bin_last_byte) bin_write_op <= 1'b0; 
  end


  always @(posedge clock or posedge reset) begin
    if(reset) send_stat_flag <= 1'b0; 
    else if((main_sm == 4'b1000) && new_rx_data) begin
      if(rx_data[0] == 1'b1) send_stat_flag <= 1'b1; 
      else send_stat_flag <= 1'b0;
    end 
  end


  always @(posedge clock or posedge reset) begin
    if(reset) addr_auto_inc <= 1'b0; 
    else if((main_sm == 4'b1000) && new_rx_data) begin
      if(rx_data[1] == 1'b0) addr_auto_inc <= 1'b1; 
      else addr_auto_inc <= 1'b0;
    end 
  end


  always @(posedge clock or posedge reset) begin
    if(reset) data_param <= 8'h0; 
    else if((main_sm == 4'b0001) & new_rx_data & data_in_hex_range) data_param <= { 4'h0, data_nibble }; 
    else if((main_sm == 4'b0010) & new_rx_data & data_in_hex_range) data_param <= { data_param[3:0], data_nibble }; 
  end


  always @(posedge clock or posedge reset) begin
    if(reset) addr_param <= 0; 
    else if((main_sm == 4'b0011) & new_rx_data & data_in_hex_range) addr_param <= { 12'b0, data_nibble }; 
    else if((main_sm == 4'b0100) & new_rx_data & data_in_hex_range) addr_param <= { addr_param[11:0], data_nibble }; 
    else if(main_sm == 4'b1001) addr_param[15:8] <= rx_data; 
    else if(main_sm == 4'b1010) addr_param[7:0] <= rx_data; 
  end


  always @(posedge clock or posedge reset) begin
    if(reset) bin_byte_count <= 8'b0; 
    else if((main_sm == 4'b1011) && new_rx_data) bin_byte_count <= rx_data; 
    else if(bin_write_op && (main_sm == 4'b1100) && new_rx_data || bin_read_op && tx_end_p) bin_byte_count <= bin_byte_count - 1; 
  end

  assign bin_last_byte = (bin_byte_count == 8'h01)? 1'b1 : 1'b0;

  always @(posedge clock or posedge reset) begin
    if(reset) begin
      write_req <= 1'b0;
      int_write <= 1'b0;
      int_wr_data <= 1;
    end else if(write_op && (main_sm == 4'b0100) && new_rx_data && !data_in_hex_range) begin
      write_req <= 1'b1;
      int_wr_data <= data_param;
    end else if(bin_write_op && (main_sm == 4'b1100) && new_rx_data) begin
      write_req <= 1'b1;
      int_wr_data <= rx_data;
    end else if(int_gnt && write_req) begin
      int_write <= 1'b1;
      write_req <= 1'b0;
    end else int_write <= 1'b0;
  end


  always @(posedge clock or posedge reset) begin
    if(reset) begin
      int_read <= 1'b0;
      read_req <= 1'b0;
    end else if(read_op && (main_sm == 4'b0100) && new_rx_data && !data_in_hex_range) read_req <= 1'b1; 
    else if(bin_read_op && (main_sm == 4'b1011) && new_rx_data) read_req <= 1'b1; 
    else if(bin_read_op && tx_end_p && !bin_last_byte) read_req <= 1'b1; 
    else if(int_gnt && read_req) begin
      int_read <= 1'b1;
      read_req <= 1'b0;
    end else int_read <= 1'b0;
  end

  assign int_req = write_req | read_req;

  always @(posedge clock or posedge reset) begin
    if(reset) int_address <= 0; 
    else if((main_sm == 4'b0100) && new_rx_data && !data_in_hex_range) int_address <= addr_param[AW-1:0]; 
    else if((main_sm == 4'b1011) && new_rx_data) int_address <= addr_param[AW-1:0]; 
    else if(addr_auto_inc && (bin_read_op && tx_end_p && !bin_last_byte || bin_write_op && int_write)) int_address <= int_address + 1; 
  end


  always @(posedge clock or posedge reset) begin
    if(reset) begin
      read_done <= 1'b0;
      read_done_s <= 1'b0;
      read_data_s <= 8'h0;
    end else begin
      if(int_read) read_done <= 1'b1; 
      else read_done <= 1'b0;
      read_done_s <= read_done;
      if(read_done) read_data_s <= int_rd_data; 
    end
  end


  always @(posedge clock or posedge reset) begin
    if(reset) begin
      tx_sm <= 3'b000;
      tx_data <= 8'h0;
      new_tx_data <= 1'b0;
    end else case(tx_sm)
      3'b000: if(read_done_s) if(bin_read_op) begin
        tx_data <= read_data_s;
        new_tx_data <= 1'b1;
      end else begin
        tx_sm <= 3'b001;
        tx_data <= tx_char;
        new_tx_data <= 1'b1;
      end else if(send_stat_flag && bin_read_op && tx_end_p && bin_last_byte || send_stat_flag && bin_write_op && new_rx_data && bin_last_byte || (main_sm == 4'b1000) && new_rx_data && (rx_data[5:4] == 2'b00)) begin
        tx_data <= 8'h5a;
        new_tx_data <= 1'b1;
      end else new_tx_data <= 1'b0;
      3'b001: if(tx_end_p) begin
        tx_sm <= 3'b100;
        tx_data <= tx_char;
        new_tx_data <= 1'b1;
      end else new_tx_data <= 1'b0;
      3'b100: if(tx_end_p) begin
        tx_sm <= 3'b101;
        tx_data <= 8'h0d;
        new_tx_data <= 1'b1;
      end else new_tx_data <= 1'b0;
      3'b101: if(tx_end_p) begin
        tx_sm <= 3'b110;
        tx_data <= 8'h0a;
        new_tx_data <= 1'b1;
      end else new_tx_data <= 1'b0;
      3'b110: begin
        if(tx_end_p) tx_sm <= 3'b000; 
        new_tx_data <= 1'b0;
      end
      default: tx_sm <= 3'b000;
    endcase
  end


  always @(tx_sm or read_data_s) begin
    case(tx_sm)
      3'b000: tx_nibble = read_data_s[7:4];
      3'b001: tx_nibble = read_data_s[3:0];
      default: tx_nibble = read_data_s[7:4];
    endcase
  end


  always @(posedge clock or posedge reset) begin
    if(reset) s_tx_busy <= 1'b0; 
    else s_tx_busy <= tx_busy;
  end

  assign tx_end_p = ~tx_busy & s_tx_busy;

  always @(rx_data) begin
    case(rx_data)
      8'h30: data_nibble = 4'h0;
      8'h31: data_nibble = 4'h1;
      8'h32: data_nibble = 4'h2;
      8'h33: data_nibble = 4'h3;
      8'h34: data_nibble = 4'h4;
      8'h35: data_nibble = 4'h5;
      8'h36: data_nibble = 4'h6;
      8'h37: data_nibble = 4'h7;
      8'h38: data_nibble = 4'h8;
      8'h39: data_nibble = 4'h9;
      8'h41, 8'h61: data_nibble = 4'ha;
      8'h42, 8'h62: data_nibble = 4'hb;
      8'h43, 8'h63: data_nibble = 4'hc;
      8'h44, 8'h64: data_nibble = 4'hd;
      8'h45, 8'h65: data_nibble = 4'he;
      8'h46, 8'h66: data_nibble = 4'hf;
      default: data_nibble = 4'hf;
    endcase
  end


  always @(tx_nibble) begin
    case(tx_nibble)
      4'h0: tx_char = 8'h30;
      4'h1: tx_char = 8'h31;
      4'h2: tx_char = 8'h32;
      4'h3: tx_char = 8'h33;
      4'h4: tx_char = 8'h34;
      4'h5: tx_char = 8'h35;
      4'h6: tx_char = 8'h36;
      4'h7: tx_char = 8'h37;
      4'h8: tx_char = 8'h38;
      4'h9: tx_char = 8'h39;
      4'ha: tx_char = 8'h41;
      4'hb: tx_char = 8'h42;
      4'hc: tx_char = 8'h43;
      4'hd: tx_char = 8'h44;
      4'he: tx_char = 8'h45;
      default: tx_char = 8'h46;
    endcase
  end


endmodule

