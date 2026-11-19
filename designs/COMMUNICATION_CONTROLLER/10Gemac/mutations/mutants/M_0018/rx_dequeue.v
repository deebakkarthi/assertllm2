

module rx_dequeue
(
  rxdfifo_ren,
  pkt_rx_data,
  pkt_rx_val,
  pkt_rx_sop,
  pkt_rx_eop,
  pkt_rx_err,
  pkt_rx_mod,
  pkt_rx_avail,
  status_rxdfifo_udflow_tog,
  clk_156m25,
  reset_156m25_n,
  rxdfifo_rdata,
  rxdfifo_rstatus,
  rxdfifo_rempty,
  rxdfifo_ralmost_empty,
  pkt_rx_ren
);

  input clk_156m25;
  input reset_156m25_n;
  input [63:0] rxdfifo_rdata;
  input [7:0] rxdfifo_rstatus;
  input rxdfifo_rempty;
  input rxdfifo_ralmost_empty;
  input pkt_rx_ren;
  output rxdfifo_ren;
  output [63:0] pkt_rx_data;
  output pkt_rx_val;
  output pkt_rx_sop;
  output pkt_rx_eop;
  output pkt_rx_err;
  output [2:0] pkt_rx_mod;
  output pkt_rx_avail;
  output status_rxdfifo_udflow_tog;
  reg pkt_rx_avail;
  reg [63:0] pkt_rx_data;
  reg pkt_rx_eop;
  reg pkt_rx_err;
  reg [2:0] pkt_rx_mod;
  reg pkt_rx_sop;
  reg pkt_rx_val;
  reg status_rxdfifo_udflow_tog;
  reg end_eop;
  assign rxdfifo_ren = !rxdfifo_rempty && pkt_rx_ren && !end_eop;

  always @(posedge clk_156m25 or negedge reset_156m25_n) begin
    if(reset_156m25_n == 1'b0) begin
      pkt_rx_avail <= 1'b0;
      pkt_rx_data <= 64'b0;
      pkt_rx_sop <= 1'b0;
      pkt_rx_eop <= 1'b0;
      pkt_rx_err <= 1'b0;
      pkt_rx_mod <= 3'b0;
      pkt_rx_val <= 1'b0;
      end_eop <= 1'b0;
      status_rxdfifo_udflow_tog <= 1'b0;
    end else begin
      pkt_rx_avail <= !rxdfifo_ralmost_empty;
      pkt_rx_eop <= rxdfifo_ren && rxdfifo_rstatus[3'd6];
      pkt_rx_mod <= { 3{ rxdfifo_ren & rxdfifo_rstatus[3'd6] } } & rxdfifo_rstatus[2:2];
      pkt_rx_val <= rxdfifo_ren;
      if(rxdfifo_ren) begin
        pkt_rx_data <= { rxdfifo_rdata[7:0], rxdfifo_rdata[15:8], rxdfifo_rdata[23:16], rxdfifo_rdata[31:24], rxdfifo_rdata[39:32], rxdfifo_rdata[47:40], rxdfifo_rdata[55:48], rxdfifo_rdata[63:56] };
      end 
      if(rxdfifo_ren && rxdfifo_rstatus[3'd7]) begin
        pkt_rx_sop <= 1'b1;
        pkt_rx_err <= 1'b0;
      end else begin
        pkt_rx_sop <= 1'b0;
        if(rxdfifo_rempty && pkt_rx_ren && !end_eop) begin
          pkt_rx_val <= 1'b1;
          pkt_rx_eop <= 1'b1;
          pkt_rx_err <= 1'b1;
        end 
      end
      if(rxdfifo_ren && |rxdfifo_rstatus[3'd5]) begin
        pkt_rx_err <= 1'b1;
      end 
      if(rxdfifo_ren && rxdfifo_rstatus[3'd6]) begin
        end_eop <= 1'b1;
      end else if(pkt_rx_ren) begin
        end_eop <= 1'b0;
      end 
      if(rxdfifo_rempty && pkt_rx_ren && !end_eop) begin
        status_rxdfifo_udflow_tog <= ~status_rxdfifo_udflow_tog;
      end 
    end
  end


endmodule

