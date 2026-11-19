

module wbicapetwo
(
  i_clk,
  i_wb_cyc,
  i_wb_stb,
  i_wb_we,
  i_wb_addr,
  i_wb_data,
  o_wb_ack,
  o_wb_stall,
  o_wb_data
);

  input i_clk;
  input i_wb_cyc;input i_wb_stb;input i_wb_we;
  input [4:0] i_wb_addr;
  input [31:0] i_wb_data;
  output o_wb_ack;reg o_wb_ack;output o_wb_stall;reg o_wb_stall;
  output [31:0] o_wb_data;reg [31:0] o_wb_data;
  reg wb_req;reg r_we;
  reg [31:0] r_data;
  reg [4:0] r_addr;
  reg [31:0] cfg_in;
  reg cfg_cs_n;reg cfg_rdwrn;
  wire [31:0] cfg_out;
  reg [4:0] state;

  initial state = 5'h00;


  initial cfg_cs_n = 1'b1;


  always @(posedge i_clk) begin
    o_wb_ack <= 1'b0;
    o_wb_stall <= 1'b1;
    state <= state + 5'h01;
    wb_req <= wb_req & i_wb_cyc;
    case(state)
      5'h00: begin
        cfg_cs_n <= 1'b1;
        cfg_rdwrn <= 1'b1;
        cfg_in <= 32'hffffffff;
        state <= 5'h00;
        o_wb_ack <= 1'b0;
        o_wb_stall <= 1'b0;
        r_addr <= i_wb_addr;
        r_data <= i_wb_data;
        r_we <= i_wb_we;
        if(i_wb_cyc && i_wb_stb) begin
          state <= 5'h01;
          wb_req <= 1'b1;
          o_wb_ack <= 1'b0;
          o_wb_stall <= 1'b1;
        end 
      end
      5'h01: cfg_in <= 32'hffffffff;
      5'h02: begin
        cfg_cs_n <= 1'b0;
        cfg_rdwrn <= 1'b0;
        cfg_in <= 32'h20000000;
      end
      5'h03: cfg_in <= 32'haa995566;
      5'h04: cfg_in <= 32'h20000000;
      5'h05: begin
        cfg_in <= 32'h20000000;
        state <= (r_we)? 5'h0f : 5'h06;
      end
      5'h06: cfg_in <= { 8'h28, 6'h0, r_addr, 13'h001 };
      5'h07: cfg_in <= 32'h20000000;
      5'h08: cfg_in <= 32'h20000000;
      5'h09: begin
        cfg_cs_n <= 1'b1;
        cfg_rdwrn <= 1'b1;
        cfg_in <= 32'h20000000;
      end
      5'h0a: begin
        cfg_cs_n <= 1'b0;
        cfg_rdwrn <= 1'b1;
        cfg_in <= 32'h20000000;
      end
      5'h0b: cfg_in <= 32'h20000000;
      5'h0c: cfg_in <= 32'h20000000;
      5'h0d: cfg_in <= 32'h20000000;
      5'h0e: begin
        cfg_cs_n <= 1'b1;
        cfg_rdwrn <= 1'b1;
        cfg_in <= 32'h20000000;
        o_wb_ack <= wb_req;
        o_wb_data <= cfg_out;
        wb_req <= 1'b0;
        state <= 5'h11;
      end
      5'h0f: cfg_in <= { 8'h30, 6'h0, r_addr, 13'h001 };
      5'h10: cfg_in <= r_data;
      5'h11: begin
        cfg_cs_n <= 1'b0;
        cfg_rdwrn <= 1'b0;
        cfg_in <= 32'h20000000;
      end
      5'h12: cfg_in <= 32'h20000000;
      5'h13: cfg_in <= 32'h30008001;
      5'h14: cfg_in <= 32'h0000000d;
      5'h15: cfg_in <= 32'h20000000;
      5'h16: cfg_in <= 32'h20000000;
      5'h17: begin
        o_wb_ack <= wb_req;
        o_wb_stall <= 1'b1;
        wb_req <= 1'b1;
        cfg_cs_n <= 1'b0;
        cfg_rdwrn <= 1'b1;
        cfg_in <= 32'hfffffffe;
        state <= 5'h01;
      end
      default: begin
        o_wb_ack <= 1'b0;
        o_wb_stall <= 1'b1;
        cfg_cs_n <= 1'b1;
        cfg_rdwrn <= 1'b0;
        state <= 5'h00;
        cfg_in <= 32'hffffffff;
      end
    endcase
  end

  genvar k;
  wire [31:0] bit_swapped_cfg_in;

  generate for(k=0; k<8; k=k+1) begin
    assign bit_swapped_cfg_in[k] = cfg_in[7 - k];
    assign bit_swapped_cfg_in[8 + k] = cfg_in[8 + 7 - k];
    assign bit_swapped_cfg_in[16 + k] = cfg_in[16 + 7 - k];
    assign bit_swapped_cfg_in[24 + k] = cfg_in[24 + 7 - k];
  end
  endgenerate

  wire [31:0] bit_swapped_cfg_out;

  generate for(k=0; k<8; k=k+1) begin
    assign cfg_out[k] = bit_swapped_cfg_out[7 - k];
    assign cfg_out[8 + k] = bit_swapped_cfg_out[8 + 7 - k];
    assign cfg_out[16 + k] = bit_swapped_cfg_out[16 + 7 - k];
    assign cfg_out[24 + k] = bit_swapped_cfg_out[24 + 7 - k];
  end
  endgenerate


endmodule

