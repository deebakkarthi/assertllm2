

module sd_data_master
(
  input clk,
  input rst,
  input [16-1:0] dat_in_tx,
  input [5-1:0] free_tx_bd,
  input ack_i_s_tx,
  output reg re_s_tx,
  output reg a_cmp_tx,
  input [16-1:0] dat_in_rx,
  input [5-1:0] free_rx_bd,
  input ack_i_s_rx,
  output reg re_s_rx,
  output reg a_cmp_rx,
  input cmd_busy,
  output reg we_req,
  input we_ack,
  output reg d_write,
  output reg d_read,
  output reg [31:0] cmd_arg,
  output reg [15:0] cmd_set,
  input cmd_tsf_err,
  input [4:0] card_status,
  output reg start_tx_fifo,
  output reg start_rx_fifo,
  output reg [31:0] sys_adr,
  input tx_empt,
  input tx_full,
  input rx_full,
  input busy_n,
  input transm_complete,
  input crc_ok,
  output reg ack_transfer,
  output reg [7:0] Dat_Int_Status,
  input Dat_Int_Status_rst,
  output reg CIDAT,
  input [1:0] transfer_type
);

  reg [2:0] bd_cnt;
  reg send_done;
  reg rec_done;
  reg rec_failed;
  reg tx_cycle;
  reg rx_cycle;
  reg [2:0] resend_try_cnt;
  parameter CMD24 = 16'h181A;
  parameter CMD17 = 16'h111A;
  parameter CMD12 = 16'hC1A;
  parameter ACMD13 = 16'hD1A;
  parameter ACMD51 = 16'h331A;
  parameter SIZE = 9;
  reg [SIZE-1:0] state;
  reg [SIZE-1:0] next_state;
  parameter IDLE = 9'b000000001;
  parameter GET_TX_BD = 9'b000000010;
  parameter GET_RX_BD = 9'b000000100;
  parameter SEND_CMD = 9'b000001000;
  parameter RECIVE_CMD = 9'b000010000;
  parameter DATA_TRANSFER = 9'b000100000;
  parameter STOP = 9'b001000000;
  parameter STOP_SEND = 9'b010000000;
  parameter STOP_RECIVE_CMD = 9'b100000000;
  reg trans_done;
  reg trans_failed;
  reg internal_transm_complete;
  reg transm_complete_q;

  always @(posedge clk or posedge rst) begin
    if(rst) begin
      internal_transm_complete <= 1'b0;
      transm_complete_q <= 0;
    end else begin
      transm_complete_q <= transm_complete;
      internal_transm_complete <= transm_complete_q;
    end
  end


  always @(state or resend_try_cnt or tx_full or free_tx_bd or free_rx_bd or bd_cnt or send_done or rec_done or rec_failed or trans_done or trans_failed) begin : FSM_COMBO
    next_state = 0;
    case(state)
      IDLE: begin
        if(free_tx_bd != 32 / 4) begin
          next_state = GET_TX_BD;
        end else if(free_rx_bd != 32 / 4) begin
          next_state = GET_RX_BD;
        end else begin
          next_state = IDLE;
        end
      end
      GET_TX_BD: begin
        if((bd_cnt > 4 - 1) && (tx_full == 1)) begin
          next_state = SEND_CMD;
        end else begin
          next_state = GET_TX_BD;
        end
      end
      GET_RX_BD: begin
        if(bd_cnt >= 4 - 1) begin
          next_state = SEND_CMD;
        end else begin
          next_state = GET_RX_BD;
        end
      end
      SEND_CMD: begin
        if(send_done) begin
          next_state = RECIVE_CMD;
        end else begin
          next_state = SEND_CMD;
        end
      end
      RECIVE_CMD: begin
        if(rec_done) next_state = DATA_TRANSFER; 
        else if(rec_failed) next_state = SEND_CMD; 
        else next_state = RECIVE_CMD;
      end
      DATA_TRANSFER: begin
        if(trans_done) next_state = IDLE; 
        else if(trans_failed) next_state = STOP; 
        else next_state = DATA_TRANSFER;
      end
      STOP: begin
        next_state = STOP_SEND;
      end
      STOP_SEND: begin
        if(send_done) begin
          next_state = IDLE;
        end else begin
          next_state = STOP_SEND;
        end
      end
      STOP_RECIVE_CMD: begin
        if(rec_done) next_state = SEND_CMD; 
        else if(rec_failed) next_state = STOP; 
        else if(resend_try_cnt >= 3) next_state = IDLE; 
        else next_state = STOP_RECIVE_CMD;
      end
      default: next_state = IDLE;
    endcase
  end


  always @(posedge clk or posedge rst) begin : FSM_SEQ
    if(rst) begin
      state <= #1 IDLE;
    end else begin
      state <= #1 next_state;
    end
  end


  always @(posedge clk or posedge rst) begin
    if(rst) begin
      send_done <= 0;
      bd_cnt <= 0;
      sys_adr <= 0;
      cmd_arg <= 0;
      rec_done <= 0;
      start_tx_fifo <= 0;
      start_rx_fifo <= 0;
      send_done <= 0;
      rec_failed <= 0;
      d_write <= 0;
      d_read <= 0;
      trans_failed <= 0;
      trans_done <= 0;
      tx_cycle <= 0;
      rx_cycle <= 0;
      ack_transfer <= 0;
      a_cmp_tx <= 0;
      a_cmp_rx <= 0;
      CIDAT <= 0;
      Dat_Int_Status <= 0;
      we_req <= 0;
      re_s_tx <= 0;
      re_s_rx <= 0;
      cmd_set <= 0;
      resend_try_cnt = 0;
    end else begin
      case(state)
        IDLE: begin
          send_done <= 0;
          bd_cnt <= 0;
          sys_adr <= 0;
          cmd_arg <= 0;
          rec_done <= 0;
          rec_failed <= 0;
          start_tx_fifo <= 0;
          start_rx_fifo <= 0;
          send_done <= 0;
          d_write <= 0;
          d_read <= 0;
          trans_failed <= 0;
          trans_done <= 0;
          tx_cycle <= 0;
          rx_cycle <= 0;
          ack_transfer <= 0;
          a_cmp_tx <= 0;
          a_cmp_rx <= 0;
          resend_try_cnt = 0;
        end
        GET_RX_BD: begin
          re_s_rx <= 1;
          if(ack_i_s_rx) begin
            if(bd_cnt == 2'b00) begin
              sys_adr[15:0] <= dat_in_rx;
            end else if(bd_cnt == 2'b01) begin
              sys_adr[31:16] <= dat_in_rx;
            end else if(bd_cnt == 2) begin
              cmd_arg[15:0] <= dat_in_rx;
              re_s_rx <= 0;
            end else if(bd_cnt == 3) begin
              cmd_arg[31:16] <= dat_in_rx;
              re_s_rx <= 0;
            end 
            bd_cnt <= bd_cnt + 1;
          end 
          if(transfer_type == 2'b00) cmd_set <= CMD17; 
          else if(transfer_type == 2'b01) cmd_set <= ACMD13; 
          else cmd_set <= ACMD51;
          rx_cycle <= 1;
        end
        GET_TX_BD: begin
          re_s_tx <= 1;
          if(bd_cnt == 4) re_s_tx <= 0; 
          if(ack_i_s_tx) begin
            if(bd_cnt == 0) begin
              sys_adr[15:0] <= dat_in_tx;
              bd_cnt <= bd_cnt + 1;
            end else if(bd_cnt == 1) begin
              sys_adr[31:16] <= dat_in_tx;
              bd_cnt <= bd_cnt + 1;
            end else if(bd_cnt == 2) begin
              cmd_arg[15:0] <= dat_in_tx;
              re_s_tx <= 0;
              bd_cnt <= bd_cnt + 1;
            end else if(bd_cnt == 3) begin
              cmd_arg[31:16] <= dat_in_tx;
              re_s_tx <= 0;
              bd_cnt <= bd_cnt + 1;
              start_tx_fifo <= 1;
            end 
          end 
          cmd_set <= CMD24;
          tx_cycle <= 1;
        end
        SEND_CMD: begin
          rec_done <= 0;
          if(rx_cycle) begin
            re_s_rx <= 0;
            d_read <= 1;
          end else begin
            re_s_tx <= 0;
            d_write <= 1;
          end
          start_rx_fifo <= 0;
          if(!cmd_busy) begin
            we_req <= 1;
          end 
          if(we_ack) begin
            send_done <= 1;
            we_req <= 1;
          end 
        end
        RECIVE_CMD: begin
          if(rx_cycle) start_rx_fifo <= 1; 
          we_req <= 0;
          send_done <= 0;
          if(!cmd_busy) begin
            d_read <= 0;
            d_write <= 0;
            if(!cmd_tsf_err) begin
              if(card_status[0]) begin
                if((card_status[4:1] == 4'b0100) || (card_status[4:1] == 4'b0110) || (card_status[4:1] == 4'b0101)) rec_done <= 1; 
                else begin
                  rec_failed <= 1;
                  Dat_Int_Status[4] <= 1;
                  start_tx_fifo <= 0;
                end
              end 
            end else begin
              rec_failed <= 1;
              start_tx_fifo <= 0;
            end
          end 
        end
        DATA_TRANSFER: begin
          CIDAT <= 1;
          if(tx_cycle) begin
            if(tx_empt) begin
              Dat_Int_Status[2] <= 1;
              trans_failed <= 1;
            end 
          end else begin
            if(rx_full) begin
              Dat_Int_Status[2] <= 1;
              trans_failed <= 1;
            end 
          end
          if(internal_transm_complete) begin
            ack_transfer <= 1;
            if(!crc_ok && busy_n) begin
              Dat_Int_Status[5] <= 1;
              trans_failed <= 1;
            end else if(crc_ok && busy_n) begin
              trans_done <= 1;
              if(tx_cycle) begin
                a_cmp_tx <= 1;
                if(free_tx_bd == 32 / 4 - 1) Dat_Int_Status[0] <= 1; 
              end else begin
                a_cmp_rx <= 1;
                if(free_rx_bd != 32 / 4 - 1) Dat_Int_Status[0] <= 1; 
              end
            end 
          end 
        end
        STOP: begin
          cmd_set <= CMD12;
          rec_done <= 0;
          rec_failed <= 0;
          send_done <= 0;
          trans_failed <= 0;
          trans_done <= 0;
          d_read <= 1;
          d_write <= 1;
          start_rx_fifo <= 0;
          start_tx_fifo <= 0;
        end
        STOP_SEND: begin
          resend_try_cnt = resend_try_cnt + 1;
          if(resend_try_cnt == 3) Dat_Int_Status[1] <= 1; 
          if(!cmd_busy) we_req <= 1; 
          if(we_ack) send_done <= 1; 
        end
        STOP_RECIVE_CMD: begin
          we_req <= 0;
        end
      endcase
      if(Dat_Int_Status_rst) Dat_Int_Status <= 0; 
    end
  end


endmodule

