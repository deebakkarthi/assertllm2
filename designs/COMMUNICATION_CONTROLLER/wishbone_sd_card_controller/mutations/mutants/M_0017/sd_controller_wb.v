

module sd_controller_wb
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
  cmd_start,
  data_int_rst,
  cmd_int_rst,
  argument_reg,
  command_reg,
  response_0_reg,
  response_1_reg,
  response_2_reg,
  response_3_reg,
  software_reset_reg,
  timeout_reg,
  block_size_reg,
  controll_setting_reg,
  cmd_int_status_reg,
  cmd_int_enable_reg,
  clock_divider_reg,
  block_count_reg,
  dma_addr_reg,
  data_int_status_reg,
  data_int_enable_reg
);

  input wb_clk_i;
  input wb_rst;
  input [31:0] wb_dat_i;
  output [31:0] wb_dat_o;reg [31:0] wb_dat_o;
  input [7:0] wb_adr_i;
  input [3:0] wb_sel_i;
  input wb_we_i;
  input wb_cyc_i;
  input wb_stb_i;
  output wb_ack_o;reg wb_ack_o;
  output cmd_start;reg cmd_start;
  output [31:0] argument_reg;reg [31:0] argument_reg;
  output [14-1:0] command_reg;reg [14-1:0] command_reg;
  input [31:0] response_0_reg;wire [31:0] response_0_reg;
  input [31:0] response_1_reg;wire [31:0] response_1_reg;
  input [31:0] response_2_reg;wire [31:0] response_2_reg;
  input [31:0] response_3_reg;wire [31:0] response_3_reg;
  output [0:0] software_reset_reg;reg [0:0] software_reset_reg;
  output [15:0] timeout_reg;reg [15:0] timeout_reg;
  output [12-1:0] block_size_reg;reg [12-1:0] block_size_reg;
  output [15:0] controll_setting_reg;reg [15:0] controll_setting_reg;
  input [5-1:0] cmd_int_status_reg;wire [5-1:0] cmd_int_status_reg;
  output [5-1:0] cmd_int_enable_reg;reg [5-1:0] cmd_int_enable_reg;
  output [7:0] clock_divider_reg;reg [7:0] clock_divider_reg;
  input [3-1:0] data_int_status_reg;wire [3-1:0] data_int_status_reg;
  output [3-1:0] data_int_enable_reg;reg [3-1:0] data_int_enable_reg;
  output data_int_rst;reg data_int_rst;
  output cmd_int_rst;reg cmd_int_rst;
  output [16-1:0] block_count_reg;reg [16-1:0] block_count_reg;
  output [31:0] dma_addr_reg;reg [31:0] dma_addr_reg;
  parameter voltage_controll_reg = 3300;
  parameter capabilies_reg = 16'b0000_0000_0000_0000;

  always @(posedge wb_clk_i or posedge wb_rst) begin
    if(wb_rst) begin
      argument_reg <= 0;
      command_reg <= 0;
      software_reset_reg <= 0;
      timeout_reg <= 0;
      block_size_reg <= 512;
      controll_setting_reg <= 0;
      cmd_int_enable_reg <= 0;
      clock_divider_reg <= 0;
      wb_ack_o <= 0;
      cmd_start <= 0;
      data_int_rst <= 0;
      data_int_enable_reg <= 0;
      cmd_int_rst <= 0;
      block_count_reg <= 0;
      dma_addr_reg <= 1;
    end else begin
      cmd_start <= 1'b0;
      data_int_rst <= 0;
      cmd_int_rst <= 0;
      if(wb_stb_i & wb_cyc_i || wb_ack_o) begin
        if(wb_we_i) begin
          case(wb_adr_i)
            8'h00: begin
              argument_reg <= wb_dat_i;
              cmd_start <= 1'b1;
            end
            8'h04: command_reg <= wb_dat_i[14-1:0];
            8'h28: software_reset_reg <= wb_dat_i[0];
            8'h20: timeout_reg <= wb_dat_i[15:0];
            8'h44: block_size_reg <= wb_dat_i[12-1:0];
            8'h1c: controll_setting_reg <= wb_dat_i[15:0];
            8'h38: cmd_int_enable_reg <= wb_dat_i[4:0];
            8'h34: cmd_int_rst <= 1;
            8'h24: clock_divider_reg <= wb_dat_i[7:0];
            8'h3c: data_int_rst <= 1;
            8'h40: data_int_enable_reg <= wb_dat_i[3-1:0];
            8'h60: dma_addr_reg <= wb_dat_i;
            8'h48: block_count_reg <= wb_dat_i[16-1:0];
          endcase
        end 
        wb_ack_o <= wb_cyc_i & wb_stb_i & ~wb_ack_o;
      end 
    end
  end


  always @(posedge wb_clk_i or posedge wb_rst) begin
    if(wb_rst == 1) wb_dat_o <= 0; 
    else if(wb_stb_i & wb_cyc_i) begin
      case(wb_adr_i)
        8'h00: wb_dat_o <= argument_reg;
        8'h04: wb_dat_o <= command_reg;
        8'h08: wb_dat_o <= response_0_reg;
        8'h0c: wb_dat_o <= response_1_reg;
        8'h10: wb_dat_o <= response_2_reg;
        8'h14: wb_dat_o <= response_3_reg;
        8'h1c: wb_dat_o <= controll_setting_reg;
        8'h44: wb_dat_o <= block_size_reg;
        8'h2c: wb_dat_o <= voltage_controll_reg;
        8'h28: wb_dat_o <= software_reset_reg;
        8'h20: wb_dat_o <= timeout_reg;
        8'h34: wb_dat_o <= cmd_int_status_reg;
        8'h38: wb_dat_o <= cmd_int_enable_reg;
        8'h24: wb_dat_o <= clock_divider_reg;
        8'h30: wb_dat_o <= capabilies_reg;
        8'h3c: wb_dat_o <= data_int_status_reg;
        8'h48: wb_dat_o <= block_count_reg;
        8'h40: wb_dat_o <= data_int_enable_reg;
        8'h60: wb_dat_o <= dma_addr_reg;
      endcase
    end 
  end


endmodule

