

module sd_controller_wb
(
  wb_clk_i,
  wb_rst_i,
  wb_dat_i,
  wb_dat_o,
  wb_adr_i,
  wb_sel_i,
  wb_we_i,
  wb_cyc_i,
  wb_stb_i,
  wb_ack_o,
  we_m_tx_bd,
  new_cmd,
  we_m_rx_bd,
  we_ack,
  int_ack,
  cmd_int_busy,
  Bd_isr_reset,
  normal_isr_reset,
  error_isr_reset,
  int_busy,
  dat_in_m_tx_bd,
  dat_in_m_rx_bd,
  write_req_s,
  cmd_set_s,
  cmd_arg_s,
  argument_reg,
  cmd_setting_reg,
  status_reg,
  cmd_resp_1,
  software_reset_reg,
  time_out_reg,
  normal_int_status_reg,
  error_int_status_reg,
  normal_int_signal_enable_reg,
  error_int_signal_enable_reg,
  clock_divider,
  Bd_Status_reg,
  Bd_isr_reg,
  Bd_isr_enable_reg
);

  input wb_clk_i;
  input wb_rst_i;
  input [31:0] wb_dat_i;
  output [31:0] wb_dat_o;reg [31:0] wb_dat_o;
  input [7:0] wb_adr_i;
  input [3:0] wb_sel_i;
  input wb_we_i;
  input wb_cyc_i;
  input wb_stb_i;
  output wb_ack_o;reg wb_ack_o;
  output we_m_tx_bd;reg we_m_tx_bd;
  output new_cmd;reg new_cmd;
  output we_ack;reg we_ack;
  output int_ack;reg int_ack;
  output cmd_int_busy;reg cmd_int_busy;
  output we_m_rx_bd;reg we_m_rx_bd;
  output int_busy;reg int_busy;
  input write_req_s;
  input [15:0] cmd_set_s;wire [15:0] cmd_set_s;
  input [31:0] cmd_arg_s;wire [31:0] cmd_arg_s;
  parameter power_controll_reg = 8'b0000_111_1;
  parameter block_size_reg = 512;
  parameter controll_setting_reg = 16'b0000_0000_0000_0010;
  parameter capabilies_reg = 16'b0000_0000_0000_0000;
  output [31:0] argument_reg;reg [31:0] argument_reg;
  output [15:0] cmd_setting_reg;reg [15:0] cmd_setting_reg;
  input [15:0] status_reg;wire [15:0] status_reg;
  input [31:0] cmd_resp_1;wire [31:0] cmd_resp_1;
  output [7:0] software_reset_reg;reg [7:0] software_reset_reg;
  output [15:0] time_out_reg;reg [15:0] time_out_reg;
  input [15:0] normal_int_status_reg;wire [15:0] normal_int_status_reg;
  input [15:0] error_int_status_reg;wire [15:0] error_int_status_reg;
  output [15:0] normal_int_signal_enable_reg;reg [15:0] normal_int_signal_enable_reg;
  output [15:0] error_int_signal_enable_reg;reg [15:0] error_int_signal_enable_reg;
  output [7:0] clock_divider;reg [7:0] clock_divider;
  input [15:0] Bd_Status_reg;wire [15:0] Bd_Status_reg;
  input [7:0] Bd_isr_reg;wire [7:0] Bd_isr_reg;
  output [7:0] Bd_isr_enable_reg;reg [7:0] Bd_isr_enable_reg;
  output Bd_isr_reset;reg Bd_isr_reset;
  output normal_isr_reset;reg normal_isr_reset;
  output error_isr_reset;reg error_isr_reset;
  output [16-1:0] dat_in_m_rx_bd;reg [16-1:0] dat_in_m_rx_bd;
  output [16-1:0] dat_in_m_tx_bd;reg [16-1:0] dat_in_m_tx_bd;
  reg [1:0] we;

  always @(posedge wb_clk_i or posedge wb_rst_i) begin
    we_m_rx_bd <= 0;
    we_m_tx_bd <= 0;
    new_cmd <= 1'b0;
    we_ack <= 0;
    int_ack = 1;
    cmd_int_busy <= 0;
    if(wb_rst_i) begin
      argument_reg <= 0;
      cmd_setting_reg <= 0;
      software_reset_reg <= 0;
      time_out_reg <= 0;
      normal_int_signal_enable_reg <= 0;
      error_int_signal_enable_reg <= 0;
      clock_divider <= 0;
      int_ack = 1;
      we <= 0;
      int_busy <= 0;
      we_ack <= 0;
      wb_ack_o = 0;
      cmd_int_busy <= 0;
      Bd_isr_reset <= 0;
      dat_in_m_tx_bd <= 0;
      dat_in_m_rx_bd <= 0;
      Bd_isr_enable_reg <= 0;
      normal_isr_reset <= 0;
      error_isr_reset <= 0;
    end else begin
      if(wb_stb_i & wb_cyc_i || wb_ack_o) begin
        Bd_isr_reset <= 0;
        normal_isr_reset <= 0;
        error_isr_reset <= 0;
        if(wb_we_i) begin
          case(wb_adr_i)
            8'h00: begin
              argument_reg <= wb_dat_i;
              new_cmd <= 1'b1;
            end
            8'h04: begin
              cmd_setting_reg <= wb_dat_i;
              int_busy <= 1;
            end
            8'h28: software_reset_reg <= wb_dat_i;
            8'h2c: time_out_reg <= wb_dat_i;
            8'h38: normal_int_signal_enable_reg <= wb_dat_i;
            8'h3c: error_int_signal_enable_reg <= wb_dat_i;
            8'h30: normal_isr_reset <= 1;
            8'h34: error_isr_reset <= 1;
            8'h4c: clock_divider <= wb_dat_i;
            8'h54: Bd_isr_reset <= 1;
            8'h58: Bd_isr_enable_reg <= wb_dat_i;
            8'h60: begin
              we <= we + 1;
              we_m_rx_bd <= 1;
              int_ack = 0;
              if(we[1:0] == 2'b00) we_m_rx_bd <= 0; 
              else if(we[1:0] == 2'b01) dat_in_m_rx_bd <= wb_dat_i[15:0]; 
              else if(we[1:0] == 2'b10) dat_in_m_rx_bd <= wb_dat_i[31:17]; 
              else begin
                int_ack = 1;
                we <= 0;
                we_m_rx_bd <= 0;
              end
            end
            8'h80: begin
              we <= we + 1;
              we_m_tx_bd <= 1;
              int_ack = 0;
              if(we[1:0] == 2'b00) we_m_tx_bd <= 0; 
              else if(we[1:0] == 2'b01) dat_in_m_tx_bd <= wb_dat_i[15:0]; 
              else if(we[1:0] == 2'b10) dat_in_m_tx_bd <= wb_dat_i[31:16]; 
              else begin
                int_ack = 1;
                we <= 0;
                we_m_tx_bd <= 0;
              end
            end
          endcase
        end 
        wb_ack_o = wb_cyc_i & wb_stb_i & ~wb_ack_o & int_ack;
      end else if(write_req_s) begin
        new_cmd <= 1'b1;
        cmd_setting_reg <= cmd_set_s;
        argument_reg <= cmd_arg_s;
        cmd_int_busy <= 1;
        we_ack <= 1;
      end 
      if(status_reg[0]) int_busy <= 0; 
    end
  end


  always @(posedge wb_clk_i) begin
    if(wb_stb_i & wb_cyc_i) begin
      case(wb_adr_i)
        8'h00: wb_dat_o <= argument_reg;
        8'h04: wb_dat_o <= cmd_setting_reg;
        8'h08: wb_dat_o <= status_reg;
        8'h0c: wb_dat_o <= cmd_resp_1;
        8'h1c: wb_dat_o <= controll_setting_reg;
        8'h20: wb_dat_o <= block_size_reg;
        8'h24: wb_dat_o <= power_controll_reg;
        8'h28: wb_dat_o <= software_reset_reg;
        8'h2c: wb_dat_o <= time_out_reg;
        8'h30: wb_dat_o <= normal_int_status_reg;
        8'h34: wb_dat_o <= error_int_status_reg;
        8'h38: wb_dat_o <= normal_int_signal_enable_reg;
        8'h3c: wb_dat_o <= error_int_signal_enable_reg;
        8'h4c: wb_dat_o <= clock_divider;
        8'h48: wb_dat_o <= capabilies_reg;
        8'h50: wb_dat_o <= Bd_Status_reg;
        8'h54: wb_dat_o <= Bd_isr_reg;
        8'h58: wb_dat_o <= Bd_isr_enable_reg;
      endcase
    end 
  end


endmodule

