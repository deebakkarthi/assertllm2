

module sd_scoreboard #
(
  parameter width = 8,
  parameter items = 64,
  parameter use_txid = 0,
  parameter use_mask = 0,
  parameter txid_sz = 2,
  parameter asz = 6
)
(
  input clk,
  input reset,
  input c_srdy,
  output c_drdy,
  input c_req_type,
  input [txid_sz-1:0] c_txid,
  input [width-1:0] c_mask,
  input [width-1:0] c_data,
  input [asz-1:0] c_itemid,
  output p_srdy,
  input p_drdy,
  output [txid_sz-1:0] p_txid,
  output [width-1:0] p_data
);

  localparam tot_in_sz = ((use_mask)? width * 2 : width) + ((use_txid)? txid_sz : 0) + asz + 1;
  wire ip_req_type;
  wire [txid_sz-1:0] ip_txid;
  wire [width-1:0] ip_mask;
  wire [width-1:0] ip_data;
  wire [asz-1:0] ip_itemid;
  wire [txid_sz-1:0] ic_txid;
  wire [width-1:0] ic_data;
  wire [asz-1:0] addr;
  wire [width-1:0] d_in;
  wire [width-1:0] d_out;
  wire ic_drdy;
  wire ic_srdy;
  wire ip_drdy;
  wire ip_srdy;
  wire rd_en;
  wire wr_en;
  wire [tot_in_sz-1:0] c_hold_data;wire [tot_in_sz-1:0] p_hold_data;

  generate if((use_txid == 1) && (use_mask == 1)) begin : txid_and_mask
    assign c_hold_data = { c_txid, c_req_type, c_itemid, c_mask, c_data };
    assign { ip_txid, ip_req_type, ip_itemid, ip_mask, ip_data } = p_hold_data;
  end else if((use_txid == 0) && (use_mask == 1)) begin : no_txid_and_mask
    assign c_hold_data = { c_req_type, c_itemid, c_mask, c_data };
    assign { ip_req_type, ip_itemid, ip_mask, ip_data } = p_hold_data;
    assign ip_txid = 0;
  end else if((use_txid == 1) && (use_mask == 0)) begin : txid_and_no_mask
    assign c_hold_data = { c_txid, c_req_type, c_itemid, c_data };
    assign { ip_txid, ip_req_type, ip_itemid, ip_data } = p_hold_data;
    assign ip_mask = 0;
  end else if((use_txid == 0) && (use_mask == 0)) begin : no_txid_no_mask
    assign c_hold_data = { c_req_type, c_itemid, c_data };
    assign { ip_req_type, ip_itemid, ip_data } = p_hold_data;
    assign ip_mask = 0;
    assign ip_txid = 0;
  end 
  endgenerate


  sd_input
  #(
    .width(tot_in_sz)
  )
  inhold
  (
    .c_data(c_hold_data),
    .ip_data(p_hold_data),
    .c_drdy(c_drdy),
    .ip_srdy(ip_drdy),
    .clk(clk),
    .reset(reset),
    .c_srdy(c_srdy),
    .ip_drdy(ip_srdy)
  );


  behave1p_mem
  #(
    .depth(items),
    .addr_sz(asz),
    .width(width)
  )
  sb_mem
  (
    .addr(addr[asz-1:0]),
    .d_out(d_out[width-1:0]),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .clk(clk),
    .d_in(d_in[width-1:0])
  );


  sd_scoreboard_fsm
  #(
    .width(width),
    .items(items),
    .use_txid(use_txid),
    .use_mask(use_mask),
    .txid_sz(txid_sz),
    .asz(asz)
  )
  fsm
  (
    .ip_drdy(ip_drdy),
    .ic_srdy(ic_srdy),
    .ic_txid(ic_txid[txid_sz-1:0]),
    .ic_data(ic_data[width-1:0]),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .d_in(d_in[width-1:0]),
    .addr(addr[asz-1:0]),
    .clk(clk),
    .reset(reset),
    .ip_srdy(ip_srdy),
    .ip_req_type(ip_req_type),
    .ip_txid(ip_txid[txid_sz-1:0]),
    .ip_mask(ip_mask[width-1:0]),
    .ip_data(ip_data[width-1:0]),
    .ip_itemid(ip_itemid[asz-1:0]),
    .ic_drdy(ic_drdy),
    .d_out(d_out[width-1:0])
  );


  sd_output
  #(
    .width(width + txid_sz)
  )
  outhold
  (
    .p_data({ p_txid, p_data }),
    .ic_data({ ic_txid, ic_data }),
    .ic_drdy(ic_drdy),
    .p_srdy(p_srdy),
    .clk(clk),
    .reset(reset),
    .ic_srdy(ic_srdy),
    .p_drdy(p_drdy)
  );


endmodule

