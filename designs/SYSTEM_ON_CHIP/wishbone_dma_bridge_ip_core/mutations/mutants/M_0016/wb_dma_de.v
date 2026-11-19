

module wb_dma_de
(
  clk,
  rst,
  mast0_go,
  mast0_we,
  mast0_adr,
  mast0_din,
  mast0_dout,
  mast0_err,
  mast0_drdy,
  mast0_wait,
  mast1_go,
  mast1_we,
  mast1_adr,
  mast1_din,
  mast1_dout,
  mast1_err,
  mast1_drdy,
  mast1_wait,
  de_start,
  nd,
  csr,
  pointer,
  pointer_s,
  txsz,
  adr0,
  adr1,
  am0,
  am1,
  de_csr_we,
  de_txsz_we,
  de_adr0_we,
  de_adr1_we,
  ptr_set,
  de_csr,
  de_txsz,
  de_adr0,
  de_adr1,
  de_fetch_descr,
  next_ch,
  de_ack,
  pause_req,
  paused,
  dma_abort,
  dma_busy,
  dma_err,
  dma_done,
  dma_done_all
);

  input clk;input rst;
  output mast0_go;
  output mast0_we;
  output [31:0] mast0_adr;
  input [31:0] mast0_din;
  output [31:0] mast0_dout;
  input mast0_err;
  input mast0_drdy;
  output mast0_wait;
  output mast1_go;
  output mast1_we;
  output [31:0] mast1_adr;
  input [31:0] mast1_din;
  output [31:0] mast1_dout;
  input mast1_err;
  input mast1_drdy;
  output mast1_wait;
  input de_start;
  input nd;
  input [31:0] csr;
  input [31:0] pointer;
  input [31:0] pointer_s;
  input [31:0] txsz;
  input [31:0] adr0;input [31:0] adr1;
  input [31:0] am0;input [31:0] am1;
  output de_csr_we;
  output de_txsz_we;
  output de_adr0_we;
  output de_adr1_we;
  output ptr_set;
  output [31:0] de_csr;
  output [11:0] de_txsz;
  output [31:0] de_adr0;
  output [31:0] de_adr1;
  output de_fetch_descr;
  output next_ch;
  output de_ack;
  input dma_abort;
  input pause_req;
  output paused;
  output dma_busy;output dma_err;output dma_done;output dma_done_all;
  parameter [10:0] IDLE = 11'b000_0000_0001;parameter [10:0] READ = 11'b000_0000_0010;parameter [10:0] WRITE = 11'b000_0000_0100;parameter [10:0] UPDATE = 11'b000_0000_1000;parameter [10:0] LD_DESC1 = 11'b000_0001_0000;parameter [10:0] LD_DESC2 = 11'b000_0010_0000;parameter [10:0] LD_DESC3 = 11'b000_0100_0000;parameter [10:0] LD_DESC4 = 11'b000_1000_0000;parameter [10:0] LD_DESC5 = 11'b001_0000_0000;parameter [10:0] WB = 11'b010_0000_0000;parameter [10:0] PAUSE = 11'b100_0000_0000;
  reg [10:0] state;reg [10:0] next_state;
  reg [31:0] mast0_adr;reg [31:0] mast1_adr;
  reg [29:0] adr0_cnt;reg [29:0] adr1_cnt;
  wire [29:0] adr0_cnt_next;wire [29:0] adr1_cnt_next;
  wire [29:0] adr0_cnt_next1;wire [29:0] adr1_cnt_next1;
  reg adr0_inc;reg adr1_inc;
  reg [8:0] chunk_cnt;
  reg chunk_dec;
  reg [11:0] tsz_cnt;
  reg tsz_dec;
  reg de_txsz_we;
  reg de_csr_we;
  reg de_adr0_we;
  reg de_adr1_we;
  reg ld_desc_sel;
  wire chunk_cnt_is_0_d;
  reg chunk_cnt_is_0_r;
  wire tsz_cnt_is_0_d;
  reg tsz_cnt_is_0_r;
  reg read;reg write;
  reg read_r;reg write_r;
  wire rd_ack;wire wr_ack;
  reg rd_ack_r;
  reg chunk_0;
  wire done;
  reg dma_done_d;
  reg dma_done_r;
  reg dma_abort_r;
  reg next_ch;
  wire read_hold;wire write_hold;
  reg write_hold_r;
  reg [1:0] ptr_adr_low;
  reg m0_go;
  reg m0_we;
  reg ptr_set;
  wire a0_inc_en;assign a0_inc_en = csr[4];
  wire a1_inc_en;assign a1_inc_en = csr[3];
  wire ptr_valid;assign ptr_valid = pointer[0];
  wire use_ed;assign use_ed = csr[7];
  reg mast0_drdy_r;
  reg paused;
  reg de_fetch_descr;

  always @(posedge clk) dma_done_r <= #1 dma_done;


  always @(posedge clk) if(de_start | ptr_set) adr0_cnt <= #1 adr0[31:2]; 
  else if(adr0_inc & a0_inc_en) adr0_cnt <= #1 adr0_cnt_next; 


  wb_dma_inc30r
  u0
  (
    .clk(clk),
    .in(adr0_cnt),
    .out(adr0_cnt_next1)
  );

  assign adr0_cnt_next[1:0] = adr0_cnt_next1[1:0];
  assign adr0_cnt_next[2] = (am0[4])? adr0_cnt_next1[2] : adr0_cnt[2];
  assign adr0_cnt_next[3] = (am0[5])? adr0_cnt_next1[3] : adr0_cnt[3];
  assign adr0_cnt_next[4] = (am0[6])? adr0_cnt_next1[4] : adr0_cnt[4];
  assign adr0_cnt_next[5] = (am0[7])? adr0_cnt_next1[5] : adr0_cnt[5];
  assign adr0_cnt_next[6] = (am0[8])? adr0_cnt_next1[6] : adr0_cnt[6];
  assign adr0_cnt_next[7] = (am0[9])? adr0_cnt_next1[7] : adr0_cnt[7];
  assign adr0_cnt_next[8] = (am0[10])? adr0_cnt_next1[8] : adr0_cnt[8];
  assign adr0_cnt_next[9] = (am0[11])? adr0_cnt_next1[9] : adr0_cnt[9];
  assign adr0_cnt_next[10] = (am0[12])? adr0_cnt_next1[10] : adr0_cnt[10];
  assign adr0_cnt_next[11] = (am0[13])? adr0_cnt_next1[11] : adr0_cnt[11];
  assign adr0_cnt_next[12] = (am0[14])? adr0_cnt_next1[12] : adr0_cnt[12];
  assign adr0_cnt_next[13] = (am0[15])? adr0_cnt_next1[13] : adr0_cnt[13];
  assign adr0_cnt_next[14] = (am0[16])? adr0_cnt_next1[14] : adr0_cnt[14];
  assign adr0_cnt_next[15] = (am0[17])? adr0_cnt_next1[15] : adr0_cnt[15];
  assign adr0_cnt_next[16] = (am0[18])? adr0_cnt_next1[16] : adr0_cnt[16];
  assign adr0_cnt_next[17] = (am0[19])? adr0_cnt_next1[17] : adr0_cnt[17];
  assign adr0_cnt_next[18] = (am0[20])? adr0_cnt_next1[18] : adr0_cnt[18];
  assign adr0_cnt_next[19] = (am0[21])? adr0_cnt_next1[19] : adr0_cnt[19];
  assign adr0_cnt_next[20] = (am0[22])? adr0_cnt_next1[20] : adr0_cnt[20];
  assign adr0_cnt_next[21] = (am0[23])? adr0_cnt_next1[21] : adr0_cnt[21];
  assign adr0_cnt_next[22] = (am0[24])? adr0_cnt_next1[22] : adr0_cnt[22];
  assign adr0_cnt_next[23] = (am0[25])? adr0_cnt_next1[23] : adr0_cnt[23];
  assign adr0_cnt_next[24] = (am0[26])? adr0_cnt_next1[24] : adr0_cnt[24];
  assign adr0_cnt_next[25] = (am0[27])? adr0_cnt_next1[25] : adr0_cnt[25];
  assign adr0_cnt_next[26] = (am0[28])? adr0_cnt_next1[26] : adr0_cnt[26];
  assign adr0_cnt_next[27] = (am0[29])? adr0_cnt_next1[27] : adr0_cnt[27];
  assign adr0_cnt_next[28] = (am0[30])? adr0_cnt_next1[28] : adr0_cnt[28];
  assign adr0_cnt_next[29] = (am0[31])? adr0_cnt_next1[29] : adr0_cnt[29];

  always @(posedge clk) if(de_start | ptr_set) adr1_cnt <= #1 adr1[31:2]; 
  else if(adr1_inc & a1_inc_en) adr1_cnt <= #1 adr1_cnt_next; 


  wb_dma_inc30r
  u1
  (
    .clk(clk),
    .in(adr1_cnt),
    .out(adr1_cnt_next1)
  );

  assign adr1_cnt_next[1:0] = adr1_cnt_next1[1:0];
  assign adr1_cnt_next[2] = (am1[4])? adr1_cnt_next1[2] : adr1_cnt[2];
  assign adr1_cnt_next[3] = (am1[5])? adr1_cnt_next1[3] : adr1_cnt[3];
  assign adr1_cnt_next[4] = (am1[6])? adr1_cnt_next1[4] : adr1_cnt[4];
  assign adr1_cnt_next[5] = (am1[7])? adr1_cnt_next1[5] : adr1_cnt[5];
  assign adr1_cnt_next[6] = (am1[8])? adr1_cnt_next1[6] : adr1_cnt[6];
  assign adr1_cnt_next[7] = (am1[9])? adr1_cnt_next1[7] : adr1_cnt[7];
  assign adr1_cnt_next[8] = (am1[10])? adr1_cnt_next1[8] : adr1_cnt[8];
  assign adr1_cnt_next[9] = (am1[11])? adr1_cnt_next1[9] : adr1_cnt[9];
  assign adr1_cnt_next[10] = (am1[12])? adr1_cnt_next1[10] : adr1_cnt[10];
  assign adr1_cnt_next[11] = (am1[13])? adr1_cnt_next1[11] : adr1_cnt[11];
  assign adr1_cnt_next[12] = (am1[14])? adr1_cnt_next1[12] : adr1_cnt[12];
  assign adr1_cnt_next[13] = (am1[15])? adr1_cnt_next1[13] : adr1_cnt[13];
  assign adr1_cnt_next[14] = (am1[16])? adr1_cnt_next1[14] : adr1_cnt[14];
  assign adr1_cnt_next[15] = (am1[17])? adr1_cnt_next1[15] : adr1_cnt[15];
  assign adr1_cnt_next[16] = (am1[18])? adr1_cnt_next1[16] : adr1_cnt[16];
  assign adr1_cnt_next[17] = (am1[19])? adr1_cnt_next1[17] : adr1_cnt[17];
  assign adr1_cnt_next[18] = (am1[20])? adr1_cnt_next1[18] : adr1_cnt[18];
  assign adr1_cnt_next[19] = (am1[21])? adr1_cnt_next1[19] : adr1_cnt[19];
  assign adr1_cnt_next[20] = (am1[22])? adr1_cnt_next1[20] : adr1_cnt[20];
  assign adr1_cnt_next[21] = (am1[23])? adr1_cnt_next1[21] : adr1_cnt[21];
  assign adr1_cnt_next[22] = (am1[24])? adr1_cnt_next1[22] : adr1_cnt[22];
  assign adr1_cnt_next[23] = (am1[25])? adr1_cnt_next1[23] : adr1_cnt[23];
  assign adr1_cnt_next[24] = (am1[26])? adr1_cnt_next1[24] : adr1_cnt[24];
  assign adr1_cnt_next[25] = (am1[27])? adr1_cnt_next1[25] : adr1_cnt[25];
  assign adr1_cnt_next[26] = (am1[28])? adr1_cnt_next1[26] : adr1_cnt[26];
  assign adr1_cnt_next[27] = (am1[29])? adr1_cnt_next1[27] : adr1_cnt[27];
  assign adr1_cnt_next[28] = (am1[30])? adr1_cnt_next1[28] : adr1_cnt[28];
  assign adr1_cnt_next[29] = (am1[31])? adr1_cnt_next1[29] : adr1_cnt[29];

  always @(posedge clk) if(de_start) chunk_cnt <= #1 txsz[24:16]; 
  else if(chunk_dec & !chunk_cnt_is_0_r) chunk_cnt <= #1 chunk_cnt - 9'h1; 

  assign chunk_cnt_is_0_d = chunk_cnt == 9'h0;

  always @(posedge clk) chunk_cnt_is_0_r <= #1 chunk_cnt_is_0_d;


  always @(posedge clk) if(de_start | ptr_set) tsz_cnt <= #1 txsz[11:0]; 
  else if(tsz_dec & !tsz_cnt_is_0_r) tsz_cnt <= #1 tsz_cnt - 12'h1; 

  assign tsz_cnt_is_0_d = (tsz_cnt == 12'h0) & !txsz[15];

  always @(posedge clk) tsz_cnt_is_0_r <= #1 tsz_cnt_is_0_d;


  always @(posedge clk) chunk_dec <= #1 read & !read_r;


  always @(posedge clk) tsz_dec <= #1 read & !read_r;


  always @(rd_ack or read_r) adr0_inc = rd_ack & read_r;


  always @(wr_ack or write_r) adr1_inc = wr_ack & write_r;


  always @(posedge clk) chunk_0 <= #1 txsz[24:16] == 9'h0;

  assign done = (chunk_0)? tsz_cnt_is_0_d : tsz_cnt_is_0_d | chunk_cnt_is_0_d;
  assign dma_done = dma_done_d & done;
  assign dma_done_all = dma_done_d & (tsz_cnt_is_0_r | nd & chunk_cnt_is_0_d);

  always @(posedge clk) next_ch <= #1 dma_done;

  assign de_txsz = (ld_desc_sel)? mast0_din[11:0] : tsz_cnt;
  assign de_adr0 = (ld_desc_sel)? mast0_din : { adr0_cnt, 2'b00 };
  assign de_adr1 = (ld_desc_sel)? mast0_din : { adr1_cnt, 2'b00 };
  assign de_csr = mast0_din;

  always @(posedge clk) dma_abort_r <= #1 dma_abort | mast0_err | mast1_err;

  assign dma_err = dma_abort_r;
  assign dma_busy = state != IDLE;

  always @(posedge clk) read_r <= #1 read;


  always @(posedge clk) write_r <= #1 write;


  always @(posedge clk) rd_ack_r <= #1 read_r;

  assign mast0_dout = (m0_we)? { 20'h0, tsz_cnt } : 
                      (csr[2])? mast1_din : mast0_din;
  assign mast1_dout = (csr[2])? mast1_din : mast0_din;

  always @(posedge clk) mast0_adr <= #1 (m0_go)? (m0_we)? pointer_s : { pointer[31:4], ptr_adr_low, 2'b00 } : 
               (read)? { adr0_cnt, 2'b00 } : { adr1_cnt, 2'b00 };


  always @(posedge clk) mast1_adr <= #1 (read)? { adr0_cnt, 2'b00 } : { adr1_cnt, 2'b00 };

  assign write_hold = (read | write) & write_hold_r;

  always @(posedge clk) write_hold_r <= #1 read | write;

  assign read_hold = (done)? read : read | write;
  assign mast0_go = !csr[2] & read_hold | !csr[1] & write_hold | m0_go;
  assign mast1_go = csr[2] & read_hold | csr[1] & write_hold;
  assign mast0_we = (m0_go)? m0_we : !csr[1] & write;
  assign mast1_we = csr[1] & write;
  assign rd_ack = (csr[2])? mast1_drdy : mast0_drdy;
  assign wr_ack = (csr[1])? mast1_drdy : mast0_drdy;
  assign mast0_wait = !(!csr[2] & read | !csr[1] & write) & !m0_go;
  assign mast1_wait = !(csr[2] & read | csr[1] & write);

  always @(posedge clk) mast0_drdy_r <= #1 mast0_drdy;

  assign de_ack = dma_done;

  always @(posedge clk or negedge rst) if(!rst) state <= #1 IDLE; 
  else state <= #1 next_state;


  always @(state or pause_req or dma_abort_r or de_start or rd_ack or wr_ack or done or ptr_valid or use_ed or mast0_drdy or mast0_drdy_r or csr or nd) begin
    next_state = state;
    read = 1'b0;
    write = 1'b0;
    dma_done_d = 1'b0;
    de_csr_we = 1'b0;
    de_txsz_we = 1'b0;
    de_adr0_we = 1'b0;
    de_adr1_we = 1'b0;
    de_fetch_descr = 1'b0;
    m0_go = 1'b0;
    m0_we = 1'b0;
    ptr_adr_low = 2'h0;
    ptr_set = 1'b0;
    ld_desc_sel = 1'b0;
    paused = 1'b0;
    case(state)
      IDLE: begin
        if(pause_req) next_state = PAUSE; 
        else if(de_start & !csr[12]) begin
          if(use_ed & !ptr_valid) next_state = LD_DESC1; 
          else next_state = READ;
        end 
      end
      PAUSE: begin
        paused = 1'b1;
        if(!pause_req) next_state = IDLE; 
      end
      READ: begin
        if(dma_abort_r) next_state = UPDATE; 
        else if(!rd_ack) read = 1'b1; 
        else begin
          write = 1'b1;
          next_state = WRITE;
        end
      end
      WRITE: begin
        if(dma_abort_r) next_state = UPDATE; 
        else if(!wr_ack) write = 1'b1; 
        else begin
          if(done) next_state = UPDATE; 
          else begin
            read = 1'b1;
            next_state = READ;
          end
        end
      end
      UPDATE: begin
        dma_done_d = 1'b1;
        de_txsz_we = 1'b1;
        de_adr0_we = 1'b1;
        de_adr1_we = 1'b1;
        if(use_ed & csr[8] & nd) begin
          m0_we = 1'b1;
          m0_go = 1'b1;
          next_state = WB;
        end else next_state = IDLE;
      end
      WB: begin
        m0_we = 1'b1;
        if(mast0_drdy) begin
          next_state = IDLE;
        end else m0_go = 1'b1;
      end
      LD_DESC1: begin
        ptr_adr_low = 2'h0;
        ld_desc_sel = 1'b1;
        m0_go = 1'b1;
        de_csr_we = 1'b1;
        de_txsz_we = 1'b1;
        de_fetch_descr = 1'b1;
        if(mast0_drdy) begin
          ptr_adr_low = 2'h1;
          next_state = LD_DESC2;
        end 
      end
      LD_DESC2: begin
        de_fetch_descr = 1'b1;
        if(mast0_drdy_r) de_csr_we = 1'b1; 
        if(mast0_drdy_r) de_txsz_we = 1'b1; 
        ptr_adr_low = 2'h1;
        ld_desc_sel = 1'b1;
        m0_go = 1'b1;
        if(mast0_drdy) begin
          ptr_adr_low = 2'h2;
          next_state = LD_DESC3;
        end 
      end
      LD_DESC3: begin
        de_fetch_descr = 1'b1;
        if(mast0_drdy_r) de_adr0_we = 1'b1; 
        ptr_adr_low = 2'h2;
        ld_desc_sel = 1'b1;
        m0_go = 1'b1;
        if(mast0_drdy) begin
          ptr_adr_low = 2'h3;
          next_state = LD_DESC4;
        end 
      end
      LD_DESC4: begin
        de_fetch_descr = 1'b0;
        if(mast0_drdy_r) de_adr1_we = 1'b1; 
        ptr_adr_low = 2'h2;
        ld_desc_sel = 1'b0;
        if(mast0_drdy) begin
          next_state = LD_DESC5;
        end else m0_go = 1'b1;
      end
      LD_DESC5: begin
        de_fetch_descr = 1'b1;
        ptr_set = 1'b1;
        next_state = READ;
      end
    endcase
  end


endmodule

