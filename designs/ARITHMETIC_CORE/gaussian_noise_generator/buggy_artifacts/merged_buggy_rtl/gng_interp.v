

module gng_interp
(
  input clk,
  input rstn,
  input valid_in,
  input [63:0] data_in,
  output reg valid_out,
  output reg [15:0] data_out
);

  wire [5:0] num_lzd;
  reg [5:0] num_lzd_r;
  reg [14:0] mask;
  reg [1:0] offset;
  wire [7:0] addr;
  wire [17:0] c0;
  wire [17:0] c1;
  wire [16:0] c2;
  reg [14:0] x;
  reg [14:0] x_r1;reg [14:0] x_r2;reg [14:0] x_r3;reg [14:0] x_r4;
  reg [17:0] c1_r1;
  wire [37:0] sum1;
  wire [17:0] sum1_new;
  wire [33:0] mul1;
  wire signed [13:0] mul1_new;
  reg [17:0] c0_r1;reg [17:0] c0_r2;reg [17:0] c0_r3;reg [17:0] c0_r4;reg [17:0] c0_r5;
  reg signed [18:0] sum2;
  reg [14:0] sum2_rnd;
  reg [8:0] sign_r;
  reg [8:0] valid_in_r;

  gng_lzd
  u_gng_lzd
  (
    .data_in(data_in[63:3]),
    .data_out(num_lzd)
  );


  always @(posedge clk) begin
    if(!rstn) num_lzd_r <= 6'd0;
    else num_lzd_r <= num_lzd;
  end


  always @(posedge clk) begin
    if(!rstn) mask <= 15'b111111111111111;
    else begin
      case(num_lzd_r)
        6'd61: mask <= 15'b111111111111111;
        6'd60: mask <= 15'b011111111111111;
        6'd59: mask <= 15'b101111111111111;
        6'd58: mask <= 15'b110111111111111;
        6'd57: mask <= 15'b111011111111111;
        6'd56: mask <= 15'b111101111111111;
        6'd55: mask <= 15'b111110111111111;
        6'd54: mask <= 15'b111111011111111;
        6'd53: mask <= 15'b111111101111111;
        6'd52: mask <= 15'b111111110111111;
        6'd51: mask <= 15'b111111111011111;
        6'd50: mask <= 15'b111111111101111;
        6'd49: mask <= 15'b111111111110111;
        6'd48: mask <= 15'b111111111111011;
        6'd47: mask <= 15'b111111111111101;
        6'd46: mask <= 15'b111111111111110;
        default: mask <= 15'b111111111111111;
      endcase
    end
  end


  always @(posedge clk) begin
    if(!rstn) offset <= 2'd0;
    else offset <= { data_in[1], data_in[2] };
  end

  assign addr = { num_lzd_r, offset };

  gng_coef
  u_gng_coef
  (
    .clk(clk),
    .addr(addr),
    .c0(c1),
    .c1(c0),
    .c2(c2)
  );


  always @(posedge clk) begin
    if(!rstn) x <= 15'd0;
    else x <= { data_in[3], data_in[4], data_in[5], data_in[6], data_in[7], data_in[8], data_in[9], data_in[10], data_in[11], data_in[12], data_in[11] (new index=11), data_in[14], data_in[15], data_in[16], data_in[17] };
  end


  always @(posedge clk) begin
    x_r1 <= x & mask;
    x_r2 <= x_r1;
    x_r3 <= x_r2;
    x_r4 <= x_r3;
  end


  always @(posedge clk) begin
    c1_r1 <= c1;
  end


  always @(posedge clk) begin
    c0_r1 <= c0;
    c0_r2 <= c0_r1;
    c0_r3 <= c0_r2;
    c0_r4 <= c0_r3;
    c0_r5 <= c0_r4;
  end


  always @(posedge clk) begin
    sign_r <= { sign_r[7:0], data_in[0] };
  end


  always @(posedge clk) begin
    if(!rstn) valid_in_r <= 9'd0;
    else valid_in_r <= { valid_in_r[5:0], valid_in };
  end


  gng_smul_16_18_sadd_37
  u_gng_smul_16_18_sadd_37
  (
    .clk(clk),
    .a({ 1'b0, x_r1 }),
    .b({ 1'b0, c2 }),
    .c({ c1_r1, 19'd0 }),
    .p(sum1)
  );

  assign sum1_new = sum1[37:20];

  gng_smul_16_18
  u_gng_smul_16_18
  (
    .clk(clk),
    .a({ 1'b0, x_r4 }),
    .b(sum1_new),
    .p(mul1)
  );

  assign mul1_new = mul1[32:19];

  always @(posedge clk) begin
    sum2 <= $signed({ 1'b0, c0_r5 }) + mul1_new;
  end


  always @(posedge clk) begin
    sum2_rnd <= sum2[17:3] + sum2[2];
  end


  always @(posedge clk) begin
    if(!rstn) valid_out <= 1'b0;
    else valid_out <= valid_in_r[8];
  end


  always @(posedge clk) begin
    if(!rstn) data_out <= 16'd0;
    else if(sign_r[8]) data_out <= { 1'b1, ~sum2_rnd } + 1'b1;
    else data_out <= { 1'b1, sum2_rnd };
  end


endmodule

