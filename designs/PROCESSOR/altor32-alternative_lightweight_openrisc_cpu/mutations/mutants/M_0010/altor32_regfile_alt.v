

module altor32_regfile_alt
(
  input clk_i,
  input rst_i,
  input wr_i,
  input [4:0] ra_i,
  input [4:0] rb_i,
  input [4:0] rd_i,
  output reg [31:0] reg_ra_o,
  output reg [31:0] reg_rb_o,
  input [31:0] reg_rd_i
);

  parameter SUPPORT_32REGS = "ENABLED";
  wire clk_delayed_w;
  wire [31:0] reg_ra_w;
  wire [31:0] reg_rb_w;
  wire write_enable_w;
  reg [4:0] addr_q;
  reg [31:0] data_q;
  wire [31:0] ra_w;
  wire [31:0] rb_w;

  always @(posedge clk_i or posedge rst_i) begin
    if(rst_i) begin
      addr_q <= 5'b00000;
      data_q <= 32'h00000000;
    end else begin
      addr_q <= rd_i;
      data_q <= reg_rd_i;
    end
  end


  lpm_ram_dp
  #(
    .lpm_width(32),
    .lpm_widthad(5),
    .lpm_indata("REGISTERED"),
    .lpm_outdata("UNREGISTERED"),
    .lpm_rdaddress_control("REGISTERED"),
    .lpm_wraddress_control("REGISTERED"),
    .lpm_file("UNUSED"),
    .lpm_type("lpm_ram_dp"),
    .lpm_hint("UNUSED")
  )
  lpm1
  (
    .rdclock(clk_delayed_w),
    .rdclken(1'b1),
    .rdaddress(ra_i),
    .rden(1'b1),
    .data(reg_rd_i),
    .wraddress(rd_i),
    .wren(write_enable_w),
    .wrclock(clk_i),
    .wrclken(1'b1),
    .q(ra_w)
  );


  lpm_ram_dp
  #(
    .lpm_width(32),
    .lpm_widthad(5),
    .lpm_indata("REGISTERED"),
    .lpm_outdata("UNREGISTERED"),
    .lpm_rdaddress_control("REGISTERED"),
    .lpm_wraddress_control("REGISTERED"),
    .lpm_file("UNUSED"),
    .lpm_type("lpm_ram_dp"),
    .lpm_hint("UNUSED")
  )
  lpm2
  (
    .rdclock(clk_delayed_w),
    .rdclken(1'b1),
    .rdaddress(rb_i),
    .rden(1'b1),
    .data(reg_rd_i),
    .wraddress(rd_i),
    .wren(write_enable_w),
    .wrclock(clk_i),
    .wrclken(1'b1),
    .q(rb_w)
  );

  assign clk_delayed_w = !clk_i;

  always @(*) begin
    if(ra_i == 5'b00000) reg_ra_o = 32'h00000000; 
    else reg_ra_o = reg_ra_w;
    if(rb_i == 5'b00000) reg_rb_o = 32'h00000000; 
    else reg_rb_o = reg_rb_w;
  end

  assign write_enable_w = (rd_i != 5'b00000) & wr_i;
  assign reg_ra_w = ra_w;
  assign reg_rb_w = (rb_i != addr_q)? rb_w : data_q;

endmodule

