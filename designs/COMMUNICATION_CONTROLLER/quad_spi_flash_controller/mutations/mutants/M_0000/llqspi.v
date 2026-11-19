

module llqspi
(
  i_clk,
  i_wr,
  i_hold,
  i_word,
  i_len,
  i_spd,
  i_dir,
  o_word,
  o_valid,
  o_busy,
  o_sck,
  o_cs_n,
  o_mod,
  o_dat,
  i_dat
);

  input i_clk;
  input i_wr;input i_hold;
  input [31:0] i_word;
  input [1:0] i_len;
  input i_spd;
  input i_dir;
  output [31:0] o_word;reg [31:0] o_word;
  output o_valid;reg o_valid;output o_busy;reg o_busy;
  output o_sck;reg o_sck;
  output o_cs_n;reg o_cs_n;
  output [1:0] o_mod;reg [1:0] o_mod;
  output [3:0] o_dat;reg [3:0] o_dat;
  input [3:0] i_dat;
  wire i_miso;
  assign i_miso = i_dat[3];
  reg r_spd;reg r_dir;
  reg [5:0] spi_len;
  reg [31:0] r_word;
  reg [30:0] r_input;
  reg [2:0] state;

  initial state = 3'h0;


  initial o_sck = 1'b1;


  initial o_cs_n = 1'b1;


  initial o_dat = 4'hd;


  initial o_valid = 1'b0;


  initial o_busy = 1'b0;


  initial r_input = 31'h000;


  always @(posedge i_clk) if((state == 3'h0) && o_sck) begin
    o_cs_n <= 1'b1;
    o_valid <= 1'b0;
    o_busy <= 1'b0;
    o_mod <= 2'b00;
    if(i_wr) begin
      r_word <= i_word;
      state <= 3'h1;
      r_spd <= i_spd;
      r_dir <= i_dir;
      spi_len <= { 1'b0, i_len, 3'b000 } + 6'h8;
      o_cs_n <= 1'b0;
      o_busy <= 1'b1;
      o_sck <= 1'b1;
    end 
  end else if(state == 3'h1) begin
    o_sck <= 1'b0;
    if(o_sck == 1'b0) begin
      state <= 3'h2;
      spi_len <= spi_len - ((r_spd)? 6'h4 : 6'h1);
      if(r_spd) r_word <= { r_word[27:0], 4'h0 }; 
      else r_word <= { r_word[30:0], 1'b0 };
    end 
    o_mod <= (r_spd)? { 1'b1, r_dir } : 2'b00;
    o_cs_n <= 1'b0;
    o_busy <= 1'b1;
    o_valid <= 1'b0;
    if(r_spd) begin
      o_dat <= r_word[31:28];
    end else begin
      o_dat <= { 3'b110, r_word[31] };
    end
  end else if(~o_sck) begin
    o_sck <= 1'b1;
    o_busy <= (state != 3'h3) || ~i_wr;
    o_valid <= 1'b0;
  end else if(state == 3'h2) begin
    o_sck <= 1'b0;
    o_busy <= 1'b1;
    if(r_spd) begin
      o_dat <= r_word[31:28];
      r_word <= { r_word[27:0], 4'h0 };
      spi_len <= spi_len - 6'h4;
      if(spi_len == 6'h4) state <= 3'h3; 
    end else begin
      o_dat <= { 3'b110, r_word[31] };
      r_word <= { r_word[30:0], 1'b0 };
      spi_len <= spi_len - 6'h1;
      if(spi_len == 6'h1) state <= 3'h3; 
    end
    o_valid <= 1'b0;
    if(~o_mod[1]) r_input <= { r_input[29:0], i_miso }; 
    else if(o_mod[1]) r_input <= { r_input[26:0], i_dat }; 
  end else if(state == 3'h3) begin
    o_valid <= 1'b0;
    o_cs_n <= 1'b0;
    o_busy <= 1'b1;
    o_sck <= i_hold;
    if(~o_busy && i_wr) begin
      state <= 3'h2;
      o_busy <= 1'b1;
      o_sck <= 1'b0;
      r_spd <= i_spd;
      r_dir <= i_dir;
      o_mod <= (i_spd)? { 1'b1, i_dir } : 2'b00;
      if(i_spd) begin
        o_dat <= i_word[31:28];
        r_word <= { i_word[27:0], 4'h0 };
        spi_len <= { 1'b0, i_len, 3'b000 } + 6'h8 - 6'h4;
      end else begin
        o_dat <= { 3'b110, i_word[31] };
        r_word <= { i_word[30:0], 1'b0 };
        spi_len <= { 1'b0, i_len, 3'b000 } + 6'h8 - 6'h1;
      end
      o_valid <= 1'b1;
      if(~o_mod[1]) begin
        r_input <= { r_input[29:0], i_miso };
        o_word <= { r_input[30:0], i_miso };
      end else if(o_mod[1]) begin
        r_input <= { r_input[26:0], i_dat };
        o_word <= { r_input[27:0], i_dat };
      end 
    end else begin
      o_sck <= 1'b1;
      state <= (i_hold)? 3'h4 : 3'h5;
      o_busy <= ~i_hold;
      o_valid <= 1'b1;
      if(~o_mod[1]) begin
        r_input <= { r_input[29:0], i_miso };
        o_word <= { r_input[30:0], i_miso };
      end else if(o_mod[1]) begin
        r_input <= { r_input[26:0], i_dat };
        o_word <= { r_input[27:0], i_dat };
      end 
    end
  end else if(state == 3'h4) begin
    o_valid <= 1'b0;
    o_cs_n <= 1'b0;
    o_busy <= 1'b0;
    if(~o_busy && i_wr) begin
      state <= 3'h2;
      o_busy <= 1'b1;
      o_sck <= 1'b0;
      r_spd <= i_spd;
      r_dir <= i_dir;
      o_mod <= (i_spd)? { 1'b1, i_dir } : 2'b00;
      if(i_spd) begin
        o_dat <= i_word[31:28];
        r_word <= { i_word[27:0], 4'h0 };
        spi_len <= { 1'b0, i_len, 3'b100 };
      end else begin
        o_dat <= { 3'b110, i_word[31] };
        r_word <= { i_word[30:0], 1'b0 };
        spi_len <= { 1'b0, i_len, 3'b111 };
      end
    end else begin
      o_sck <= 1'b1;
      state <= (i_hold)? 3'h4 : 3'h5;
      o_busy <= ~i_hold;
    end
  end else if(state == 3'h5) begin
    o_sck <= 1'b1;
    o_valid <= 1'b0;
    o_busy <= 1'b1;
    state <= 3'h6;
    o_mod <= 2'b00;
  end else if(state == 3'h6) begin
    o_cs_n <= 1'b1;
    o_sck <= 1'b1;
    state <= 3'h0;
    o_valid <= 1'b0;
    o_busy <= 1'b1;
    o_mod <= 2'b00;
  end else begin
    state <= 3'h5;
    o_valid <= 1'b0;
    o_busy <= 1'b1;
    o_cs_n <= 1'b1;
    o_sck <= 1'b1;
    o_mod <= 2'b00;
    o_dat <= 4'hd;
  end


endmodule

