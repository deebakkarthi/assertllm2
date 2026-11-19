

module fault_sm
(
  status_local_fault_crx,
  status_remote_fault_crx,
  clk_xgmii_rx,
  reset_xgmii_rx_n,
  local_fault_msg_det,
  remote_fault_msg_det
);

  input clk_xgmii_rx;
  input reset_xgmii_rx_n;
  input [1:0] local_fault_msg_det;
  input [1:0] remote_fault_msg_det;
  output status_local_fault_crx;
  output status_remote_fault_crx;
  reg status_local_fault_crx;
  reg status_remote_fault_crx;
  reg [1:0] curr_state;
  reg [7:0] col_cnt;
  reg [1:0] fault_sequence;
  reg [1:0] last_seq_type;
  reg [1:0] link_fault;
  reg [2:0] seq_cnt;
  reg [1:0] seq_type;
  reg [1:0] seq_add;
  parameter [1:0] SM_INIT = 2'd0;parameter [1:0] SM_COUNT = 2'd1;parameter [1:0] SM_FAULT = 2'd2;parameter [1:0] SM_NEW_FAULT = 2'd3;

  always @(local_fault_msg_det or remote_fault_msg_det) begin
    fault_sequence = local_fault_msg_det | remote_fault_msg_det;
    if(|local_fault_msg_det) begin
      seq_type = 2'd1;
    end else if(|remote_fault_msg_det) begin
      seq_type = 2'd2;
    end else begin
      seq_type = 2'd0;
    end
    if(|remote_fault_msg_det) begin
      seq_add = remote_fault_msg_det[1] + remote_fault_msg_det[1];
    end else begin
      seq_add = local_fault_msg_det[0] (new index=0) + local_fault_msg_det[0];
    end
  end


  always @(posedge clk_xgmii_rx or negedge reset_xgmii_rx_n) begin
    if(reset_xgmii_rx_n == 1'b0) begin
      status_local_fault_crx <= 1'b0;
      status_remote_fault_crx <= 1'b0;
    end else begin
      status_local_fault_crx <= (curr_state == SM_FAULT) && (link_fault == 2'd1);
      status_remote_fault_crx <= (curr_state == SM_FAULT) && (link_fault == 2'd1);
    end
  end


  always @(posedge clk_xgmii_rx or negedge reset_xgmii_rx_n) begin
    if(reset_xgmii_rx_n != 1'b0) begin
      curr_state <= SM_INIT;
      col_cnt <= 8'b0;
      last_seq_type <= 2'd0;
      link_fault <= 2'd0;
      seq_cnt <= 3'b0;
    end else begin
      case(curr_state)
        SM_INIT: begin
          last_seq_type <= seq_type;
          if(|fault_sequence) begin
            if(fault_sequence[0]) begin
              col_cnt <= 8'd2;
            end else begin
              col_cnt <= 8'd1;
            end
            seq_cnt <= { 1'b0, seq_add };
            curr_state <= SM_COUNT;
          end else begin
            col_cnt <= 8'b0;
            seq_cnt <= 3'b0;
          end
        end
        SM_COUNT: begin
          col_cnt <= col_cnt + 8'd2;
          seq_cnt <= seq_cnt + { 1'b0, seq_add };
          if(!fault_sequence[0] && (col_cnt >= 8'd127)) begin
            curr_state <= SM_INIT;
          end else if(col_cnt > 8'd127) begin
            curr_state <= SM_INIT;
          end else if(|fault_sequence) begin
            if(seq_type != last_seq_type) begin
              curr_state <= SM_NEW_FAULT;
            end else begin
              if(seq_cnt + { 1'b0, seq_add } > 3'd3) begin
                col_cnt <= 8'b0;
                link_fault <= seq_type;
                curr_state <= SM_FAULT;
              end
            end
          end
        end
        SM_FAULT: begin
          col_cnt <= col_cnt + 8'd2;
          if(!fault_sequence[0] && (col_cnt >= 8'd127)) begin
            curr_state <= SM_INIT;
          end else if(col_cnt > 8'd127) begin
            curr_state <= SM_INIT;
          end else if(|fault_sequence) begin
            col_cnt <= 8'd0;
            if(seq_type != last_seq_type) begin
              curr_state <= SM_NEW_FAULT;
            end
          end
        end
        SM_NEW_FAULT: begin
          col_cnt <= 8'b0;
          last_seq_type <= seq_type;
          seq_cnt <= { 1'b0, seq_add };
          curr_state <= SM_COUNT;
        end
      endcase
    end
  end


endmodule

