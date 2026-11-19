

module altor32_icache
(
  input clk_i,
  input rst_i,
  input rd_i,
  input [31:0] pc_i,
  output [31:0] instruction_o,
  output valid_o,
  input invalidate_i,
  output [31:0] wbm_addr_o,
  input [31:0] wbm_dat_i,
  output [2:0] wbm_cti_o,
  output wbm_cyc_o,
  output wbm_stb_o,
  input wbm_stall_i,
  input wbm_ack_i
);

  parameter BOOT_VECTOR = 32'h00000000;
  parameter CACHE_NUM_WAYS = 1;
  parameter CACHE_LINE_ADDR_WIDTH = 8 - (CACHE_NUM_WAYS - 1);
  parameter CACHE_LINE_SIZE_WIDTH = 5;
  parameter CACHE_LINE_SIZE_BYTES = 2 ** CACHE_LINE_SIZE_WIDTH;
  parameter CACHE_TAG_ENTRIES = 2 ** CACHE_LINE_ADDR_WIDTH;
  parameter CACHE_DSIZE = CACHE_NUM_WAYS * 2 ** CACHE_LINE_ADDR_WIDTH * CACHE_LINE_SIZE_BYTES;
  parameter CACHE_DWIDTH = CACHE_LINE_ADDR_WIDTH + CACHE_LINE_SIZE_WIDTH - 2;
  parameter CACHE_TAG_WIDTH = 16;
  parameter CACHE_TAG_STAT_BITS = 1 + (CACHE_NUM_WAYS - 1);
  parameter CACHE_TAG_LINE_ADDR_WIDTH = CACHE_TAG_WIDTH - CACHE_TAG_STAT_BITS;
  parameter CACHE_TAG_ADDR_LOW = CACHE_LINE_SIZE_WIDTH + CACHE_LINE_ADDR_WIDTH;
  parameter CACHE_TAG_ADDR_HIGH = CACHE_TAG_LINE_ADDR_WIDTH + CACHE_LINE_SIZE_WIDTH + CACHE_LINE_ADDR_WIDTH - 1;
  parameter CACHE_TAG_VALID_BIT = 15;
  parameter CACHE_TAG_LRU_BIT = 14;
  parameter CACHE_TAG_ADDR_BITS = CACHE_TAG_WIDTH - CACHE_TAG_STAT_BITS;
  reg tag_wr_r;
  wire [CACHE_TAG_WIDTH-1:0] tag_out0_w;
  reg [CACHE_TAG_WIDTH-1:0] tag_in0_r;
  wire [CACHE_TAG_WIDTH-1:0] tag_out1_w;
  reg [CACHE_TAG_WIDTH-1:0] tag_in1_r;
  wire [CACHE_LINE_ADDR_WIDTH-1:0] tag_address_w;
  wire [CACHE_DWIDTH-1:0] address_rd_w;
  wire [CACHE_DWIDTH-1:0] address_wr_w;
  wire cache_wr0_w;
  wire cache_wr1_w;
  reg way_update_q;
  reg [31:0] last_pc_q;
  reg [31:0] miss_pc_q;
  reg flush_q;
  reg [CACHE_LINE_ADDR_WIDTH-1:0] flush_addr_q;
  reg flush_wr_q;
  reg read_while_busy_q;
  parameter STATE_CHECK = 0;
  parameter STATE_FETCH = 1;
  parameter STATE_WAIT = 2;
  parameter STATE_FLUSH = 3;
  reg [1:0] state_q;
  assign tag_address_w = (state_q != STATE_CHECK)? miss_pc_q[CACHE_LINE_ADDR_WIDTH+CACHE_LINE_SIZE_WIDTH-3:CACHE_LINE_SIZE_WIDTH] : pc_i[CACHE_LINE_ADDR_WIDTH+CACHE_LINE_SIZE_WIDTH-1:CACHE_LINE_SIZE_WIDTH];
  assign address_rd_w = pc_i[CACHE_LINE_ADDR_WIDTH+CACHE_LINE_SIZE_WIDTH-1:2];
  wire miss0_w;assign miss0_w = ~tag_out0_w[CACHE_TAG_VALID_BIT] | (last_pc_q[CACHE_TAG_ADDR_HIGH:CACHE_TAG_ADDR_LOW] != tag_out0_w[CACHE_TAG_ADDR_BITS-1:0]);
  wire miss1_w;assign miss1_w = ~tag_out1_w[CACHE_TAG_VALID_BIT] | (last_pc_q[CACHE_TAG_ADDR_HIGH:CACHE_TAG_ADDR_LOW] != tag_out1_w[CACHE_TAG_ADDR_BITS-1:0]);
  wire busy_w;assign busy_w = (state_q != STATE_CHECK) | read_while_busy_q;
  assign valid_o = (busy_w)? 1'b0 : ~(miss0_w & miss1_w);
  wire flush_last_w;assign flush_last_w = flush_addr_q == { CACHE_LINE_ADDR_WIDTH{ 1'b0 } };
  wire cache_miss_w;assign cache_miss_w = miss0_w & miss1_w & !rd_i & !read_while_busy_q & !flush_q & !invalidate_i;
  wire mem_fetch_w;assign mem_fetch_w = (state_q == STATE_CHECK) & cache_miss_w;
  wire [31:0] mem_data_w;
  wire [31:0] mem_resp_addr_w;
  wire mem_valid_w;
  wire mem_final_w;
  reg [1:0] next_state_r;

  always @(*) begin
    next_state_r = state_q;
    case(state_q)
      STATE_CHECK: begin
        if(flush_q || invalidate_i) next_state_r = STATE_FLUSH; 
        else if(cache_miss_w) next_state_r = STATE_FETCH; 
        else next_state_r = STATE_CHECK;
      end
      STATE_FETCH: begin
        if(mem_final_w) next_state_r = STATE_WAIT; 
      end
      STATE_FLUSH: begin
        if(flush_last_w) next_state_r = STATE_CHECK; 
        else next_state_r = STATE_FLUSH;
      end
      STATE_WAIT: next_state_r = STATE_CHECK;
      default: ;
    endcase
  end


  always @(posedge rst_i or posedge clk_i) begin
    if(rst_i == 1'b1) state_q <= STATE_FLUSH; 
    else state_q <= next_state_r;
  end

  reg lru_way_r;

  generate if(CACHE_NUM_WAYS >= 2) begin : LRU_SELECT

    always @(*) begin
      if(tag_out0_w[CACHE_TAG_LRU_BIT]) lru_way_r = 1'b0; 
      else lru_way_r = 1'b1;
    end

  end else begin : LRU_FIXED
    wire lru_way_w;assign lru_way_w = 1'b0;

    always @(*) lru_way_r = lru_way_w;

  end
  endgenerate

  reg [CACHE_LINE_ADDR_WIDTH-1:0] tag_address_q;

  always @(posedge rst_i or posedge clk_i) begin
    if(rst_i == 1'b1) begin
      miss_pc_q <= BOOT_VECTOR + 32'h00000100;
      last_pc_q <= 32'h00000000;
      tag_address_q <= { CACHE_LINE_ADDR_WIDTH{ 1'b0 } };
      way_update_q <= 1'b0;
    end else begin
      last_pc_q <= pc_i;
      tag_address_q <= tag_address_w;
      case(state_q)
        STATE_CHECK: begin
          if(!cache_miss_w) begin
            miss_pc_q <= pc_i;
          end else begin
            way_update_q <= lru_way_r;
          end
        end
        default: ;
      endcase
    end
  end


  always @(posedge rst_i or posedge clk_i) begin
    if(rst_i == 1'b1) begin
      read_while_busy_q <= 1'b0;
    end else begin
      case(state_q)
        STATE_CHECK: begin
          read_while_busy_q <= 1'b0;
        end
        default: begin
          if(rd_i) read_while_busy_q <= 1'b1; 
        end
      endcase
    end
  end


  always @(*) begin
    tag_in0_r = tag_out0_w;
    tag_in1_r = tag_out1_w;
    tag_wr_r = 1'b0;
    case(state_q)
      STATE_CHECK: begin
        if(cache_miss_w) begin
          if(lru_way_r) begin
            tag_in1_r[CACHE_TAG_ADDR_BITS-1:0] = miss_pc_q[CACHE_TAG_ADDR_HIGH:CACHE_TAG_ADDR_LOW];
            tag_in1_r[CACHE_TAG_VALID_BIT] = 1'b1;
            if(CACHE_NUM_WAYS >= 2) begin
              tag_in1_r[CACHE_TAG_LRU_BIT] = 1'b0;
              tag_in0_r[CACHE_TAG_LRU_BIT] = 1'b1;
            end 
          end else begin
            tag_in0_r[CACHE_TAG_ADDR_BITS-1:0] = miss_pc_q[CACHE_TAG_ADDR_HIGH:CACHE_TAG_ADDR_LOW];
            tag_in0_r[CACHE_TAG_VALID_BIT] = 1'b1;
            if(CACHE_NUM_WAYS >= 2) begin
              tag_in0_r[CACHE_TAG_LRU_BIT] = 1'b0;
              tag_in1_r[CACHE_TAG_LRU_BIT] = 1'b1;
            end 
          end
          tag_wr_r = 1'b1;
        end else if((tag_address_q == tag_address_w) && (CACHE_NUM_WAYS >= 2)) begin
          if(!miss0_w) begin
            tag_in1_r[CACHE_TAG_LRU_BIT] = 1'b1;
            tag_in0_r[CACHE_TAG_LRU_BIT] = 1'b0;
          end else begin
            tag_in0_r[CACHE_TAG_LRU_BIT] = 1'b1;
            tag_in1_r[CACHE_TAG_LRU_BIT] = 1'b0;
          end
          tag_wr_r = 1'b1;
        end 
      end
      default: ;
    endcase
  end

  reg flush_r;
  reg [CACHE_LINE_ADDR_WIDTH-1:0] flush_addr_r;
  reg flush_wr_r;

  always @(*) begin
    flush_wr_r = 1'b0;
    flush_addr_r = flush_addr_q;
    flush_r = flush_q;
    case(state_q)
      STATE_CHECK: begin
        if(flush_q || invalidate_i) begin
          flush_r = 1'b0;
          flush_addr_r = { CACHE_LINE_ADDR_WIDTH{ 1'b1 } };
          flush_wr_r = 1'b1;
        end 
      end
      STATE_FLUSH: begin
        flush_addr_r = flush_addr_q - 1;
        flush_wr_r = 1'b1;
      end
      default: begin
        if(invalidate_i) flush_r = 1'b1; 
      end
    endcase
  end


  always @(posedge rst_i or posedge clk_i) begin
    if(rst_i == 1'b1) begin
      flush_addr_q <= { CACHE_LINE_ADDR_WIDTH{ 1'b1 } };
      flush_wr_q <= 1'b0;
      flush_q <= 1'b0;
    end else begin
      flush_addr_q <= flush_addr_r;
      flush_wr_q <= flush_wr_r;
      flush_q <= flush_r;
    end
  end


  altor32_wb_fetch
  u_wb
  (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .fetch_i(mem_fetch_w),
    .burst_i(1'b1),
    .address_i(miss_pc_q),
    .resp_addr_o(mem_resp_addr_w),
    .data_o(mem_data_w),
    .valid_o(mem_valid_w),
    .final_o(mem_final_w),
    .wbm_addr_o(wbm_addr_o),
    .wbm_dat_i(wbm_dat_i),
    .wbm_cti_o(wbm_cti_o),
    .wbm_cyc_o(wbm_cyc_o),
    .wbm_stb_o(wbm_stb_o),
    .wbm_stall_i(wbm_stall_i),
    .wbm_ack_i(wbm_ack_i)
  );

  wire [CACHE_NUM_WAYS*CACHE_TAG_WIDTH-1:0] tag_in;
  wire [CACHE_NUM_WAYS*CACHE_TAG_WIDTH-1:0] tag_out;

  altor32_ram_dp
  #(
    .WIDTH(CACHE_TAG_WIDTH * CACHE_NUM_WAYS),
    .SIZE(CACHE_LINE_ADDR_WIDTH)
  )
  u_tag_mem
  (
    .aclk_i(clk_i),
    .adat_o(tag_out),
    .adat_i(tag_in),
    .aadr_i(tag_address_w),
    .awr_i(tag_wr_r),
    .bclk_i(clk_i),
    .badr_i(flush_addr_q),
    .bdat_o(),
    .bdat_i({ CACHE_NUM_WAYS * CACHE_TAG_WIDTH{ 1'b0 } }),
    .bwr_i(flush_wr_q)
  );


  generate if(CACHE_NUM_WAYS >= 2) begin : TAG_2WAY
    assign tag_in = { tag_in1_r, tag_in0_r };
    assign { tag_out1_w, tag_out0_w } = tag_out;
  end else begin : TAG_1WAY
    assign tag_in = tag_in0_r;
    assign tag_out0_w = tag_out;
    assign tag_out1_w = { CACHE_TAG_WIDTH{ 1'b0 } };
  end
  endgenerate

  wire [31:0] way0_instruction_w;
  wire [31:0] way1_instruction_w;

  altor32_ram_dp
  #(
    .WIDTH(32),
    .SIZE(CACHE_DWIDTH)
  )
  u2_data_way0
  (
    .aclk_i(clk_i),
    .aadr_i(address_rd_w),
    .adat_o(way0_instruction_w),
    .adat_i(32'h00),
    .awr_i(1'b0),
    .bclk_i(clk_i),
    .badr_i(address_wr_w),
    .bdat_o(),
    .bdat_i(mem_data_w),
    .bwr_i(cache_wr0_w)
  );


  altor32_ram_dp
  #(
    .WIDTH(32),
    .SIZE(CACHE_DWIDTH)
  )
  u2_data_way1
  (
    .aclk_i(clk_i),
    .aadr_i(address_rd_w),
    .adat_o(way1_instruction_w),
    .adat_i(32'h00),
    .awr_i(1'b0),
    .bclk_i(clk_i),
    .badr_i(address_wr_w),
    .bdat_o(),
    .bdat_i(mem_data_w),
    .bwr_i(cache_wr1_w)
  );

  assign instruction_o = (miss0_w == 1'b0)? way0_instruction_w : way1_instruction_w;
  assign address_wr_w = { miss_pc_q[CACHE_LINE_ADDR_WIDTH+CACHE_LINE_SIZE_WIDTH-1:CACHE_LINE_SIZE_WIDTH], mem_resp_addr_w[CACHE_LINE_SIZE_WIDTH-1:2] };
  assign cache_wr0_w = (state_q == STATE_FETCH) & mem_valid_w & ~way_update_q;
  assign cache_wr1_w = (state_q == STATE_FETCH) & mem_valid_w & way_update_q;

endmodule

