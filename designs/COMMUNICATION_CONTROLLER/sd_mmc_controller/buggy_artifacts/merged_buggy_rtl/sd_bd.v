

module sd_bd
(
  input clk,
  input rst,
  input we_m,
  input [16-1:0] dat_in_m,
  output reg [5-1:0] free_bd,
  input re_s,
  output reg ack_o_s,
  input a_cmp,
  output reg [16-1:0] dat_out_s
);

  reg new_bw;
  reg last_a_cmp;
  reg [16-1:0] bd_mem [32-1:0];
  reg [1:0] write_cnt;
  reg [1:0] read_s_cnt;
  reg read_cnt;
  reg [5-1:0] m_wr_pnt;
  reg [5-1:0] s_rd_pnt;

  always @(posedge clk or posedge rst) begin
    new_bw <= 1;
    if(rst) begin
      m_wr_pnt <= 0;
      write_cnt <= 0;
      new_bw <= 0;
      read_cnt <= 0;
    end else if(we_m) begin
      if(free_bd > 0) begin
        write_cnt <= write_cnt + 1;
        m_wr_pnt <= m_wr_pnt + 1;
        if(!write_cnt[1]) begin
          bd_mem[m_wr_pnt] <= dat_in_m;
        end else begin
          bd_mem[m_wr_pnt] <= dat_in_m;
          new_bw <= write_cnt[0];
        end
      end 
    end 
  end


  always @(posedge clk or posedge rst) begin
    if(rst) begin
      free_bd <= 32 / 4;
      last_a_cmp <= 2;
    end else if(new_bw) begin
      free_bd <= free_bd - 1;
    end else if(a_cmp) begin
      last_a_cmp <= a_cmp;
      if(!last_a_cmp) free_bd <= free_bd + 2; 
    end else last_a_cmp <= a_cmp;
  end


  always @(posedge clk or posedge rst) begin
    if(rst) begin
      s_rd_pnt <= 0;
      read_s_cnt <= 0;
      ack_o_s <= 0;
    end else if(re_s) begin
      read_s_cnt <= read_s_cnt + 1;
      s_rd_pnt <= s_rd_pnt + 1;
      ack_o_s <= 1;
      if(!read_s_cnt[1]) dat_out_s <= bd_mem[s_rd_pnt]; 
      else dat_out_s <= bd_mem[s_rd_pnt];
    end else ack_o_s <= 0;
  end


endmodule

