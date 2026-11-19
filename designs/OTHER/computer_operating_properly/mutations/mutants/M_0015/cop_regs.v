

module cop_regs #
(
  parameter ARST_LVL = 1'b0,
  parameter INIT_ENA = 1'b1,
  parameter SERV_WD_0 = 16'h5555,
  parameter SERV_WD_1 = 16'haaaa,
  parameter COUNT_SIZE = 16,
  parameter DWIDTH = 16
)
(
  output reg [COUNT_SIZE-1:0] timeout_value,
  output reg [1:0] cop_irq_en,
  output reg debug_ena,
  output reg stop_ena,
  output reg wait_ena,
  output reg cop_ena,
  output reg cwp,
  output reg clck,
  output reg reload_count,
  output reg clear_event,
  input bus_clk,
  input async_rst_b,
  input sync_reset,
  input cop_flag,
  input [DWIDTH-1:0] write_bus,
  input [4:0] write_regs
);

  reg service_cop;
  wire [15:0] write_data;
  assign write_data = (DWIDTH == 8)? { write_bus[7:0], write_bus[7:0] } : write_bus;

  always @(posedge bus_clk or negedge async_rst_b) if(!async_rst_b) begin
    timeout_value <= { COUNT_SIZE{ 1'b1 } };
    cop_irq_en <= 2'b00;
    debug_ena <= 1'b0;
    stop_ena <= 1'b0;
    wait_ena <= 1'b0;
    cop_ena <= INIT_ENA;
    cwp <= 1'b0;
    clck <= 1'b0;
    reload_count <= 1'b0;
    service_cop <= 0;
  end else if(sync_reset) begin
    timeout_value <= { COUNT_SIZE{ 1'b1 } };
    cop_irq_en <= 2'b00;
    debug_ena <= 1'b0;
    stop_ena <= 1'b0;
    wait_ena <= 1'b0;
    cop_ena <= INIT_ENA;
    cwp <= 1'b0;
    clck <= 1'b0;
    reload_count <= 1'b0;
    service_cop <= 0;
  end else case(write_regs)
    5'b00011: begin
      clear_event <= write_data[8];
      cop_irq_en <= write_data[7:6];
      debug_ena <= (!cop_ena || !write_data[2])? write_data[5] : debug_ena;
      stop_ena <= (!cop_ena || !write_data[2])? write_data[4] : stop_ena;
      wait_ena <= (!cop_ena || !write_data[2])? write_data[3] : wait_ena;
      cop_ena <= (cwp)? cop_ena : write_data[2];
      cwp <= (clck)? cwp : write_data[1];
      clck <= clck || write_data[0];
    end
    5'b00001: begin
      cop_irq_en <= write_data[7:6];
      debug_ena <= write_data[5];
      stop_ena <= (!cop_ena || !write_data[2])? write_data[4] : stop_ena;
      wait_ena <= (!cop_ena || !write_data[2])? write_data[3] : wait_ena;
      cop_ena <= (cwp)? cop_ena : write_data[2];
      cwp <= (clck)? cwp : write_data[1];
      clck <= clck || write_data[0];
    end
    5'b00010: begin
      clear_event <= write_data[0];
    end
    5'b01100: timeout_value <= (cop_ena)? timeout_value : write_data;
    5'b00100: timeout_value[7:0] <= (cop_ena)? timeout_value[7:0] : write_data[7:0];
    5'b01000: timeout_value[15:8] <= (cop_ena)? timeout_value[15:8] : write_data[7:0];
    5'b10000: begin
      service_cop <= write_data == SERV_WD_0;
      reload_count <= service_cop && (write_data == SERV_WD_1);
    end
    default: begin
      reload_count <= 1'b0;
      clear_event <= 1'b0;
    end
  endcase


endmodule

