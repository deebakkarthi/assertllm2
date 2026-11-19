

module llsdspi
(
  i_clk,
  i_speed,
  i_cs,
  i_stb,
  i_byte,
  o_cs_n,
  o_sclk,
  o_mosi,
  i_miso,
  o_stb,
  o_byte,
  o_idle,
  i_bus_grant
);

  parameter SPDBITS = 7;
  input i_clk;wire i_clk;
  input [SPDBITS-1:0] i_speed;wire [SPDBITS-1:0] i_speed;
  input i_cs;wire i_cs;
  input i_stb;wire i_stb;
  input [7:0] i_byte;wire [7:0] i_byte;
  output o_cs_n;reg o_cs_n;output o_sclk;reg o_sclk;output o_mosi;reg o_mosi;
  input i_miso;wire i_miso;
  output o_stb;reg o_stb;
  output [7:0] o_byte;reg [7:0] o_byte;
  output o_idle;wire o_idle;
  input i_bus_grant;wire i_bus_grant;
  reg r_z_counter;
  reg [SPDBITS-1:0] r_clk_counter;
  reg r_idle;
  reg [3:0] r_state;
  reg [7:0] r_byte;reg [7:0] r_ireg;
  wire byte_accepted;
  assign byte_accepted = i_stb && o_idle;

  initial r_clk_counter = 7'h0;


  always @(posedge i_clk) begin
    if(!i_cs || !i_bus_grant) r_clk_counter <= 0; 
    else if(byte_accepted) r_clk_counter <= i_speed; 
    else if(!r_z_counter) r_clk_counter <= r_clk_counter - { { SPDBITS - 1{ 1'b0 } }, 1'b1 }; 
    else if((r_state != 4'h0) && (r_state != 4'h1)) r_clk_counter <= i_speed; 
  end


  initial r_z_counter = 1'b1;


  always @(posedge i_clk) begin
    if(!i_cs || !i_bus_grant) r_z_counter <= 1'b1; 
    else if(byte_accepted) r_z_counter <= 1'b0; 
    else if(!r_z_counter) r_z_counter <= r_clk_counter == 1; 
    else if((r_state != 4'h0) && (r_state != 4'h1)) r_z_counter <= 1'b0; 
  end


  initial r_state = 4'h0;


  always @(posedge i_clk) begin
    o_stb <= 1'b0;
    o_cs_n <= !i_cs;
    if(!i_cs) begin
      r_state <= 4'h0;
      r_idle <= 1'b0;
      o_sclk <= 1'b1;
    end else if(!r_z_counter) begin
      r_idle <= 1'b0;
      if(byte_accepted) begin
        r_byte <= { i_byte[6:0], 1'b1 };
        r_state <= 4'h3 + 1;
        o_mosi <= i_byte[7];
      end 
    end else if(r_state == 4'h0) begin
      o_sclk <= 1'b1;
      if(byte_accepted) begin
        r_byte <= i_byte[7:0];
        r_state <= (i_bus_grant)? 4'h3 : 4'h2;
        r_idle <= 1'b1;
        o_mosi <= i_byte[7];
      end else begin
        r_idle <= 1'b1;
      end
    end else if(r_state == 4'h2) begin
      r_idle <= 1'b0;
      if(i_bus_grant) r_state <= 4'h3; 
    end else if(r_state == 4'h1) begin
      o_sclk <= 1'b0;
      if(byte_accepted) begin
        r_byte <= i_byte[7:0];
        r_state <= 4'h3;
        r_idle <= 1'b0;
        o_mosi <= i_byte[7];
      end else r_idle <= 1'b1;
    end else if(o_sclk) begin
      o_mosi <= r_byte[7];
      r_byte <= { r_byte[6:0], 1'b1 };
      r_state <= r_state + 1;
      o_sclk <= 1'b0;
      if(r_state >= 4'h3 + 8) begin
        r_state <= 4'h1;
        r_idle <= 1'b1;
        o_stb <= 1'b1;
        o_byte <= r_ireg;
      end else r_state <= r_state + 1;
    end else begin
      r_ireg <= { r_ireg[6:0], i_miso };
      o_sclk <= 1'b1;
    end
  end

  assign o_idle = r_idle && (i_cs && i_bus_grant);

endmodule

