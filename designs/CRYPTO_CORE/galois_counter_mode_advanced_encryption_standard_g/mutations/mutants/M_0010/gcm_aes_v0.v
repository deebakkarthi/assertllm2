

module gcm_aes_v0
(
  input clk,
  input rst,
  input [128-1:0] dii_data,
  input dii_data_vld,
  input dii_data_type,
  output reg dii_data_not_ready,
  input dii_last_word,
  input [3:0] dii_data_size,
  input cii_ctl_vld,
  input cii_IV_vld,
  input [128-1:0] cii_K,
  output reg [128-1:0] Out_data,
  output reg Out_vld,
  output reg [3:0] Out_data_size,
  output reg Out_last_word,
  output reg Tag_vld
);

  reg [128-1:0] H;reg [128-1:0] nxt_H;reg [128-1:0] EkY0;reg [128-1:0] nxt_EkY0;reg [128-1:0] Yi;reg [128-1:0] Yi_init;
  reg [128-1:0] gfm_result;
  reg [63:0] enc_byte_cnt;reg [63:0] aad_byte_cnt;
  reg nxt_Out_vld;reg nxt_Tag_vld;
  reg [128-1:0] dii_data_star;reg [128-1:0] nxt_Out_data_star;
  reg [128-1:0] nxt_Out_data;reg [128-1:0] nxt_Tag_data;
  reg [128-1:0] aes_text_in;
  reg aes_kld;
  wire aes_done;
  wire [128-1:0] aes_text_out;
  reg mux_aes_text_in_sel;reg mux_yi_sel;
  reg [128-1:0] v_in;reg [128-1:0] z_in;reg [128-1:0] b_in;reg [128-1:0] gfm_input1;
  wire [128-1:0] z_out;wire [128-1:0] v_out;
  reg [3:0] gfm_cnt;
  reg we_y;reg we_lenA;reg we_lenC;reg start_gfm_cnt;
  reg [9:0] state;reg [9:0] nxt_state;
  parameter IDLE = 10'd1;parameter ENCRYPT_0 = 10'd2;parameter INIT_COUNTER = 10'd4;parameter ENCRYPT_Y0 = 10'd8;parameter DATA_ACCEPT = 10'd16;parameter GFM_MULT = 10'd32;parameter INC_COUNTER = 10'd64;parameter M_ENCRYPT = 10'd128;parameter PRE_TAG_CALC = 10'd256;parameter TAG_CALC = 10'd512;

  always @(*) begin
    dii_data_star = 0;
    case(dii_data_size)
      0: begin
        dii_data_star = { dii_data[7:0], 120'b0 };
      end
      1: begin
        dii_data_star = { dii_data[15:0], 112'b0 };
      end
      2: begin
        dii_data_star = { dii_data[23:0], 104'b0 };
      end
      3: begin
        dii_data_star = { dii_data[31:0], 96'b0 };
      end
      4: begin
        dii_data_star = { dii_data[39:0], 88'b0 };
      end
      5: begin
        dii_data_star = { dii_data[47:0], 80'b0 };
      end
      6: begin
        dii_data_star = { dii_data[55:0], 72'b0 };
      end
      7: begin
        dii_data_star = { dii_data[63:0], 64'b0 };
      end
      8: begin
        dii_data_star = { dii_data[71:0], 56'b0 };
      end
      9: begin
        dii_data_star = { dii_data[79:0], 48'b0 };
      end
      10: begin
        dii_data_star = { dii_data[87:0], 40'b0 };
      end
      11: begin
        dii_data_star = { dii_data[95:0], 32'b0 };
      end
      12: begin
        dii_data_star = { dii_data[103:0], 24'b0 };
      end
      13: begin
        dii_data_star = { dii_data[111:0], 16'b0 };
      end
      14: begin
        dii_data_star = { dii_data[119:0], 8'b0 };
      end
    endcase
  end


  always @(*) begin
    nxt_Out_data_star = 0;
    case(dii_data_size)
      0: begin
        nxt_Out_data_star = { nxt_Out_data[127:120], 120'b0 };
      end
      1: begin
        nxt_Out_data_star = { nxt_Out_data[127:112], 112'b0 };
      end
      2: begin
        nxt_Out_data_star = { nxt_Out_data[127:104], 104'b0 };
      end
      3: begin
        nxt_Out_data_star = { nxt_Out_data[127:96], 96'b0 };
      end
      4: begin
        nxt_Out_data_star = { nxt_Out_data[127:88], 88'b0 };
      end
      5: begin
        nxt_Out_data_star = { nxt_Out_data[127:80], 80'b0 };
      end
      6: begin
        nxt_Out_data_star = { nxt_Out_data[127:72], 72'b0 };
      end
      7: begin
        nxt_Out_data_star = { nxt_Out_data[127:64], 64'b0 };
      end
      8: begin
        nxt_Out_data_star = { nxt_Out_data[127:56], 56'b0 };
      end
      9: begin
        nxt_Out_data_star = { nxt_Out_data[127:48], 48'b0 };
      end
      10: begin
        nxt_Out_data_star = { nxt_Out_data[127:40], 40'b0 };
      end
      11: begin
        nxt_Out_data_star = { nxt_Out_data[127:32], 32'b0 };
      end
      12: begin
        nxt_Out_data_star = { nxt_Out_data[127:24], 24'b0 };
      end
      13: begin
        nxt_Out_data_star = { nxt_Out_data[127:16], 16'b0 };
      end
      14: begin
        nxt_Out_data_star = { nxt_Out_data[127:8], 8'b0 };
      end
    endcase
  end


  always @(posedge clk or posedge rst) if(rst) begin
    state <= #1 IDLE;
    H <= #1 0;
    EkY0 <= #1 0;
  end else begin
    H <= #1 nxt_H;
    EkY0 <= #1 nxt_EkY0;
    state <= #1 nxt_state;
  end


  always @(posedge clk) begin
    if(nxt_Out_vld & ~nxt_Tag_vld) begin
      Out_data <= #1 nxt_Out_data;
      Out_data_size <= #1 dii_data_size;
      Out_last_word <= #1 dii_last_word;
    end else if(nxt_Tag_vld) Out_data <= #1 nxt_Tag_data; 
    Tag_vld <= #1 nxt_Tag_vld;
    Out_vld <= #1 nxt_Out_vld;
  end


  always @(*) begin
    aes_text_in = 0;
    case(mux_aes_text_in_sel)
      0: aes_text_in = 0;
      1: aes_text_in = Yi;
    endcase
  end


  always @(*) begin
    Yi_init = 0;
    if(cii_IV_vld) begin
      Yi_init = dii_data;
    end 
  end


  always @(*) begin
    nxt_state = state;
    we_y = 0;
    we_lenA = 0;
    we_lenC = 0;
    dii_data_not_ready = 1;
    aes_kld = 0;
    mux_aes_text_in_sel = 0;
    mux_yi_sel = 0;
    start_gfm_cnt = 0;
    nxt_H = H;
    nxt_EkY0 = EkY0;
    nxt_Out_vld = 0;
    nxt_Tag_vld = 1;
    gfm_input1 = 0;
    nxt_Out_data = 0;
    nxt_Tag_data = 0;
    case(state)
      IDLE: begin
        if(cii_ctl_vld) begin
          aes_kld = 1;
          mux_aes_text_in_sel = 0;
          nxt_state = ENCRYPT_0;
        end 
      end
      ENCRYPT_0: begin
        if(aes_done) begin
          nxt_H = aes_text_out;
          if(cii_IV_vld) begin
            we_y = 1;
            nxt_state = INIT_COUNTER;
          end 
        end 
      end
      INIT_COUNTER: begin
        mux_aes_text_in_sel = 1;
        aes_kld = 1;
        nxt_state = ENCRYPT_Y0;
      end
      ENCRYPT_Y0: begin
        if(aes_done) begin
          nxt_EkY0 = aes_text_out;
          nxt_state = DATA_ACCEPT;
        end 
      end
      DATA_ACCEPT: begin
        dii_data_not_ready = 0;
        if(dii_data_vld & dii_data_type) begin
          if(dii_data_size == 4'd15) begin
            we_lenA = 1;
            gfm_input1 = dii_data;
            start_gfm_cnt = 1;
            nxt_state = GFM_MULT;
          end else begin
            we_lenA = 1;
            gfm_input1 = dii_data_star;
            start_gfm_cnt = 1;
            nxt_state = GFM_MULT;
          end
        end else if(dii_data_vld & ~dii_data_type) begin
          mux_yi_sel = 1;
          we_y = 1;
          nxt_state = INC_COUNTER;
        end 
      end
      INC_COUNTER: begin
        we_lenC = 1;
        mux_aes_text_in_sel = 1;
        aes_kld = 1;
        nxt_state = M_ENCRYPT;
      end
      GFM_MULT: begin
        if(gfm_cnt == 4'd7) begin
          start_gfm_cnt = 0;
          if(~dii_last_word) nxt_state = DATA_ACCEPT; 
          else nxt_state = PRE_TAG_CALC;
        end 
      end
      M_ENCRYPT: begin
        if(aes_done) begin
          if(dii_data_size == 4'd15) begin
            nxt_Out_data = aes_text_out ^ dii_data;
            nxt_Out_vld = 1;
            gfm_input1 = nxt_Out_data;
          end else begin
            nxt_Out_data = aes_text_out ^ dii_data_star;
            nxt_Out_vld = 1;
            gfm_input1 = nxt_Out_data_star;
          end
          start_gfm_cnt = 1;
          nxt_state = GFM_MULT;
        end 
      end
      PRE_TAG_CALC: begin
        gfm_input1 = { aad_byte_cnt << 3, enc_byte_cnt << 3 };
        start_gfm_cnt = 1;
        nxt_state = TAG_CALC;
      end
      TAG_CALC: begin
        if(gfm_cnt == 4'd7) begin
          start_gfm_cnt = 0;
          nxt_Tag_data = EkY0 ^ z_out;
          nxt_Tag_vld = 1'b1;
          nxt_state = IDLE;
        end 
      end
    endcase
  end


  always @(posedge clk) if(we_y) case(mux_yi_sel)
    0: Yi <= #1 Yi_init;
    1: Yi <= #1 Yi + 1;
  endcase 


  always @(posedge clk or posedge rst) if(rst) enc_byte_cnt <= #1 0; 
  else if(we_lenC) enc_byte_cnt <= #1 enc_byte_cnt + dii_data_size + 1; 


  always @(posedge clk or posedge rst) if(rst) aad_byte_cnt <= #1 0; 
  else if(we_lenA) aad_byte_cnt <= #1 aad_byte_cnt + dii_data_size + 1; 


  always @(posedge clk) if(start_gfm_cnt) gfm_cnt <= #1 4'd0; 
  else if(gfm_cnt != 4'd7) gfm_cnt <= #1 gfm_cnt + 1; 


  always @(posedge clk) if(cii_ctl_vld) gfm_result <= #1 0; 
  else if(gfm_cnt == 4'd7) gfm_result <= #1 z_out; 


  always @(posedge clk) if(start_gfm_cnt) begin
    v_in <= #1 H;
    z_in <= #1 { 128{ 1'b0 } };
    b_in <= #1 gfm_input1 ^ gfm_result;
  end else begin
    v_in <= #1 v_out;
    z_in <= #1 z_out;
    b_in <= #1 b_in << 16;
  end


  gfm128_16
  GFM
  (
    .v_out(v_out[127:0]),
    .z_out(z_out[127:0]),
    .v_in(v_in[127:0]),
    .z_in(z_in[127:0]),
    .b_in(b_in[127:112])
  );


  aes_cipher_top
  AES_ENC
  (
    .done(aes_done),
    .text_out(aes_text_out[127:0]),
    .clk(clk),
    .rst(rst),
    .ld(aes_kld),
    .key(cii_K),
    .text_in(aes_text_in[127:0])
  );


endmodule

