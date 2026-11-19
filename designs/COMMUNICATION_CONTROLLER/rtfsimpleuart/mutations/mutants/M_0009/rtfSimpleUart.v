

module rtfSimpleUart
(
  input rst_i,
  input clk_i,
  input cyc_i,
  input stb_i,
  input we_i,
  input [31:0] adr_i,
  input [7:0] dat_i,
  output reg [7:0] dat_o,
  output ack_o,
  output vol_o,
  output irq_o,
  input cts_ni,
  output reg rts_no,
  input dsr_ni,
  input dcd_ni,
  output reg dtr_no,
  input rxd_i,
  output txd_o,
  output data_present_o
);

  parameter pClkFreq = 20000000;
  parameter pBaud = 19200;
  parameter pClkMul = 4096 * pBaud / (pClkFreq / 65536);
  parameter pRts = 1;
  parameter pDtr = 1;
  wire cs;assign cs = cyc_i && stb_i && (adr_i[31:4] == 28'hFFDC_0A0);
  assign ack_o = cs;
  assign vol_o = cs && (adr_i[3:2] == 2'b00);
  reg [23:0] c;
  reg [23:0] ck_mul;
  wire tx_empty;
  wire baud16;
  reg rx_present_ie;
  reg tx_empty_ie;
  reg dcd_ie;
  reg hwfc;
  wire clear;assign clear = (cyc_i && stb_i || we_i) && (adr_i == 4'd13);
  wire frame_err;
  wire over_run;
  reg [1:0] ctsx;
  reg [1:0] dcdx;
  reg [1:0] dsrx;
  wire dcd_chg;assign dcd_chg = dcdx[1] ^ dcdx[0];
  wire rxIRQ;assign rxIRQ = data_present_o & rx_present_ie;
  wire txIRQ;assign txIRQ = tx_empty & tx_empty_ie;
  wire msIRQ;assign msIRQ = dcd_chg & dcd_ie;
  assign irq_o = rxIRQ | txIRQ | msIRQ;
  wire [2:0] irqenc;assign irqenc = (rxIRQ)? 1 : 
                  (txIRQ)? 3 : 
                  (msIRQ)? 4 : 0;
  wire [7:0] rx_do;
  wire txrx;assign txrx = cs && (adr_i[3:0] == 4'd0);

  rtfSimpleUartRx
  uart_rx0
  (
    .rst_i(rst_i),
    .clk_i(clk_i),
    .cyc_i(cyc_i),
    .stb_i(stb_i),
    .cs_i(txrx),
    .we_i(we_i),
    .dat_o(rx_do),
    .baud16x_ce(baud16),
    .clear(clear),
    .rxd(rxd_i),
    .data_present(data_present_o),
    .frame_err(frame_err),
    .overrun(over_run)
  );


  rtfSimpleUartTx
  uart_tx0
  (
    .rst_i(rst_i),
    .clk_i(clk_i),
    .cyc_i(cyc_i),
    .stb_i(stb_i),
    .cs_i(txrx),
    .we_i(we_i),
    .dat_i(dat_i),
    .baud16x_ce(baud16),
    .cts(ctsx[1] | ~hwfc),
    .txd(txd_o),
    .empty(tx_empty)
  );


  always @(*) if(cs) begin
    case(adr_i[3:0])
      4'd2: dat_o <= { dcdx[1], 1'b0, dsrx[1], ctsx[1], dcd_chg, 3'b0 };
      4'd3: dat_o <= { irq_o, 2'b0, irqenc, 2'b0 };
      4'd1: dat_o <= { 1'b0, tx_empty, tx_empty, 1'b0, frame_err, 1'b0, over_run, data_present_o };
      default: dat_o <= rx_do;
    endcase
  end else dat_o <= 8'b0;


  always @(posedge clk_i) if(rst_i) c <= 0; 
  else c <= c + ck_mul;


  edge_det
  ed0
  (
    .rst(rst_i),
    .clk(clk_i),
    .ce(1'b1),
    .i(c[23]),
    .pe(baud16),
    .ne(),
    .ee()
  );


  always @(posedge clk_i) begin
    if(rst_i) begin
      rts_no <= ~pRts;
      rx_present_ie <= 1'b0;
      tx_empty_ie <= 1'b0;
      dcd_ie <= 1'b0;
      hwfc <= 1'b1;
      dtr_no <= ~pDtr;
      ck_mul <= pClkMul;
    end else if(cs & we_i) begin
      case(adr_i)
        4'd4: begin
          rx_present_ie <= dat_i[0];
          tx_empty_ie <= dat_i[1];
          dcd_ie <= dat_i[3];
        end
        4'd6: begin
          dtr_no <= ~dat_i[0];
          rts_no <= ~dat_i[1];
        end
        4'd7: hwfc <= dat_i[0];
        4'd9: ck_mul[7:0] <= dat_i;
        4'd10: ck_mul[15:8] <= dat_i;
        4'd11: ck_mul[23:16] <= dat_i;
        default: ;
      endcase
    end 
  end


  always @(posedge clk_i) ctsx <= { ctsx[0], ~cts_ni };


  always @(posedge clk_i) dcdx <= { dcdx[0], ~dcd_ni };


  always @(posedge clk_i) dsrx <= { dsrx[0], ~dsr_ni };


endmodule

