

module uart_msg_handler
(
  reset_n,
  sys_clk,
  tx_data_avail,
  tx_rd,
  tx_data,
  rx_ready,
  rx_wr,
  rx_data,
  reg_addr,
  reg_wr,
  reg_wdata,
  reg_req,
  reg_ack,
  reg_rdata
);

  input reset_n;
  input sys_clk;
  output tx_data_avail;
  output [7:0] tx_data;
  input tx_rd;
  output rx_ready;
  input [7:0] rx_data;
  input rx_wr;
  output [15:0] reg_addr;
  output [31:0] reg_wdata;
  output reg_req;
  output reg_wr;
  input reg_ack;
  input [31:0] reg_rdata;
  reg tx_data_avail;
  reg [7:0] tx_data;
  reg [16*8-1:0] TxMsgBuf;
  reg [4:0] TxMsgSize;
  reg [4:0] RxMsgCnt;
  reg [3:0] State;
  reg [3:0] NextState;
  reg [15:0] cmd;
  reg [15:0] reg_addr;
  reg [31:0] reg_wdata;
  reg reg_wr;
  reg reg_req;
  wire rx_ready;assign rx_ready = 1;

  always @(negedge reset_n or posedge sys_clk) begin
    if(reset_n == 1'b0) begin
      tx_data_avail <= 0;
      reg_req <= 0;
      State <= 4'h0;
      NextState <= 4'h0;
    end else begin
      case(State)
        4'h0: begin
          TxMsgBuf <= "Command Format:\n";
          TxMsgSize <= 16;
          tx_data_avail <= 0;
          State <= 4'hA;
          NextState <= 4'h1;
        end
        4'h1: begin
          TxMsgBuf <= "wm <ad> <data>\n ";
          TxMsgSize <= 15;
          tx_data_avail <= 0;
          State <= 4'hA;
          NextState <= 4'h2;
        end
        4'h2: begin
          TxMsgBuf <= "rm <ad>\n>>      ";
          TxMsgSize <= 10;
          tx_data_avail <= 0;
          RxMsgCnt <= 0;
          State <= 4'hA;
          NextState <= 4'h3;
        end
        4'h3: begin
          if(rx_wr == 1) begin
            if((RxMsgCnt == 0) && (rx_data == 8'h20)) begin
            end else if((RxMsgCnt > 0) && (rx_data == 8'h20)) begin
              if(cmd == 16'h776D) begin
                RxMsgCnt <= 0;
                reg_addr <= 0;
                reg_wdata <= 0;
                State <= 4'h4;
              end else if(cmd == 16'h726D) begin
                reg_addr <= 0;
                RxMsgCnt <= 0;
                State <= 4'h7;
              end else begin
                State <= 4'h0;
              end
            end else if(rx_data == 8'h0A) begin
              State <= 4'h0;
            end else begin
              cmd <= (cmd << 8) | rx_data;
              RxMsgCnt <= RxMsgCnt + 1;
            end
          end 
        end
        4'h4: begin
          if(rx_wr == 1) begin
            if((RxMsgCnt == 0) && (rx_data == 8'h20)) begin
            end else if((RxMsgCnt > 0) && (rx_data == 8'h20)) begin
              State <= 4'h5;
            end else if(rx_data == 8'h0A) begin
              State <= 4'h0;
            end else begin
              reg_addr <= (reg_addr << 4) | char2hex(rx_data);
              RxMsgCnt <= RxMsgCnt + 1;
            end
          end 
        end
        4'h5: begin
          if(rx_wr == 1) begin
            if(rx_data == 8'h20) begin
            end else if(rx_data == 8'h0A) begin
              State <= 4'h6;
              reg_wr <= 1'b1;
              reg_req <= 1'b1;
            end else begin
              reg_wdata <= (reg_wdata >> 4) | char2hex(rx_data);
            end
          end 
        end
        4'h6: begin
          if(reg_ack) begin
            reg_req <= 1'b0;
            TxMsgBuf <= "cmd success\n>>  ";
            TxMsgSize <= 14;
            tx_data_avail <= 0;
            State <= 4'hA;
            NextState <= 4'h3;
          end 
        end
        4'h7: begin
          if(rx_wr == 1) begin
            if(rx_data == 8'h20) begin
            end else if(rx_data == 8'h0A) begin
              State <= 4'h8;
              reg_wr <= 1'b0;
              reg_req <= 1'b1;
            end else begin
              reg_addr <= (reg_addr << 4) | char2hex(rx_data);
              RxMsgCnt <= RxMsgCnt + 1;
            end
          end 
        end
        4'h8: begin
          if(reg_ack) begin
            reg_req <= 1'b0;
            TxMsgBuf <= "Response:       ";
            TxMsgSize <= 10;
            tx_data_avail <= 0;
            State <= 4'hA;
            NextState <= 4'h9;
          end 
        end
        4'h9: begin
          TxMsgBuf[16*8-1:15*8] <= hex2char(reg_rdata[31:28]);
          TxMsgBuf[15*8-1:14*8] <= hex2char(reg_rdata[27:24]);
          TxMsgBuf[14*8-1:13*8] <= hex2char(reg_rdata[23:20]);
          TxMsgBuf[13*8-1:12*8] <= hex2char(reg_rdata[19:16]);
          TxMsgBuf[12*8-1:11*8] <= hex2char(reg_rdata[15:12]);
          TxMsgBuf[11*8-1:10*8] <= hex2char(reg_rdata[11:8]);
          TxMsgBuf[10*8-1:9*8] <= hex2char(reg_rdata[7:4]);
          TxMsgBuf[9*8-1:8*8] <= hex2char(reg_rdata[3:0]);
          TxMsgBuf[8*8-1:7*8] <= "\n";
          TxMsgSize <= 9;
          tx_data_avail <= 0;
          State <= 4'hA;
          NextState <= 4'h3;
        end
        4'hA: begin
          tx_data_avail <= 1;
          tx_data <= TxMsgBuf[16*8-1:15*8];
          if(TxMsgSize == 0) begin
            tx_data_avail <= 0;
            State <= NextState;
          end else if(tx_rd) begin
            TxMsgBuf <= TxMsgBuf << 8;
            TxMsgSize <= TxMsgSize - 1;
          end 
        end
      endcase
    end
  end


  function [3:0] char2hex;
    input [7:0] data_in;
    case(data_in)
      8'h30: char2hex = 4'h0;
      8'h31: char2hex = 4'h1;
      8'h32: char2hex = 4'h2;
      8'h33: char2hex = 4'h3;
      8'h34: char2hex = 4'h4;
      8'h35: char2hex = 4'h5;
      8'h36: char2hex = 4'h6;
      8'h37: char2hex = 4'h7;
      8'h38: char2hex = 4'h8;
      8'h39: char2hex = 4'h9;
      8'h41: char2hex = 4'hA;
      8'h42: char2hex = 4'hB;
      8'h43: char2hex = 4'hC;
      8'h44: char2hex = 4'hD;
      8'h45: char2hex = 4'hE;
      8'h46: char2hex = 4'hF;
      8'h61: char2hex = 4'hA;
      8'h62: char2hex = 4'hB;
      8'h63: char2hex = 4'hC;
      8'h64: char2hex = 4'hD;
      8'h65: char2hex = 4'hE;
      8'h66: char2hex = 4'hF;
      default: char2hex = 4'hF;
    endcase
  endfunction


  function [7:0] hex2char;
    input [3:0] data_in;
    case(data_in)
      4'h0: hex2char = 8'h30;
      4'h1: hex2char = 8'h31;
      4'h2: hex2char = 8'h32;
      4'h3: hex2char = 8'h33;
      4'h4: hex2char = 8'h34;
      4'h5: hex2char = 8'h35;
      4'h6: hex2char = 8'h36;
      4'h7: hex2char = 8'h37;
      4'h8: hex2char = 8'h38;
      4'h9: hex2char = 8'h39;
      4'hA: hex2char = 8'h41;
      4'hB: hex2char = 8'h42;
      4'hC: hex2char = 8'h43;
      4'hD: hex2char = 8'h44;
      4'hE: hex2char = 8'h45;
      4'hF: hex2char = 8'h46;
    endcase
  endfunction


endmodule

