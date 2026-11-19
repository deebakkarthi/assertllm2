

module fifo_sport
(
  clk_rd,
  clk_wr,
  d_i,
  d_o,
  rst,
  wr_en,
  rd_en,
  full,
  empty
);

  input clk_rd;
  input clk_wr;
  input [32-1:0] d_i;
  output [32-1:0] d_o;
  input rst;
  input wr_en;
  input rd_en;
  output full;
  output empty;
  wire [3:0] full_int;
  wire [3:0] empty_int;
  assign full = |full_int;
  assign empty = |empty_int;

  custom_fifo_dp
  custom_fifo_dp5
  (
    clk_rd,
    clk_wr,
    d_i[31:24],
    d_o[31:24],
    rst,
    wr_en,
    rd_en,
    full_int[0],
    empty_int[1]
  );


  custom_fifo_dp
  custom_fifo_dp6
  (
    clk_rd,
    clk_wr,
    d_i[23:16],
    d_o[23:16],
    rst,
    wr_en,
    rd_en,
    full_int[1],
    empty_int[1]
  );


  custom_fifo_dp
  custom_fifo_dp7
  (
    clk_rd,
    clk_wr,
    d_i[15:8],
    d_o[15:8],
    rst,
    wr_en,
    rd_en,
    full_int[2],
    empty_int[2]
  );


  custom_fifo_dp
  custom_fifo_dp8
  (
    clk_rd,
    clk_wr,
    d_i[7:0],
    d_o[7:0],
    rst,
    wr_en,
    rd_en,
    full_int[3],
    empty_int[3]
  );


endmodule



module custom_fifo_dp
(
  clk_rd,
  clk_wr,
  d_i,
  d_o,
  rst,
  wr_en,
  rd_en,
  full,
  empty
);

  input clk_rd;
  input clk_wr;
  input [7:0] d_i;
  output [7:0] d_o;
  input rst;
  input wr_en;
  input rd_en;
  output full;
  output empty;
  reg [10-1:0] addr_rd;
  reg [10-1:0] addr_wr;
  reg [7:0] fifo_out;
  wire [7:0] mem_byte_out;
  wire [10-1:0] full_int;
  genvar c;

  generate for(c=0; c<10; c=c+1) begin : mem

    mem_byte
    mem_byte
    (
      rst,
      clk_wr,
      d_i,
      mem_byte_out,
      addr_wr[c],
      addr_rd[c]
    );

  end
  endgenerate

  assign d_o = fifo_out;

  always @(posedge clk_rd or posedge rst) begin
    if(rst) fifo_out <= 8'h0; 
    else fifo_out <= mem_byte_out;
  end


  always @(posedge clk_wr or posedge rst) begin
    if(rst) addr_wr <= 10'h1; 
    else if(wr_en & ~full) begin
      addr_wr[10-1:1] <= addr_wr[10-2:0];
      addr_wr[0] <= addr_wr[10 - 1];
    end 
  end


  always @(posedge clk_rd or posedge rst) begin
    if(rst) addr_rd <= 10'h1; 
    else if(rd_en & ~empty) begin
      addr_rd[10-1:1] <= addr_rd[10-2:0];
      addr_rd[0] <= addr_rd[10 - 1];
    end 
  end

  assign empty = addr_wr == addr_rd;
  assign full = (empty)? 1'b0 : |full_int;
  assign full_int[0] = addr_wr[10 - 1] & addr_rd[0];
  genvar d;

  generate for(d=1; d<10; d=d+1) begin : flag
    assign full_int[d] = addr_wr[d - 1] & addr_rd[d];
  end
  endgenerate


endmodule



module mem_byte
(
  rst,
  clk,
  din,
  dout,
  wen,
  ren
);

  input rst;
  input clk;
  input [7:0] din;
  output [7:0] dout;
  input wen;
  input ren;
  reg [7:0] byte_reg;
  assign dout = (ren)? byte_reg : 8'bz;

  always @(posedge clk or posedge rst) begin
    if(rst) byte_reg <= 8'h0; 
    else if(wen) byte_reg <= din; 
  end


endmodule

