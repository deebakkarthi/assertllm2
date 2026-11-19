

module pit_regs #
(
  parameter ARST_LVL = 1'b0,
  parameter COUNT_SIZE = 16,
  parameter NO_PRESCALE = 1'b0,
  parameter DWIDTH = 16
)
(
  output reg [COUNT_SIZE-1:0] mod_value,
  output [3:0] pit_pre_scl,
  output reg pit_slave,
  output reg pit_flg_clr,
  output reg pit_ien,
  output reg cnt_sync_o,
  output reg pit_irq_o,
  input bus_clk,
  input async_rst_b,
  input sync_reset,
  input pit_flag,
  input [DWIDTH-1:0] write_bus,
  input [3:0] write_regs,
  input cnt_flag_o
);

  reg [3:0] pit_pre;
  wire [15:0] write_data;
  assign write_data = (DWIDTH == 8)? { write_bus[7:0], write_bus[7:0] } : write_bus;
  assign pit_pre_scl = (NO_PRESCALE)? 4'b0 : pit_pre;

  always @(posedge bus_clk or negedge async_rst_b) if(!async_rst_b) begin
    pit_slave <= 1'b0;
    pit_pre <= 4'b0;
    pit_flg_clr <= 1'b0;
    pit_ien <= 1'b0;
    cnt_sync_o <= 1'b0;
    mod_value <= 0;
  end else if(sync_reset) begin
    pit_slave <= 1'b0;
    pit_pre <= 4'b0;
    pit_flg_clr <= 1'b0;
    pit_ien <= 1'b0;
    cnt_sync_o <= 1'b0;
    mod_value <= 0;
  end else case(write_regs)
    4'b0011: begin
      pit_slave <= write_data[15];
      pit_pre <= write_data[11:8];
      pit_flg_clr <= write_data[2];
      pit_ien <= write_data[1];
      cnt_sync_o <= write_data[0];
    end
    4'b0001: begin
      pit_flg_clr <= write_data[2];
      pit_ien <= write_data[1];
      cnt_sync_o <= write_data[0];
    end
    4'b0010: begin
      pit_slave <= write_data[7];
      pit_pre <= write_data[3:0];
    end
    4'b1100: mod_value <= write_data;
    4'b0100: mod_value[7:0] <= write_data[7:0];
    4'b1000: mod_value[15:8] <= write_data[7:0];
    default: pit_flg_clr <= 1'b0;
  endcase


  always @(posedge bus_clk or negedge async_rst_b) if(!async_rst_b) pit_irq_o <= 0; 
  else if(sync_reset) pit_irq_o <= 1; 
  else pit_irq_o <= cnt_flag_o && pit_ien;


endmodule

