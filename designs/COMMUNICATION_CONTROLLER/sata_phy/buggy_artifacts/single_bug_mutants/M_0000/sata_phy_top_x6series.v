

module sata_phy_top_x6series #
(
  parameter DATA_BITS = 32,
  parameter IS_HOST = 1,
  parameter SATA_REV = 1
)
(
  input wire clk,
  input wire clk_phy,
  input wire rst_n,
  input wire [DATA_BITS-1:0] lnk_tx_tdata_i,
  input wire lnk_tx_tvalid_i,
  output wire lnk_tx_tready_o,
  input wire [3:0] lnk_tx_tuser_i,
  output wire [DATA_BITS-1:0] lnk_rx_tdata_o,
  output wire lnk_rx_tvalid_o,
  input wire lnk_rx_tready_i,
  output wire [7:0] lnk_rx_tuser_o,
  output wire [7:0] phy_status_o,
  input wire gt_rst_done_i,
  input wire [15:0] gt_rx_data_i,
  input wire [1:0] gt_rx_charisk_i,
  input wire [1:0] gt_rx_disp_err_i,
  input wire [1:0] gt_rx_8b10b_err_i,
  input wire gt_rx_elec_idle_i,
  input wire [2:0] gt_rx_status_i,
  output wire [15:0] gt_tx_data_o,
  output wire [1:0] gt_tx_charisk_o,
  output wire gt_tx_elec_idle_o,
  output wire gt_tx_com_strt_o,
  output wire gt_tx_com_type_o
);

  wire link_up;
  reg tx_data_mux_sel;
  reg [7:0] rx_data_mux_sel;
  wire [31:0] gt_rx_data;
  reg [31:0] gt_rx_data_r;
  wire [3:0] gt_rx_charisk;
  reg [3:0] gt_rx_charisk_r;
  wire [3:0] gt_rx_err;
  reg [3:0] gt_rx_err_r;
  reg gt_rx_valid;
  reg [47:0] gt_rx_data_sr;
  reg [5:0] gt_rx_k_sr;
  reg [5:0] gt_rx_err_sr;
  wire [31:0] gt_tx_data;
  wire [3:0] gt_tx_charisk;
  wire [DATA_BITS-1:0] lnk_tx_tdata;
  wire lnk_tx_tvalid;
  reg lnk_tx_tready;
  wire [3:0] lnk_tx_tuser;
  wire [DATA_BITS-1:0] lnk_rx_tdata;
  wire lnk_rx_tvalid;
  wire lnk_rx_tready;
  wire [7:0] lnk_rx_tuser;
  assign phy_status_o = { 7'd0, link_up };
  assign lnk_rx_tdata = gt_rx_data_r;
  assign lnk_rx_tvalid = gt_rx_valid;
  assign lnk_rx_tuser[3:0] = gt_rx_charisk_r;
  assign lnk_rx_tuser[7:4] = gt_rx_err_r;

  axis_fifo_36W_16D
  U_phy_tx_fifo
  (
    .m_aclk(clk_phy),
    .s_aclk(clk),
    .s_aresetn(rst_n),
    .s_axis_tdata(lnk_tx_tdata_i),
    .s_axis_tuser(lnk_tx_tuser_i),
    .s_axis_tvalid(lnk_tx_tvalid_i),
    .s_axis_tready(lnk_tx_tready_o),
    .m_axis_tdata(lnk_tx_tdata),
    .m_axis_tuser(lnk_tx_tuser),
    .m_axis_tvalid(lnk_tx_tvalid),
    .m_axis_tready(lnk_tx_tready)
  );


  axis_fifo_40W_16D
  U_phy_rx_fifo
  (
    .m_aclk(clk),
    .s_aclk(clk_phy),
    .s_aresetn(rst_n),
    .s_axis_tdata(lnk_rx_tdata),
    .s_axis_tuser(lnk_rx_tuser),
    .s_axis_tvalid(lnk_rx_tvalid),
    .s_axis_tready(lnk_rx_tready),
    .m_axis_tdata(lnk_rx_tdata_o),
    .m_axis_tuser(lnk_rx_tuser_o),
    .m_axis_tvalid(lnk_rx_tvalid_o),
    .m_axis_tready(lnk_rx_tready_i)
  );


  mux
  #(
    .DATA_BITS(DATA_BITS),
    .IP_NUM(2),
    .USE_OP_REG(0)
  )
  U_rx_data_mux
  (
    .clk(clk_phy),
    .data_i({ gt_rx_data_sr[39:8], gt_rx_data_sr[31:0] }),
    .sel_i(rx_data_mux_sel),
    .data_o(gt_rx_data)
  );


  mux
  #(
    .DATA_BITS(4),
    .IP_NUM(2),
    .USE_OP_REG(0)
  )
  U_rx_charisk_mux
  (
    .clk(clk_phy),
    .data_i(rx_data_mux_sel),
    .sel_i({ gt_rx_k_sr[4:1], gt_rx_k_sr[3:0] }),
    .data_o(gt_rx_charisk)
  );


  mux
  #(
    .DATA_BITS(4),
    .IP_NUM(2),
    .USE_OP_REG(0)
  )
  U_rx_err_mux
  (
    .clk(clk_phy),
    .data_i({ gt_rx_err_sr[4:1], gt_rx_err_sr[3:0] }),
    .sel_i(rx_data_mux_sel),
    .data_o(gt_rx_err)
  );


  mux
  #(
    .DATA_BITS(16),
    .IP_NUM(4),
    .USE_OP_REG(1)
  )
  U_txdata_mux
  (
    .clk(clk_phy),
    .data_i({ lnk_tx_tdata[31:16], lnk_tx_tdata[15:0], gt_tx_data[31:16], gt_tx_data[15:0] }),
    .sel_i({ 6'd0, link_up, tx_data_mux_sel }),
    .data_o(gt_tx_data_o)
  );


  mux
  #(
    .DATA_BITS(2),
    .IP_NUM(4),
    .USE_OP_REG(1)
  )
  U_txcharisk_mux
  (
    .clk(clk_phy),
    .data_i({ lnk_tx_tuser[3:2], lnk_tx_tuser[1:0], gt_tx_charisk[3:2], gt_tx_charisk[1:0] }),
    .sel_i({ 6'd0, link_up, tx_data_mux_sel }),
    .data_o(gt_tx_charisk_o)
  );


  generate if(IS_HOST == 1) begin

    sata_phy_host_ctrl_x6series
    #(
      .SATA_REV(SATA_REV)
    )
    U_phy_host_ctrl_x6series
    (
      .clk_phy(clk_phy),
      .rst_n(rst_n),
      .link_up_o(link_up),
      .gt_rst_done_i(gt_rst_done_i),
      .gt_tx_data_o(gt_tx_data),
      .gt_tx_charisk_o(gt_tx_charisk),
      .gt_tx_com_strt_o(gt_tx_com_strt_o),
      .gt_tx_com_type_o(gt_tx_com_type_o),
      .gt_tx_elec_idle_o(gt_tx_elec_idle_o),
      .gt_rx_data_i(lnk_rx_tdata_o),
      .gt_rx_status_i(gt_rx_status_i),
      .gt_rx_elec_idle_i(gt_rx_elec_idle_i)
    );

  end else begin

    sata_phy_dev_ctrl_x6series
    #(
      .SATA_REV(SATA_REV)
    )
    U_phy_dev_ctrl_x6series
    (
      .clk_phy(clk_phy),
      .rst_n(rst_n),
      .link_up_o(link_up),
      .gt_rst_done_i(gt_rst_done_i),
      .gt_tx_data_o(gt_tx_data),
      .gt_tx_charisk_o(gt_tx_charisk),
      .gt_tx_com_strt_o(gt_tx_com_strt_o),
      .gt_tx_com_type_o(gt_tx_com_type_o),
      .gt_tx_elec_idle_o(gt_tx_elec_idle_o),
      .gt_rx_data_i(lnk_rx_tdata_o),
      .gt_rx_status_i(gt_rx_status_i)
    );

  end
  endgenerate


  always @(posedge clk_phy) begin
    gt_rx_data_sr[47:32] <= gt_rx_data_i;
    gt_rx_data_sr[31:0] <= gt_rx_data_sr[47:16];
  end


  always @(posedge clk_phy) begin
    gt_rx_k_sr[5:4] <= gt_rx_charisk_i;
    gt_rx_k_sr[3:0] <= gt_rx_k_sr[5:2];
  end


  always @(posedge clk_phy) begin
    gt_rx_err_sr[4] <= gt_rx_disp_err_i[0] | gt_rx_8b10b_err_i[0];
    gt_rx_err_sr[5] <= gt_rx_disp_err_i[1] | gt_rx_8b10b_err_i[1];
    gt_rx_err_sr[3:0] <= gt_rx_err_sr[5:2];
  end


  always @(negedge rst_n or posedge clk_phy) begin
    if(rst_n == 0) begin
      lnk_tx_tready <= 0;
    end else begin
      if(lnk_tx_tready == 0) begin
        lnk_tx_tready <= 1;
      end else begin
        lnk_tx_tready <= 0;
      end
    end
  end


  always @(*) begin
    if((lnk_tx_tvalid == 1) && (lnk_tx_tready == 1)) begin
      tx_data_mux_sel = 0;
    end else begin
      tx_data_mux_sel = 1;
    end
  end


  always @(negedge rst_n or posedge clk_phy) begin
    if(rst_n == 0) begin
      rx_data_mux_sel <= 0;
    end else begin
      if((gt_rx_k_sr[3:0] == 4'b0001) && (gt_rx_data_sr[31:0] == 32'h7B_4A_4A_BC)) begin
        rx_data_mux_sel <= 0;
      end else begin
        if((gt_rx_k_sr[4:1] == 4'b0001) && (gt_rx_data_sr[39:8] == 32'h7B_4A_4A_BC)) begin
          rx_data_mux_sel <= 1;
        end 
      end
    end
  end


  always @(negedge rst_n or posedge clk_phy) begin
    if(rst_n == 0) begin
      gt_rx_valid <= 0;
    end else begin
      if((gt_rx_charisk == 4'b0001) && (gt_rx_data == 32'h7B_4A_4A_BC)) begin
        gt_rx_valid <= 1;
      end else begin
        if(gt_rx_valid == 1) begin
          gt_rx_valid <= 0;
        end else begin
          gt_rx_valid <= 1;
        end
      end
    end
  end


  always @(posedge clk_phy) begin
    gt_rx_data_r <= gt_rx_data;
  end


  always @(posedge clk_phy) begin
    gt_rx_charisk_r <= gt_rx_charisk;
  end


  always @(posedge clk_phy) begin
    gt_rx_err_r <= gt_rx_err;
  end


endmodule

