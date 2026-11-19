

module xgate_regs #
(
  parameter ARST_LVL = 1'b0,
  parameter MAX_CHANNEL = 127
)
(
  output reg xge,
  output reg xgfrz,
  output reg xgdbg_set,
  output reg xgdbg_clear,
  output reg xgss,
  output reg xgfact,
  output reg xgsweif_c,
  output reg xgie,
  output reg [15:1] xgvbr,
  output reg [7:0] xgswt,
  output reg clear_xgif_7,
  output reg clear_xgif_6,
  output reg clear_xgif_5,
  output reg clear_xgif_4,
  output reg clear_xgif_3,
  output reg clear_xgif_2,
  output reg clear_xgif_1,
  output reg clear_xgif_0,
  output reg [15:0] clear_xgif_data,
  output reg brk_irq_ena,
  output [MAX_CHANNEL:1] chan_bypass,
  output reg [MAX_CHANNEL:1] irq_bypass,
  input bus_clk,
  input async_rst_b,
  input sync_reset,
  input [15:0] write_bus,
  input write_xgmctl,
  input [1:0] write_xgvbr,
  input [1:0] write_xgif_7,
  input [1:0] write_xgif_6,
  input [1:0] write_xgif_5,
  input [1:0] write_xgif_4,
  input [1:0] write_xgif_3,
  input [1:0] write_xgif_2,
  input [1:0] write_xgif_1,
  input [1:0] write_xgif_0,
  input [1:0] write_irw_en_7,
  input [1:0] write_irw_en_6,
  input [1:0] write_irw_en_5,
  input [1:0] write_irw_en_4,
  input [1:0] write_irw_en_3,
  input [1:0] write_irw_en_2,
  input [1:0] write_irw_en_1,
  input [1:0] write_irw_en_0,
  input write_xgswt,
  input debug_ack
);

  integer j;
  integer k;
  reg [MAX_CHANNEL:1] irq_bypass_d;
  wire [1:0] write_any_xgif;

  always @(posedge bus_clk or negedge async_rst_b) if(!async_rst_b) begin
    xge <= 1'b0;
    xgfrz <= 1'b0;
    xgdbg_set <= 1'b0;
    xgdbg_clear <= 1'b0;
    xgss <= 1'b0;
    xgfact <= 1'b0;
    brk_irq_ena <= 1'b0;
    xgsweif_c <= 1'b0;
    xgie <= 1'b0;
  end else if(sync_reset) begin
    xge <= 1'b0;
    xgfrz <= 1'b0;
    xgdbg_set <= 1'b0;
    xgdbg_clear <= 1'b0;
    xgss <= 1'b0;
    xgfact <= 1'b0;
    brk_irq_ena <= 1'b0;
    xgsweif_c <= 1'b0;
    xgie <= 1'b0;
  end else if(write_xgmctl) begin
    xge <= (write_bus[15])? write_bus[7] : xge;
    xgfrz <= (write_bus[14])? write_bus[6] : xgfrz;
    xgdbg_set <= write_bus[13] && write_bus[5];
    xgdbg_clear <= write_bus[13] && !write_bus[5];
    xgss <= write_bus[12] && write_bus[4];
    xgfact <= (write_bus[11])? write_bus[3] : xgfact;
    brk_irq_ena <= (write_bus[10])? write_bus[2] : brk_irq_ena;
    xgsweif_c <= write_bus[9] && write_bus[1];
    xgie <= (write_bus[8])? write_bus[0] : xgie;
  end else begin
    xgss <= 1'b0;
    xgsweif_c <= 1'b0;
    xgdbg_set <= xgdbg_set && !debug_ack;
    xgdbg_clear <= 1'b0;
  end


  always @(posedge bus_clk or negedge async_rst_b) if(!async_rst_b) begin
    xgvbr <= 15'b1111_1110_0000_000;
  end else if(sync_reset) begin
    xgvbr <= 15'b1111_1110_0000_000;
  end else if(|write_xgvbr && !xge) begin
    xgvbr[15:8] <= (write_xgvbr[1])? write_bus[15:8] : xgvbr[15:8];
    xgvbr[7:1] <= (write_xgvbr[0])? write_bus[7:1] : xgvbr[7:1];
  end 

  assign write_any_xgif = write_xgif_7 | write_xgif_6 | write_xgif_5 | write_xgif_4 | write_xgif_3 | write_xgif_2 | write_xgif_1 | write_xgif_0;

  always @(posedge bus_clk or negedge async_rst_b) if(!async_rst_b) begin
    clear_xgif_7 <= 1'b0;
    clear_xgif_6 <= 1'b0;
    clear_xgif_5 <= 1'b0;
    clear_xgif_4 <= 1'b0;
    clear_xgif_3 <= 1'b0;
    clear_xgif_2 <= 1'b0;
    clear_xgif_1 <= 1'b0;
    clear_xgif_0 <= 1'b0;
    clear_xgif_data <= 16'b0;
  end else if(sync_reset) begin
    clear_xgif_7 <= 1'b0;
    clear_xgif_6 <= 1'b0;
    clear_xgif_5 <= 1'b0;
    clear_xgif_4 <= 1'b0;
    clear_xgif_3 <= 1'b0;
    clear_xgif_2 <= 1'b0;
    clear_xgif_1 <= 1'b0;
    clear_xgif_0 <= 1'b0;
    clear_xgif_data <= 16'b0;
  end else begin
    clear_xgif_7 <= |write_xgif_7 && (MAX_CHANNEL > 111);
    clear_xgif_6 <= |write_xgif_6 && (MAX_CHANNEL > 95);
    clear_xgif_5 <= |write_xgif_5 && (MAX_CHANNEL > 79);
    clear_xgif_4 <= |write_xgif_4 && (MAX_CHANNEL > 63);
    clear_xgif_3 <= |write_xgif_3 && (MAX_CHANNEL > 47);
    clear_xgif_2 <= |write_xgif_2 && (MAX_CHANNEL > 31);
    clear_xgif_1 <= |write_xgif_1 && (MAX_CHANNEL > 15);
    clear_xgif_0 <= |write_xgif_0;
    clear_xgif_data[15:8] <= (write_any_xgif[1])? write_bus[15:8] : 8'b0;
    clear_xgif_data[7:0] <= (write_any_xgif[0])? write_bus[7:0] : 8'b0;
  end


  always @(posedge bus_clk or negedge async_rst_b) if(!async_rst_b) xgswt <= 8'h00; 
  else if(sync_reset) xgswt <= 8'h00; 
  else if(write_xgswt) xgswt <= write_bus[15:8] & write_bus[7:0] | ~write_bus[15:8] & xgswt[7:0]; 


  always @(*) begin
    k = 1;
    for(j=1; j<=127; j=j+1) begin
      if(j <= MAX_CHANNEL) begin
        if((j >= 0) && (j < 8)) irq_bypass_d[j] = (write_irw_en_0[0])? write_bus[k] : irq_bypass[j]; 
        if((j >= 8) && (j < 16)) irq_bypass_d[j] = (write_irw_en_0[1])? write_bus[k] : irq_bypass[j]; 
        if((j >= 16) && (j < 24)) irq_bypass_d[j] = write_bus[k]; 
        if((j >= 24) && (j < 32)) irq_bypass_d[j] = (write_irw_en_1[1])? write_bus[k] : irq_bypass[j]; 
        if((j >= 32) && (j < 40)) irq_bypass_d[j] = (write_irw_en_2[0])? write_bus[k] : irq_bypass[j]; 
        if((j >= 40) && (j < 48)) irq_bypass_d[j] = (write_irw_en_2[1])? write_bus[k] : irq_bypass[j]; 
        if((j >= 48) && (j < 56)) irq_bypass_d[j] = (write_irw_en_3[0])? write_bus[k] : irq_bypass[j]; 
        if((j >= 56) && (j < 64)) irq_bypass_d[j] = (write_irw_en_3[1])? write_bus[k] : irq_bypass[j]; 
        if((j >= 64) && (j < 72)) irq_bypass_d[j] = (write_irw_en_4[0])? write_bus[k] : irq_bypass[j]; 
        if((j >= 72) && (j < 80)) irq_bypass_d[j] = (write_irw_en_4[1])? write_bus[k] : irq_bypass[j]; 
        if((j >= 80) && (j < 88)) irq_bypass_d[j] = (write_irw_en_5[0])? write_bus[k] : irq_bypass[j]; 
        if((j >= 88) && (j < 96)) irq_bypass_d[j] = (write_irw_en_5[1])? write_bus[k] : irq_bypass[j]; 
        if((j >= 96) && (j < 104)) irq_bypass_d[j] = (write_irw_en_6[0])? write_bus[k] : irq_bypass[j]; 
        if((j >= 104) && (j < 112)) irq_bypass_d[j] = (write_irw_en_6[1])? write_bus[k] : irq_bypass[j]; 
        if((j >= 112) && (j < 120)) irq_bypass_d[j] = (write_irw_en_7[0])? write_bus[k] : irq_bypass[j]; 
        if((j >= 120) && (j < 128)) irq_bypass_d[j] = (write_irw_en_7[1])? write_bus[k] : irq_bypass[j]; 
      end else irq_bypass_d[j] = 1'b0;
      k = k + 1;
      if(k > 15) k = 0; 
    end
  end


  always @(posedge bus_clk or negedge async_rst_b) if(!async_rst_b) irq_bypass <= { MAX_CHANNEL{ 1'b1 } }; 
  else if(sync_reset) irq_bypass <= { MAX_CHANNEL{ 1'b1 } }; 
  else irq_bypass <= irq_bypass_d;

  assign chan_bypass = irq_bypass[MAX_CHANNEL:1];

endmodule

