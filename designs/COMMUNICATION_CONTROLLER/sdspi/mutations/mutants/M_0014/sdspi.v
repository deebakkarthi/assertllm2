

module sdspi
(
  i_clk,
  i_wb_cyc,
  i_wb_stb,
  i_wb_we,
  i_wb_addr,
  i_wb_data,
  o_wb_ack,
  o_wb_stall,
  o_wb_data,
  o_cs_n,
  o_sck,
  o_mosi,
  i_miso,
  o_int,
  i_bus_grant,
  o_debug
);

  parameter LGFIFOLN = 7;
  input i_clk;wire i_clk;
  input i_wb_cyc;wire i_wb_cyc;input i_wb_stb;wire i_wb_stb;input i_wb_we;wire i_wb_we;
  input [1:0] i_wb_addr;wire [1:0] i_wb_addr;
  input [31:0] i_wb_data;wire [31:0] i_wb_data;
  output o_wb_ack;reg o_wb_ack;
  output o_wb_stall;wire o_wb_stall;
  output [31:0] o_wb_data;reg [31:0] o_wb_data;
  output o_cs_n;wire o_cs_n;output o_sck;wire o_sck;output o_mosi;wire o_mosi;
  input i_miso;wire i_miso;
  output o_int;reg o_int;
  input i_bus_grant;wire i_bus_grant;
  output [31:0] o_debug;wire [31:0] o_debug;
  reg r_cmd_busy;
  wire wb_stb;wire write_stb;wire cmd_stb;wire new_data;wire new_cmd;
  wire [1:0] wb_addr;
  wire [31:0] wb_data;
  reg r_wb_stb;reg r_write_stb;reg r_cmd_stb;reg r_new_data;
  reg [1:0] r_wb_addr;
  reg [31:0] r_wb_data;

  always @(posedge i_clk) r_wb_stb <= i_wb_stb && !o_wb_stall;


  always @(posedge i_clk) r_write_stb <= i_wb_stb && !o_wb_stall && i_wb_we;


  always @(posedge i_clk) r_cmd_stb <= !r_cmd_busy && i_wb_stb && !o_wb_stall && i_wb_we && (i_wb_addr == 2'h1);


  always @(posedge i_clk) r_new_data <= i_wb_stb && !o_wb_stall && i_wb_we && (i_wb_addr == 2'h1);


  always @(posedge i_clk) r_wb_addr <= i_wb_addr;


  always @(posedge i_clk) r_wb_data <= i_wb_data;

  assign wb_stb = r_wb_stb;
  assign write_stb = r_write_stb;
  assign cmd_stb = r_cmd_stb;
  assign new_cmd = r_cmd_stb;
  assign new_data = r_new_data;
  assign wb_addr = r_wb_addr;
  assign wb_data = r_wb_data;
  reg [6:0] r_sdspi_clk;
  reg ll_cmd_stb;
  reg [7:0] ll_cmd_dat;
  wire ll_out_stb;wire ll_idle;
  wire [7:0] ll_out_dat;

  llsdspi
  lowlevel
  (
    i_clk,
    r_sdspi_clk,
    r_cmd_busy,
    ll_cmd_stb,
    ll_cmd_dat,
    o_cs_n,
    o_sck,
    o_mosi,
    i_miso,
    ll_out_stb,
    ll_out_dat,
    ll_idle,
    i_bus_grant
  );

  reg r_cmd_crc_stb;
  wire [7:0] cmd_crc;
  reg [2:0] r_cmd_state;reg [2:0] r_rsp_state;
  reg r_have_resp;reg r_use_fifo;reg r_fifo_wr;reg ll_fifo_rd_complete;reg ll_fifo_wr_complete;reg r_fifo_id;reg ll_fifo_wr;reg ll_fifo_rd;reg r_have_data_response_token;reg r_have_start_token;reg r_err_token;
  reg [3:0] r_read_err_token;
  reg [1:0] r_data_response_token;
  reg [7:0] fifo_byte;
  reg [7:0] r_last_r_one;
  reg [31:0] r_data_reg;
  reg [1:0] r_data_fil;reg [1:0] r_cmd_resp;
  wire need_reset;
  reg r_cmd_err;
  reg r_cmd_sent;
  reg [31:0] fifo_a_reg;reg [31:0] fifo_b_reg;
  reg q_busy;
  reg [7:0] fifo_a_mem_0 [0:(1<<LGFIFOLN)-1];reg [7:0] fifo_a_mem_1 [0:(1<<LGFIFOLN)-1];reg [7:0] fifo_a_mem_2 [0:(1<<LGFIFOLN)-1];reg [7:0] fifo_a_mem_3 [0:(1<<LGFIFOLN)-1];reg [7:0] fifo_b_mem_0 [0:(1<<LGFIFOLN)-1];reg [7:0] fifo_b_mem_1 [0:(1<<LGFIFOLN)-1];reg [7:0] fifo_b_mem_2 [0:(1<<LGFIFOLN)-1];reg [7:0] fifo_b_mem_3 [0:(1<<LGFIFOLN)-1];
  reg [LGFIFOLN-1:0] fifo_wb_addr;
  reg [LGFIFOLN+1:0] ll_fifo_addr;
  reg fifo_crc_err;
  reg [1:0] ll_fifo_wr_state;
  reg [7:0] fifo_a_byte;reg [7:0] fifo_b_byte;
  reg [2:0] ll_fifo_pkt_state;
  reg fifo_rd_crc_stb;reg fifo_wr_crc_stb;
  reg [3:0] fifo_rd_crc_count;reg [3:0] fifo_wr_crc_count;
  reg [15:0] fifo_rd_crc_reg;reg [15:0] fifo_wr_crc_reg;
  reg [3:0] r_cmd_crc_cnt;
  reg [7:0] r_cmd_crc;
  reg r_cmd_crc_ff;
  reg [3:0] r_lgblklen;
  wire [3:0] max_lgblklen;
  assign max_lgblklen = LGFIFOLN;
  reg [25:0] r_watchdog;
  reg r_watchdog_err;
  reg pre_cmd_state;

  initial r_cmd_busy = 1'b0;


  initial r_data_reg = 32'h00;


  initial r_last_r_one = 8'hff;


  initial ll_cmd_stb = 1'b0;


  initial ll_fifo_rd = 1'b0;


  initial ll_fifo_wr = 1'b0;


  initial r_rsp_state = 3'h0;


  initial r_cmd_state = 3'h0;


  initial r_use_fifo = 1'b0;


  initial r_data_fil = 2'b00;


  initial r_lgblklen = LGFIFOLN;


  initial r_cmd_err = 1'b0;


  always @(posedge i_clk) begin
    if(!ll_cmd_stb) begin
      r_have_resp <= 1'b0;
      ll_fifo_wr <= 1'b0;
      ll_fifo_rd <= 1'b0;
      r_cmd_state <= 3'h0;
      r_use_fifo <= 1'b0;
      r_data_fil <= 2'b00;
      r_cmd_resp <= 2'b00;
    end 
    r_cmd_crc_stb <= 1'b0;
    if(pre_cmd_state) begin
      if(r_cmd_state == 3'h0) begin
        r_cmd_state <= r_cmd_state + 3'h1;
        ll_cmd_dat <= r_data_reg[31:24];
        r_cmd_crc_stb <= 1'b1;
      end else if(r_cmd_state == 3'h1) begin
        r_cmd_state <= r_cmd_state + 3'h1;
        ll_cmd_dat <= r_data_reg[23:16];
        r_cmd_crc_stb <= 1'b1;
      end else if(r_cmd_state == 3'h2) begin
        r_cmd_state <= r_cmd_state + 3'h1;
        ll_cmd_dat <= r_data_reg[15:8];
        r_cmd_crc_stb <= 1'b1;
      end else if(r_cmd_state == 3'h3) begin
        r_cmd_state <= r_cmd_state + 3'h1;
        ll_cmd_dat <= r_data_reg[7:0];
        r_cmd_crc_stb <= 1'b1;
      end else if(r_cmd_state == 3'h4) begin
        r_cmd_state <= r_cmd_state + 3'h1;
        ll_cmd_dat <= cmd_crc;
      end else if(r_cmd_state == 3'h5) begin
        ll_cmd_dat <= 8'hff;
        if(r_have_resp) begin
          if(r_use_fifo) r_cmd_state <= r_cmd_state + 3'h1; 
          else r_cmd_state <= r_cmd_state + 3'h2;
          ll_fifo_rd <= r_use_fifo && r_fifo_wr;
          if(r_use_fifo && r_fifo_wr) ll_cmd_dat <= 8'hfe; 
        end 
      end else if(r_cmd_state == 3'h6) begin
        ll_cmd_dat <= 8'hff;
        if(ll_fifo_rd_complete) begin
          r_cmd_state <= r_cmd_state + 3'h1;
          ll_fifo_rd <= 1'b0;
        end else if(ll_fifo_rd) ll_cmd_dat <= fifo_byte; 
      end else ll_cmd_dat <= 8'hff;
      if(pre_rsp_state) begin
        case(r_rsp_state)
          3'h0: begin
            if(!ll_out_dat[7]) begin
              r_last_r_one <= ll_out_dat;
              if(r_cmd_resp == 2'b00) begin
                r_have_resp <= 1'b1;
                ll_cmd_stb <= r_use_fifo;
                r_data_reg <= 32'hffffffff;
                ll_fifo_wr <= r_use_fifo && !r_fifo_wr;
              end else if(r_cmd_resp == 2'b01) begin
                r_data_reg <= 32'hffffffff;
              end 
            end 
          end
          3'h1: begin
            if(nonzero_out) r_have_resp <= 1'b1; 
            ll_cmd_stb <= r_use_fifo;
          end
          3'h2: begin
            r_data_reg <= { r_data_reg[23:0], ll_out_dat };
            r_data_fil <= r_data_fil + 2'b01;
            if(r_data_fil == 2'b11) begin
              ll_cmd_stb <= r_use_fifo;
            end 
          end
          3'h5: begin
          end
          3'h6: begin
            ll_cmd_stb <= 1'b0;
          end
          3'h7: begin
            if(ll_fifo_wr_complete || r_read_err_token[0]) begin
              ll_fifo_wr <= 1'b0;
              ll_cmd_stb <= 1'b0;
            end 
          end
          default: begin
          end
        endcase
      end 
      if(r_use_fifo && ll_out_stb) r_data_reg <= { 26'h3ffffff, r_data_response_token, r_read_err_token }; 
      if(r_watchdog_err) ll_cmd_stb <= 1'b0; 
      r_cmd_err <= r_cmd_err | fifo_crc_err | r_watchdog_err | r_err_token;
    end else if(r_cmd_busy) begin
      r_cmd_busy <= ll_cmd_stb || !ll_idle;
    end else if(new_cmd) begin
      r_cmd_err <= r_cmd_err && !wb_data[15];
      r_fifo_id <= wb_data[12];
      ll_cmd_dat <= wb_data[7:0];
      if(wb_data[7:6] == 2'b01) begin
        r_cmd_busy <= 1'b1;
        ll_cmd_stb <= 1'b1;
        r_cmd_resp <= wb_data[9:8];
        r_cmd_crc_stb <= 1'b1;
        r_fifo_wr <= wb_data[10];
        r_use_fifo <= wb_data[11];
      end else if(wb_data[7]) r_data_reg <= { 8'h00, 4'h0, max_lgblklen, 4'h0, r_lgblklen, 1'b0, r_sdspi_clk }; 
    end else if(new_data) r_data_reg <= wb_data; 
  end


  always @(posedge i_clk) pre_cmd_state <= ll_cmd_stb && ll_idle;

  reg ready_for_response_token;

  always @(posedge i_clk) if(!r_cmd_busy) ready_for_response_token <= 1'b0; 
  else if(ll_fifo_rd) ready_for_response_token <= 1'b1; 


  always @(posedge i_clk) if(!r_cmd_busy) r_have_data_response_token <= 1'b0; 
  else if(ll_out_stb && ready_for_response_token && !ll_out_dat[4]) r_have_data_response_token <= 1'b1; 

  reg [2:0] second_rsp_state;

  always @(posedge i_clk) if((r_cmd_resp == 2'b00) && r_use_fifo && r_fifo_wr) second_rsp_state <= 3'h4; 
  else if(r_cmd_resp == 2'b00) second_rsp_state <= 3'h7; 
  else if(r_cmd_resp == 2'b01) second_rsp_state <= 3'h1; 
  else second_rsp_state <= 3'h2;

  reg pre_rsp_state;reg nonzero_out;

  always @(posedge i_clk) if(ll_out_stb) nonzero_out <= |ll_out_dat; 


  always @(posedge i_clk) pre_rsp_state <= ll_out_stb && r_cmd_sent;


  initial r_rsp_state = 3'h0;


  always @(posedge i_clk) if(!r_cmd_sent) r_rsp_state <= 3'h0; 
  else if(pre_rsp_state) begin
    if((r_rsp_state == 3'h0) && !ll_out_dat[7]) begin
      r_rsp_state <= second_rsp_state;
    end else if(r_rsp_state == 3'h1) begin
      if(nonzero_out) r_rsp_state <= 3'h6; 
    end else if(r_rsp_state == 3'h2) begin
      if(r_data_fil == 2'b11) r_rsp_state <= 3'h6; 
    end else if(r_rsp_state == 3'h4) begin
      if(r_have_data_response_token) r_rsp_state <= 3'h5; 
    end else if(r_rsp_state == 3'h5) begin
      if(nonzero_out) r_rsp_state <= 3'h6; 
    end 
  end 


  always @(posedge i_clk) r_cmd_sent <= ll_cmd_stb && (r_cmd_state >= 3'h5);


  initial r_sdspi_clk = 7'h63;


  always @(posedge i_clk) begin
    if(new_cmd && (wb_data[7:6] == 2'b11) && !r_data_reg[7] && (r_data_reg[15:12] == 4'h00)) begin
      if(|r_data_reg[6:0]) r_sdspi_clk <= r_data_reg[6:0]; 
      if(|r_data_reg[11:8]) r_lgblklen <= r_data_reg[11:8]; 
    end 
    if(r_lgblklen > max_lgblklen) r_lgblklen <= max_lgblklen; 
  end

  assign need_reset = 1'b0;

  always @(posedge i_clk) case(wb_addr)
    2'h0: o_wb_data <= { need_reset, 11'h00, 2'h0, r_err_token, fifo_crc_err, r_cmd_err, r_cmd_busy, 1'b0, r_fifo_id, r_use_fifo, r_fifo_wr, r_cmd_resp, r_last_r_one };
    2'h1: o_wb_data <= r_data_reg;
    2'h2: o_wb_data <= fifo_a_reg;
    2'h3: o_wb_data <= fifo_b_reg;
  endcase


  always @(posedge i_clk) o_wb_ack <= wb_stb;


  initial q_busy = 1'b1;


  always @(posedge i_clk) q_busy <= r_cmd_busy;


  always @(posedge i_clk) o_int <= !r_cmd_busy && q_busy;

  assign o_wb_stall = 1'b0;

  always @(posedge i_clk) begin
    if(write_stb && (wb_addr == 2'h0)) begin
      fifo_wb_addr <= { LGFIFOLN{ 1'b0 } };
    end else if(wb_stb && wb_addr[1]) begin
      fifo_wb_addr <= fifo_wb_addr + 1;
    end 
  end


  always @(posedge i_clk) begin
    fifo_a_reg <= { fifo_a_mem_0[fifo_wb_addr], fifo_a_mem_1[fifo_wb_addr], fifo_a_mem_2[fifo_wb_addr], fifo_a_mem_3[fifo_wb_addr] };
    fifo_b_reg <= { fifo_b_mem_0[fifo_wb_addr], fifo_b_mem_1[fifo_wb_addr], fifo_b_mem_2[fifo_wb_addr], fifo_b_mem_3[fifo_wb_addr] };
  end

  reg pre_fifo_addr_inc_rd;
  reg pre_fifo_addr_inc_wr;

  initial pre_fifo_addr_inc_rd = 1'b0;


  initial pre_fifo_addr_inc_wr = 1'b0;


  always @(posedge i_clk) pre_fifo_addr_inc_wr <= ll_fifo_wr && ll_out_stb && r_have_start_token;


  always @(posedge i_clk) pre_fifo_addr_inc_rd <= ll_fifo_rd && ll_cmd_stb && ll_idle;


  always @(posedge i_clk) begin
    if(!r_cmd_busy) ll_fifo_addr <= { LGFIFOLN + 2{ 1'b0 } }; 
    else if(pre_fifo_addr_inc_wr || pre_fifo_addr_inc_rd) ll_fifo_addr <= ll_fifo_addr + 1; 
  end


  always @(posedge i_clk) if(!r_cmd_busy) r_have_start_token <= 1'b0; 
  else if(ll_fifo_wr && ll_out_stb && (ll_out_dat == 8'hfe)) r_have_start_token <= 1'b1; 


  always @(posedge i_clk) if(!r_cmd_busy) r_read_err_token <= 4'h0; 
  else if(ll_fifo_wr && ll_out_stb && !r_have_start_token && (ll_out_dat[7:4] == 4'h0)) r_read_err_token <= ll_out_dat[3:0]; 


  always @(posedge i_clk) if(!r_cmd_busy) r_data_response_token <= 2'b00; 
  else if(ready_for_response_token && !ll_out_dat[4] && ll_out_dat[0]) r_data_response_token <= ll_out_dat[3:2]; 


  initial r_err_token = 1'b0;


  always @(posedge i_clk) if(ll_fifo_rd) r_err_token <= r_err_token | r_read_err_token[0]; 
  else if(ll_fifo_wr) r_err_token <= r_err_token | (|r_data_response_token && r_data_response_token[1]); 
  else if(cmd_stb) r_err_token <= r_err_token && !i_wb_data[16] && !i_wb_data[15]; 

  reg last_fifo_byte;

  initial last_fifo_byte = 1'b0;


  always @(posedge i_clk) if(ll_fifo_wr) last_fifo_byte <= ll_fifo_addr == w_blklimit; 
  else last_fifo_byte <= 1'b0;

  reg pre_fifo_a_wr;reg pre_fifo_b_wr;reg pre_fifo_crc_a;reg pre_fifo_crc_b;reg clear_fifo_crc;

  always @(posedge i_clk) begin
    pre_fifo_a_wr <= ll_fifo_wr && ll_out_stb && !r_fifo_id && (ll_fifo_wr_state == 2'b00);
    pre_fifo_b_wr <= ll_fifo_wr && ll_out_stb && r_fifo_id && (ll_fifo_wr_state == 2'b00);
    fifo_wr_crc_stb <= ll_fifo_wr && ll_out_stb && (ll_fifo_wr_state == 2'b00) && r_have_start_token;
    pre_fifo_crc_a <= ll_fifo_wr && ll_out_stb && (ll_fifo_wr_state == 2'b01);
    pre_fifo_crc_b <= ll_fifo_wr && ll_out_stb && (ll_fifo_wr_state == 2'b10);
    clear_fifo_crc <= new_cmd && wb_data[15];
  end

  reg fifo_a_wr;reg fifo_b_wr;
  reg [3:0] fifo_a_wr_mask;reg [3:0] fifo_b_wr_mask;
  reg [LGFIFOLN-1:0] fifo_a_wr_addr;reg [LGFIFOLN-1:0] fifo_b_wr_addr;
  reg [31:0] fifo_a_wr_data;reg [31:0] fifo_b_wr_data;

  initial fifo_crc_err = 1'b0;


  always @(posedge i_clk) begin
    fifo_a_wr <= 1'b0;
    fifo_a_wr_data <= { ll_out_dat, ll_out_dat, ll_out_dat, ll_out_dat };
    if(write_stb && (wb_addr[1:0] == 2'b10)) begin
      fifo_a_wr <= 1'b1;
      fifo_a_wr_mask <= 4'b1111;
      fifo_a_wr_addr <= fifo_wb_addr;
      fifo_a_wr_data <= wb_data;
    end else if(pre_fifo_a_wr) begin
      fifo_a_wr <= 1'b1;
      fifo_a_wr_addr <= ll_fifo_addr[LGFIFOLN+1:2];
      case(ll_fifo_addr[1:0])
        2'b00: fifo_a_wr_mask <= 4'b0001;
        2'b01: fifo_a_wr_mask <= 4'b0010;
        2'b10: fifo_a_wr_mask <= 4'b0100;
        2'b11: fifo_a_wr_mask <= 4'b1000;
      endcase
    end 
    if(fifo_a_wr && fifo_a_wr_mask[0]) fifo_a_mem_0[fifo_a_wr_addr] <= fifo_a_wr_data[7:0]; 
    if(fifo_a_wr && fifo_a_wr_mask[1]) fifo_a_mem_1[fifo_a_wr_addr] <= fifo_a_wr_data[15:8]; 
    if(fifo_a_wr && fifo_a_wr_mask[2]) fifo_a_mem_2[fifo_a_wr_addr] <= fifo_a_wr_data[23:16]; 
    if(fifo_a_wr && fifo_a_wr_mask[3]) fifo_a_mem_3[fifo_a_wr_addr] <= fifo_a_wr_data[31:24]; 
    fifo_b_wr <= 1'b0;
    fifo_b_wr_data <= { ll_out_dat, ll_out_dat, ll_out_dat, ll_out_dat };
    if(write_stb && (wb_addr[1:0] == 2'b11)) begin
      fifo_b_wr <= 1'b1;
      fifo_b_wr_mask <= 4'b1111;
      fifo_b_wr_addr <= fifo_wb_addr;
      fifo_b_wr_data <= wb_data;
    end else if(pre_fifo_b_wr) begin
      fifo_b_wr <= 1'b1;
      fifo_b_wr_addr <= ll_fifo_addr[LGFIFOLN+1:2];
      case(ll_fifo_addr[1:0])
        2'b00: fifo_b_wr_mask <= 4'b0001;
        2'b01: fifo_b_wr_mask <= 4'b0010;
        2'b10: fifo_b_wr_mask <= 4'b0100;
        2'b11: fifo_b_wr_mask <= 4'b1000;
      endcase
    end 
    if(fifo_b_wr && fifo_b_wr_mask[0]) fifo_b_mem_0[fifo_b_wr_addr] <= fifo_b_wr_data[7:0]; 
    if(fifo_b_wr && fifo_b_wr_mask[1]) fifo_b_mem_1[fifo_b_wr_addr] <= fifo_b_wr_data[15:8]; 
    if(fifo_b_wr && fifo_b_wr_mask[2]) fifo_b_mem_2[fifo_b_wr_addr] <= fifo_b_wr_data[23:16]; 
    if(fifo_b_wr && fifo_b_wr_mask[3]) fifo_b_mem_3[fifo_b_wr_addr] <= fifo_b_wr_data[31:24]; 
    if(!r_cmd_busy) ll_fifo_wr_complete <= 1'b0; 
    if(!r_cmd_busy) ll_fifo_wr_state <= 2'b00; 
    else if(pre_fifo_a_wr || pre_fifo_b_wr) ll_fifo_wr_state <= (last_fifo_byte)? 2'b01 : 2'b00; 
    if(pre_fifo_crc_a) begin
      fifo_crc_err <= fifo_crc_err | (fifo_wr_crc_reg[15:8] != ll_out_dat);
      ll_fifo_wr_state <= ll_fifo_wr_state + 2'b01;
    end 
    if(pre_fifo_crc_b) begin
      fifo_crc_err <= fifo_crc_err | (fifo_wr_crc_reg[7:0] != ll_out_dat);
      ll_fifo_wr_state <= ll_fifo_wr_state + 2'b01;
      ll_fifo_wr_complete <= 1'b1;
    end else if(clear_fifo_crc) fifo_crc_err <= 1'b0; 
  end


  always @(posedge i_clk) begin
    case(ll_fifo_addr[1:0])
      2'b00: begin
        fifo_a_byte <= fifo_a_mem_0[ll_fifo_addr[LGFIFOLN+1:2]];
        fifo_b_byte <= fifo_b_mem_0[ll_fifo_addr[LGFIFOLN+1:2]];
      end
      2'b01: begin
        fifo_a_byte <= fifo_a_mem_1[ll_fifo_addr[LGFIFOLN+1:2]];
        fifo_b_byte <= fifo_b_mem_1[ll_fifo_addr[LGFIFOLN+1:2]];
      end
      2'b10: begin
        fifo_a_byte <= fifo_a_mem_2[ll_fifo_addr[LGFIFOLN+1:2]];
        fifo_b_byte <= fifo_b_mem_2[ll_fifo_addr[LGFIFOLN+1:2]];
      end
      2'b11: begin
        fifo_a_byte <= fifo_a_mem_3[ll_fifo_addr[LGFIFOLN+1:2]];
        fifo_b_byte <= fifo_b_mem_3[ll_fifo_addr[LGFIFOLN+1:2]];
      end
    endcase
  end

  reg [LGFIFOLN-1:0] r_blklimit;
  wire [LGFIFOLN+1:0] w_blklimit;

  always @(posedge i_clk) r_blklimit[LGFIFOLN-1:0] <= (1 << r_lgblklen) - 1;

  assign w_blklimit = { r_blklimit, 2'b11 };

  always @(posedge i_clk) begin
    fifo_rd_crc_stb <= 1'b0;
    if(r_cmd_busy) begin
      if(ll_fifo_pkt_state[2:0] == 3'b000) begin
        if(ll_fifo_rd && ll_cmd_stb && ll_idle) begin
          ll_fifo_pkt_state <= ll_fifo_pkt_state + 3'b001;
        end 
      end else if(ll_fifo_pkt_state[2:0] == 3'b001) begin
        if(ll_fifo_rd && ll_cmd_stb && ll_idle) begin
          ll_fifo_pkt_state <= ll_fifo_pkt_state + 3'b001;
          fifo_byte <= (r_fifo_id)? fifo_b_byte : fifo_a_byte;
          fifo_rd_crc_stb <= 1'b1;
        end 
      end else if(ll_fifo_pkt_state[2:0] == 3'b010) begin
        if(ll_fifo_rd && ll_cmd_stb && ll_idle) begin
          fifo_byte <= (r_fifo_id)? fifo_b_byte : fifo_a_byte;
          fifo_rd_crc_stb <= 1'b1;
        end 
        if(ll_fifo_addr == 0) ll_fifo_pkt_state <= 3'b011; 
      end else if(ll_fifo_pkt_state == 3'b011) begin
        if(ll_fifo_rd && ll_cmd_stb && ll_idle) begin
          fifo_byte <= fifo_rd_crc_reg[15:8];
          ll_fifo_pkt_state <= 3'b100;
        end 
      end else if(ll_fifo_pkt_state == 3'b100) begin
        if(ll_fifo_rd && ll_cmd_stb && ll_idle) begin
          fifo_byte <= fifo_rd_crc_reg[7:0];
          ll_fifo_pkt_state <= 3'b101;
        end 
      end else if(ll_fifo_rd && ll_cmd_stb && ll_idle) begin
        ll_fifo_rd_complete <= 1'b1;
        fifo_byte <= 8'hff;
      end 
    end else if(write_stb && (wb_addr == 2'h0)) begin
      ll_fifo_pkt_state <= 3'h0;
      ll_fifo_rd_complete <= 1'b0;
      fifo_byte <= (wb_data[12])? fifo_b_byte : fifo_a_byte;
      fifo_rd_crc_stb <= 1'b1;
    end else begin
      ll_fifo_pkt_state <= 3'b111;
      ll_fifo_rd_complete <= 1'b1;
    end
  end


  always @(posedge i_clk) begin
    if(!ll_fifo_wr) fifo_wr_crc_reg <= 16'h00; 
    else if(fifo_wr_crc_stb) begin
      fifo_wr_crc_reg[15:8] <= fifo_wr_crc_reg[15:8] ^ ll_out_dat;
      fifo_wr_crc_count <= 4'h8;
    end else if(|fifo_wr_crc_count) begin
      fifo_wr_crc_count <= fifo_wr_crc_count - 4'h1;
      if(fifo_wr_crc_reg[15]) fifo_wr_crc_reg <= { fifo_wr_crc_reg[14:0], 1'b0 } ^ 16'h1021; 
      else fifo_wr_crc_reg <= { fifo_wr_crc_reg[14:0], 1'b0 };
    end 
  end


  always @(posedge i_clk) begin
    if(!r_cmd_busy) begin
      fifo_rd_crc_reg <= 16'h00;
      fifo_rd_crc_count <= 4'h0;
    end else if(fifo_rd_crc_stb) begin
      fifo_rd_crc_reg[15:8] <= fifo_rd_crc_reg[15:8] ^ fifo_byte;
      fifo_rd_crc_count <= 4'h8;
    end else if(|fifo_rd_crc_count) begin
      fifo_rd_crc_count <= fifo_rd_crc_count - 4'h1;
      if(fifo_rd_crc_reg[15]) fifo_rd_crc_reg <= { fifo_rd_crc_reg[14:0], 1'b0 } ^ 16'h1021; 
      else fifo_rd_crc_reg <= { fifo_rd_crc_reg[14:0], 1'b0 };
    end 
  end


  initial r_cmd_crc_ff = 1'b0;


  always @(posedge i_clk) begin
    if(!r_cmd_busy) begin
      r_cmd_crc <= 8'h00;
      r_cmd_crc_cnt <= 4'hf;
      r_cmd_crc_ff <= 1'b0;
    end else if(!r_cmd_crc_cnt[3]) begin
      r_cmd_crc_cnt <= r_cmd_crc_cnt - 4'h1;
      if(r_cmd_crc[7]) r_cmd_crc <= { r_cmd_crc[6:0], 1'b0 } ^ 8'h12; 
      else r_cmd_crc <= { r_cmd_crc[6:0], 1'b0 };
      r_cmd_crc_ff <= r_cmd_crc_ff || r_cmd_crc_stb;
    end else if(r_cmd_crc_stb || r_cmd_crc_ff) begin
      r_cmd_crc <= r_cmd_crc ^ ll_cmd_dat;
      r_cmd_crc_cnt <= 4'h7;
      r_cmd_crc_ff <= 1'b0;
    end 
  end

  assign cmd_crc = { r_cmd_crc[7:1], 1'b1 };

  initial r_watchdog = 26'h3ffffff;


  initial r_watchdog_err = 1'b0;


  always @(posedge i_clk) if(!r_cmd_busy) r_watchdog_err <= 1'b0; 
  else if(r_watchdog == 0) r_watchdog_err <= 1'b1; 


  always @(posedge i_clk) if(!r_cmd_busy) r_watchdog <= 26'h3fffff; 
  else if(|r_watchdog) r_watchdog <= r_watchdog - 26'h1; 

  assign o_debug = { ll_cmd_stb && ll_idle || ll_out_stb, ll_cmd_stb, ll_idle, ll_out_stb, o_cs_n, o_sck, o_mosi, i_miso, r_cmd_state, i_bus_grant, r_rsp_state, r_cmd_busy, ll_cmd_dat, ll_out_dat };
  wire unused;
  assign unused = i_wb_cyc;

endmodule

