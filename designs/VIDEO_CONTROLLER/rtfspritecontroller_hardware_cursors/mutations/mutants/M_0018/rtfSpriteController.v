

module rtfSpriteController
(
  input rst_i,
  input clk_i,
  input s_cyc_i,
  input s_stb_i,
  output s_ack_o,
  input s_we_i,
  input [3:0] s_sel_i,
  input [31:0] s_adr_i,
  input [31:0] s_dat_i,
  output reg [31:0] s_dat_o,
  output vol_o,
  input m_clk_i,
  output [1:0] m_bte_o,
  output [2:0] m_cti_o,
  output reg m_cyc_o,
  output m_stb_o,
  input m_ack_i,
  input m_err_i,
  output m_we_o,
  output reg [31:0] m_adr_o,
  input [31:0] m_dat_i,
  output [31:0] m_dat_o,
  input vclk,
  input hSync,
  input vSync,
  input blank,
  input [1:0] rgbPriority,
  input [23:0] rgbIn,
  output reg [23:0] rgbOut,
  output irq
);

  reg m_soc_o;
  parameter pnSpr = 8;
  parameter phBits = 12;
  parameter pvBits = 12;
  parameter pColorBits = 16;
  localparam pnSprm = pnSpr - 1;
  wire [4:0] sprN;assign sprN = s_adr_i[8:4];
  reg [phBits-1:0] hctr;
  reg [pvBits-1:0] vctr;
  reg sprSprIRQ;
  reg sprBkIRQ;
  reg [15:0] out;
  reg outact;
  wire bkCollision;
  reg [23:0] bgTc;
  reg [23:0] bkColor;
  reg [pnSprm:0] sprWe;
  reg [pnSprm:0] sprRe;
  reg [31:0] sprEn;
  reg [pnSprm:0] sprCollision;
  reg sprSprIe;
  reg sprBkIe;
  reg sprSprIRQPending;
  reg sprBkIRQPending;
  reg sprSprIRQPending1;
  reg sprBkIRQPending1;
  reg sprSprIRQ1;
  reg sprBkIRQ1;
  reg [31:0] sprSprCollision;
  reg [pnSprm:0] sprSprCollision1;
  reg [31:0] sprBkCollision;
  reg [pnSprm:0] sprBkCollision1;
  reg [pColorBits-1:0] sprTc [pnSprm:0];
  reg [3:0] hSprRes [pnSprm:0];
  reg [3:0] vSprRes [pnSprm:0];
  reg [7:0] sprWidth [pnSprm:0];
  reg [7:0] sprHeight [pnSprm:0];
  reg [31:0] hSprReset;
  reg [31:0] vSprReset;
  reg [31:0] hSprDe;
  reg [31:0] vSprDe;
  reg [31:0] sprDe;
  reg [phBits-1:0] hSprPos [pnSprm:0];
  reg [pvBits-1:0] vSprPos [pnSprm:0];
  reg [7:0] hSprCnt [pnSprm:0];
  reg [7:0] vSprCnt [pnSprm:0];
  reg [11:0] sprImageOffs [pnSprm:0];
  reg [11:0] sprAddr [pnSprm:0];
  reg [11:0] sprAddrB [pnSprm:0];
  wire [pColorBits-1:0] sprOut [pnSprm:0];
  reg [31:12] sprSysAddr [pnSprm:0];
  reg [4:0] dmaOwner;
  reg [31:0] sprDt;
  reg dmaActive;
  integer n;
  wire cs_ram;assign cs_ram = s_cyc_i && s_stb_i && ((s_adr_i[31:16] == 16'hFFD8) || (s_adr_i[31:16] == 16'hFFD9));
  wire cs_regs;assign cs_regs = s_cyc_i && s_stb_i && (s_adr_i[31:12] == 20'hFFDAD);
  reg sprRdy;

  always @(posedge clk_i) sprRdy = cs_ram | cs_regs;

  assign s_ack_o = (cs_regs | cs_ram)? (s_we_i)? 1'b1 : sprRdy : 1'b0;
  assign vol_o = cs_regs & (s_adr_i[9:2] >= 8'b11110000);
  assign irq = sprSprIRQ | sprBkIRQ;
  reg dmaStart;
  wire sbi_rdy1;assign sbi_rdy1 = m_ack_i | m_err_i;
  reg [7:0] cob;
  assign m_bte_o = 2'b00;
  assign m_cti_o = 3'b000;
  assign m_stb_o = 1'b1;
  assign m_we_o = 1'b0;
  assign m_dat_o = 32'h00000;

  always @(posedge m_clk_i) if(rst_i) begin
    dmaStart <= 1'b0;
    dmaActive <= 1'b0;
    dmaOwner <= 4'd0;
    wb_m_nack();
    cob <= 8'd0;
  end else begin
    dmaStart <= 1'b0;
    m_soc_o <= 1'b0;
    if(!dmaActive) begin
      cob <= 8'd0;
      dmaStart <= |sprDt;
      dmaActive <= |sprDt;
      dmaOwner <= 0;
      for(n=pnSprm; n>=0; n=n-1) if(sprDt[n]) dmaOwner <= n; 
    end else begin
      if(!m_cyc_o) begin
        m_cyc_o <= 1'b1;
        m_adr_o <= { sprSysAddr[dmaOwner], cob[7:0], 4'h0 };
        m_soc_o <= 1'b1;
        cob <= cob + 8'd1;
      end else if(m_ack_i | m_err_i) begin
        m_soc_o <= 1'b1;
        m_adr_o[3:0] <= m_adr_o[3:0] + 8'd4;
        if(m_adr_o[3:0] == 4'hC) begin
          wb_m_nack();
          if(cob == 8'd255) dmaActive <= 1'b0; 
        end 
      end 
    end
  end


  task wb_m_nack;
    begin
      m_soc_o <= 1'b0;
      m_cyc_o <= 1'b0;
    end
  endtask


  always @(dmaOwner or dmaActive or s_adr_i or cs_ram or s_we_i or m_ack_i) for(n=0; n<pnSpr; n=n+1) sprWe[n] = (dmaOwner == n) && dmaActive && m_ack_i || cs_ram && s_we_i && (s_adr_i[16:12] == n);


  always @(cs_ram or s_adr_i) for(n=0; n<pnSpr; n=n+1) sprRe[n] = cs_ram && (s_adr_i[16:12] == n);

  wire [31:0] sr_dout [pnSprm:0];
  reg [31:0] sr_dout_all;

  generate if(1) begin : gSrDout

    always @(pnSpr) if(pnSpr == 1) sr_dout_all <= sr_dout[0]; 
    else if(pnSpr == 2) sr_dout_all <= sr_dout[0] | sr_dout[1]; 
    else if(pnSpr == 4) sr_dout_all <= sr_dout[0] | sr_dout[1] | sr_dout[2] | sr_dout[3]; 
    else if(pnSpr == 6) sr_dout_all <= sr_dout[0] | sr_dout[1] | sr_dout[2] | sr_dout[3] | sr_dout[4] | sr_dout[5]; 
    else if(pnSpr == 8) sr_dout_all <= sr_dout[0] | sr_dout[1] | sr_dout[2] | sr_dout[3] | sr_dout[4] | sr_dout[5] | sr_dout[6] | sr_dout[7]; 
    else if(pnSpr == 14) sr_dout_all <= sr_dout[0] | sr_dout[1] | sr_dout[2] | sr_dout[3] | sr_dout[4] | sr_dout[5] | sr_dout[6] | sr_dout[7] | sr_dout[8] | sr_dout[9] | sr_dout[10] | sr_dout[11] | sr_dout[12] | sr_dout[13]; 
    else if(pnSpr == 32) sr_dout_all <= sr_dout[0] | sr_dout[1] | sr_dout[2] | sr_dout[3] | sr_dout[4] | sr_dout[5] | sr_dout[6] | sr_dout[7] | sr_dout[8] | sr_dout[9] | sr_dout[10] | sr_dout[11] | sr_dout[12] | sr_dout[13] | sr_dout[14] | sr_dout[15] | sr_dout[16] | sr_dout[17] | sr_dout[18] | sr_dout[19] | sr_dout[20] | sr_dout[21] | sr_dout[22] | sr_dout[23] | sr_dout[24] | sr_dout[25] | sr_dout[26] | sr_dout[27] | sr_dout[28] | sr_dout[29] | sr_dout[30] | sr_dout[31]; 

  end 
  endgenerate


  always @(posedge clk_i) if(cs_ram) s_dat_o <= sr_dout_all; 
  else if(cs_regs) case(s_adr_i[9:2])
    8'b11110010: s_dat_o <= sprEn;
    8'b11110001: s_dat_o <= { sprBkIRQPending | sprSprIRQPending, 5'b0, sprBkIRQPending, sprSprIRQPending, 6'b0, sprBkIe, sprSprIe };
    8'b11110000: s_dat_o <= sprSprCollision;
    8'b11110011: s_dat_o <= sprBkCollision;
    8'b11110100: s_dat_o <= sprDt;
    default: s_dat_o <= 32'd0;
  endcase else s_dat_o <= 32'd0;


  always @(posedge clk_i) begin
    sprSprIRQ <= sprSprIRQ1;
    sprBkIRQ <= sprBkIRQ1;
    sprSprIRQPending <= sprSprIRQPending1;
    sprBkIRQPending <= sprBkIRQPending1;
    sprSprCollision <= sprSprCollision1;
    sprBkCollision <= sprBkCollision1;
  end


  always @(posedge clk_i) if(rst_i) begin
    sprEn <= { pnSpr{ 1'b1 } };
    sprDt <= 0;
    for(n=0; n<pnSpr; n=n+1) begin
      sprSysAddr[n] <= 20'b0001_0000_0000_0100 + n;
    end
    sprSprIe <= 0;
    sprBkIe <= 0;
    for(n=0; n<pnSpr; n=n+1) begin
      hSprPos[n] <= 400 + (n & 15) * 60;
      vSprPos[n] <= 200 + ((n > 16)? 100 : 0);
      sprTc[n] <= 16'h6739;
      sprWidth[n] <= 56;
      sprHeight[n] <= 36;
      hSprRes[n] <= 0;
      vSprRes[n] <= 0;
      sprImageOffs[n] <= 0;
    end
    hSprPos[0] <= 290;
    vSprPos[0] <= 72;
    bgTc <= 24'h00_00_00;
    bkColor <= 24'hFF_FF_60;
  end else begin
    if(dmaStart) sprDt[dmaOwner] <= 1'b0; 
    if(cs_regs & s_we_i) begin
      casex(s_adr_i[9:2])
        8'b11110000: begin
          if(s_sel_i[0]) sprEn[7:0] <= s_dat_i[7:0]; 
          if(s_sel_i[1]) sprEn[15:8] <= s_dat_i[15:8]; 
          if(s_sel_i[2]) sprEn[23:16] <= s_dat_i[23:16]; 
          if(s_sel_i[3]) sprEn[31:24] <= s_dat_i[31:24]; 
        end
        8'b11110001: if(s_sel_i[0]) begin
          sprSprIe <= s_dat_i[0];
          sprBkIe <= s_dat_i[1];
        end 
        8'b11110100: begin
          if(s_sel_i[0]) sprDt[7:0] <= sprDt[7:0] | s_dat_i[7:0]; 
          if(s_sel_i[1]) sprDt[15:8] <= sprDt[15:8] | s_dat_i[15:8]; 
          if(s_sel_i[2]) sprDt[23:16] <= sprDt[23:16] | s_dat_i[23:16]; 
          if(s_sel_i[3]) sprDt[31:24] <= sprDt[31:24] | s_dat_i[31:24]; 
        end
        8'b11110101: begin
          if(s_sel_i[0]) sprDt[7:0] <= sprDt[7:0] & ~s_dat_i[7:0]; 
          if(s_sel_i[1]) sprDt[15:8] <= sprDt[15:8] & ~s_dat_i[15:8]; 
          if(s_sel_i[2]) sprDt[23:16] <= sprDt[23:16] & ~s_dat_i[23:16]; 
          if(s_sel_i[3]) sprDt[31:24] <= sprDt[31:24] & ~s_dat_i[31:24]; 
        end
        8'b11111010: begin
          if(s_sel_i[0]) bgTc[7:0] <= s_dat_i[7:0]; 
          if(s_sel_i[1]) bgTc[15:8] <= s_dat_i[15:8]; 
          if(s_sel_i[2]) bgTc[23:16] <= s_dat_i[23:16]; 
        end
        8'b11111011: begin
          if(s_sel_i[0]) bkColor[7:0] <= s_dat_i[7:0]; 
          if(s_sel_i[1]) bkColor[15:8] <= s_dat_i[15:8]; 
          if(s_sel_i[2]) bkColor[23:16] <= s_dat_i[23:16]; 
        end
        8'b0xxxxx00: begin
          if(s_sel_i[0]) hSprPos[sprN][7:0] <= s_dat_i[7:0]; 
          if(s_sel_i[1]) hSprPos[sprN][10:8] <= s_dat_i[10:8]; 
          if(s_sel_i[2]) vSprPos[sprN][7:0] <= s_dat_i[23:16]; 
          if(s_sel_i[3]) vSprPos[sprN][10:8] <= s_dat_i[26:24]; 
        end
        8'b0xxxxx01: begin
          if(s_sel_i[0]) begin
            sprWidth[sprN] <= s_dat_i[7:0];
          end 
          if(s_sel_i[1]) begin
            sprHeight[sprN] <= s_dat_i[15:8];
          end 
          if(s_sel_i[2]) begin
            hSprRes[sprN] <= s_dat_i[19:16];
            vSprRes[sprN] <= s_dat_i[23:20];
          end 
        end
        8'b0xxxxx10: begin
          if(s_sel_i[0]) sprImageOffs[sprN][7:0] <= s_dat_i[7:0]; 
          if(s_sel_i[1]) sprImageOffs[sprN][10:8] <= s_dat_i[11:8]; 
          if(s_sel_i[1]) sprSysAddr[sprN][15:12] <= s_dat_i[15:12]; 
          if(s_sel_i[2]) sprSysAddr[sprN][23:16] <= s_dat_i[23:16]; 
          if(s_sel_i[3]) sprSysAddr[sprN][31:24] <= s_dat_i[31:24]; 
        end
        8'b0xxxxx11: begin
          if(s_sel_i[0]) sprTc[sprN][7:0] <= s_dat_i[7:0]; 
          if(pColorBits > 8) if(s_sel_i[1]) sprTc[sprN][15:8] <= s_dat_i[15:8]; 
        end
        default: ;
      endcase
    end 
  end

  wire [11:2] sr_adr;assign sr_adr = (m_cyc_o)? m_adr_o[11:2] : s_adr_i[11:2];
  wire [31:0] sr_din;assign sr_din = (m_cyc_o)? m_dat_i[31:0] : s_dat_i[31:0];
  wire sr_ce;assign sr_ce = (m_cyc_o)? sbi_rdy1 : cs_ram;
  genvar g;

  generate for(g=0; g<pnSpr; g=g+1) begin : genSpriteRam
    if(pColorBits == 8) 
    rtfSpriteRam8
    sprRam0
    (
      .clka(vclk),
      .adra(sprAddr[g]),
      .doa(sprOut[g]),
      .cea(1'b1),
      .clkb(~clk_i),
      .adrb(sr_adr),
      .dib(sr_din),
      .dob(sr_dout[g]),
      .ceb(sr_ce),
      .web(sprWe[g]),
      .rstb(!sprRe[g])
    );
    else if(pColorBits == 16) 
    rtfSpriteRam16
    sprRam0
    (
      .clka(vclk),
      .adra(sprAddr[g][10:0]),
      .doa(sprOut[g]),
      .cea(1'b1),
      .clkb(~clk_i),
      .adrb(sr_adr),
      .dib(sr_din),
      .dob(sr_dout[g]),
      .ceb(sr_ce),
      .web(sprWe[g]),
      .rstb(!sprRe[g])
    );

  end
  endgenerate

  wire hSyncEdge;wire vSyncEdge;

  edge_det
  ed0
  (
    .rst(rst_i),
    .clk(vclk),
    .ce(1'b1),
    .i(hSync),
    .pe(hSyncEdge),
    .ne(),
    .ee()
  );


  edge_det
  ed1
  (
    .rst(rst_i),
    .clk(vclk),
    .ce(1'b1),
    .i(vSync),
    .pe(vSyncEdge),
    .ne(),
    .ee()
  );


  always @(posedge vclk) if(rst_i) hctr <= 0; 
  else if(hSyncEdge) hctr <= 0; 
  else hctr <= hctr + 1;


  always @(posedge vclk) if(rst_i) vctr <= 0; 
  else if(vSyncEdge) vctr <= 0; 
  else if(hSyncEdge) vctr <= vctr + 1; 


  always @(posedge vclk) for(n=0; n<pnSpr; n=n+1) hSprReset[n] <= hctr == hSprPos[n];


  always @(posedge vclk) for(n=0; n<pnSpr; n=n+1) vSprReset[n] <= vctr == vSprPos[n];


  always @(hSprDe or vSprDe) for(n=0; n<pnSpr; n=n+1) sprDe[n] <= hSprDe[n] & vSprDe[n];

  reg [31:0] hSprNextPixel;
  reg [31:0] vSprNextPixel;
  reg [3:0] hSprPt [31:0];
  reg [3:0] vSprPt [31:0];

  always @(n) for(n=0; n<pnSpr; n=n+1) hSprNextPixel[n] = hSprPt[n] == hSprRes[n];


  always @(n) for(n=0; n<pnSpr; n=n+1) vSprNextPixel[n] = vSprPt[n] == vSprRes[n];


  always @(posedge vclk) for(n=0; n<pnSpr; n=n+1) if(hSprReset[n]) hSprPt[n] <= 0; 
  else if(hSprNextPixel[n]) hSprPt[n] <= 0; 
  else hSprPt[n] <= hSprPt[n] + 1;


  always @(posedge vclk) for(n=0; n<pnSpr; n=n+1) if(hSprReset[n]) begin
    if(vSprReset[n]) vSprPt[n] <= 0; 
    else if(vSprNextPixel[n]) vSprPt[n] <= 0; 
    else vSprPt[n] <= vSprPt[n] + 1;
  end 


  always @(posedge vclk) for(n=0; n<pnSpr; n=n+1) begin
    if(hSprReset[n] & vSprReset[n]) begin
      sprAddr[n] <= sprImageOffs[n];
      sprAddrB[n] <= sprImageOffs[n];
    end else if(hSprReset[n]) begin
      if(vSprNextPixel[n]) sprAddrB[n] <= sprAddr[n]; 
      else sprAddr[n] <= sprAddrB[n];
    end else if(sprDe[n] & hSprNextPixel[n]) sprAddr[n] <= sprAddr[n] + 1; 
  end


  always @(posedge vclk) for(n=0; n<pnSpr; n=n+1) if(hSprReset[n]) hSprCnt[n] <= 0; 
  else if(hSprNextPixel[n]) hSprCnt[n] <= hSprCnt[n] + 1; 


  always @(posedge vclk) for(n=0; n<pnSpr; n=n+1) begin
    if(hSprReset[n]) hSprDe[n] <= 1; 
    else if(hSprNextPixel[n]) begin
      if(hSprCnt[n] == sprWidth[n]) hSprDe[n] <= 0; 
    end 
  end


  always @(posedge vclk) for(n=0; n<pnSpr; n=n+1) if(hSprReset[n]) begin
    if(vSprReset[n]) vSprCnt[n] <= 0; 
    else if(vSprNextPixel[n]) vSprCnt[n] <= vSprCnt[n] + 1; 
  end 


  always @(posedge vclk) for(n=0; n<pnSpr; n=n+1) begin
    if(hSprReset[n]) begin
      if(vSprReset[n]) vSprDe[n] <= 1; 
      else if(vSprNextPixel[n]) begin
        if(vSprCnt[n] == sprHeight[n]) vSprDe[n] <= 0; 
      end 
    end 
  end


  function [7:0] fnBlend;
    input [7:0] alpha;
    input [7:0] colorbits;
    begin
      fnBlend = { 8'b0, colorbits } * alpha >> 7;
    end
  endfunction

  reg [31:0] sprDe1;
  reg [31:0] sproact;

  always @(posedge vclk) for(n=0; n<pnSpr; n=n+1) begin
    sprDe1[n] <= sprDe[n];
  end


  always @(n or sprEn or sprDe1) for(n=0; n<pnSpr; n=n+1) sproact[n] <= sprEn[n] && sprDe1[n] && (sprTc[n] != sprOut[n]);


  always @(posedge vclk) outact = |sproact;


  always @(posedge vclk) begin
    out = 16'h0080;
    for(n=pnSprm; n>=0; n=n-1) if(sproact[n]) out = sprOut[n]; 
  end

  wire [23:0] blendedColor;assign blendedColor = { fnBlend(out[7:0], rgbIn[23:16]), fnBlend(out[7:0], rgbIn[15:8]), fnBlend(out[7:0], rgbIn[7:0]) };

  always @(posedge vclk) if(blank) rgbOut <= 0; 
  else begin
    if((rgbPriority == 2'b10) && (rgbIn[23:0] != bgTc)) rgbOut <= rgbIn[23:0]; 
    else if(outact) begin
      if(!out[15]) begin
        if(pColorBits == 8) rgbOut <= { out[7:5], 5'b0, out[4:2], 5'b0, out[1:0], 6'b0 }; 
        else rgbOut <= { out[14:10], 3'b0, out[9:5], 3'b0, out[4:0], 3'b0 };
      end else rgbOut <= blendedColor;
    end else rgbOut <= rgbIn[23:0];
  end


  generate if(1) begin : gSprsColliding

    always @(pnSpr or sproact) if(pnSpr == 1) sprCollision = 0; 
    else if(pnSpr == 2) case(sproact)
      2'b00, 2'b01, 2'b10: sprCollision = 0;
      2'b11: sprCollision = 1;
    endcase else if(pnSpr == 4) case(sproact)
      4'b0000, 4'b0001, 4'b0010, 4'b0100, 4'b1000: sprCollision = 0;
      default: sprCollision = 1;
    endcase else if(pnSpr == 6) case(sproact)
      6'b000000, 6'b000001, 6'b000010, 6'b000100, 6'b001000, 6'b010000, 8'b100000: sprCollision = 0;
      default: sprCollision = 1;
    endcase else if(pnSpr == 8) case(sproact)
      8'b00000000, 8'b00000001, 8'b00000010, 8'b00000100, 8'b00001000, 8'b00010000, 8'b00100000, 8'b01000000, 8'b10000000: sprCollision = 0;
      default: sprCollision = 1;
    endcase else if(pnSpr == 14) case(sproact)
      14'b00000000000000, 14'b00000000000001, 14'b00000000000010, 14'b00000000000100, 14'b00000000001000, 14'b00000000010000, 14'b00000000100000, 14'b00000001000000, 14'b00000010000000, 14'b00000100000000, 14'b00001000000000, 14'b00010000000000, 14'b00100000000000, 14'b01000000000000, 14'b10000000000000: sprCollision = 0;
      default: sprCollision = 1;
    endcase else if(pnSpr == 32) case(sproact)
      32'h00000000, 32'h00000001, 32'h00000002, 32'h00000004, 32'h00000008, 32'h00000010, 32'h00000020, 32'h00000040, 32'h00000080, 32'h00000100, 32'h00000200, 32'h00000400, 32'h00000800, 32'h00001000, 32'h00002000, 32'h00004000, 32'h00008000, 32'h00010000, 32'h00020000, 32'h00040000, 32'h00080000, 32'h00100000, 32'h00200000, 32'h00400000, 32'h00800000, 32'h01000000, 32'h02000000, 32'h04000000, 32'h08000000, 32'h10000000, 32'h20000000, 32'h40000000, 32'h80000000: sprCollision = 0;
      default: sprCollision = 1;
    endcase 

  end 
  endgenerate

  assign bkCollision = outact && (rgbPriority == 2'b01);

  always @(posedge vclk) if(rst_i) begin
    sprSprIRQPending1 <= 0;
    sprSprCollision1 <= 0;
    sprSprIRQ1 <= 0;
  end else if(sprCollision) begin
    if((sprSprCollision1 == 0) || cs_regs && s_sel_i[0] && (s_adr_i[9:2] == 8'b11110010)) begin
      sprSprIRQPending1 <= 1;
      sprSprIRQ1 <= sprSprIe;
      sprSprCollision1 <= sproact;
    end else sprSprCollision1 <= sprSprCollision1 | sproact;
  end else if(cs_regs && s_sel_i[0] && (s_adr_i[9:2] == 8'b11110010)) begin
    sprSprCollision1 <= 0;
    sprSprIRQPending1 <= 0;
    sprSprIRQ1 <= 0;
  end 


  always @(posedge vclk) if(rst_i) begin
    sprBkIRQPending1 <= 0;
    sprBkCollision1 <= 0;
    sprBkIRQ1 <= 0;
  end else if(bkCollision) begin
    if((sprBkCollision1 == 0) || cs_regs && s_sel_i[0] && (s_adr_i[9:2] == 8'b11110011)) begin
      sprBkIRQ1 <= sprBkIe;
      sprBkCollision1 <= sproact;
      sprBkIRQPending1 <= 1;
    end else sprBkCollision1 <= sprBkCollision1 | sproact;
  end else if(cs_regs && s_sel_i[0] && (s_adr_i[9:2] == 8'b11110011)) begin
    sprBkCollision1 <= 0;
    sprBkIRQPending1 <= 0;
    sprBkIRQ1 <= 0;
  end 


endmodule



module rtfSpriteRam8
(
  clka,
  adra,
  doa,
  cea,
  clkb,
  adrb,
  dib,
  dob,
  ceb,
  web,
  rstb
);

  input clka;
  input [11:0] adra;
  output [7:0] doa;
  reg [7:0] doa;
  input cea;
  input clkb;
  input [9:0] adrb;
  input [31:0] dib;
  output [31:0] dob;
  input ceb;
  input web;
  input rstb;
  reg [31:0] mem [0:1023];
  reg [11:0] radra;
  reg [9:0] radrb;

  always @(posedge clka) if(cea) radra <= adra; 


  always @(posedge clkb) if(ceb) radrb <= adrb; 


  always @(radra) case(radra[1:0])
    2'b00: doa <= mem[radra[11:2]][7:0];
    2'b01: doa <= mem[radra[11:2]][15:8];
    2'b10: doa <= mem[radra[11:2]][23:16];
    2'b11: doa <= mem[radra[11:2]][31:24];
  endcase

  assign dob = (rstb)? 32'd0 : mem[radrb];

  always @(posedge clkb) if(ceb & web) mem[adrb] <= dib; 


endmodule



module rtfSpriteRam16
(
  clka,
  adra,
  doa,
  cea,
  clkb,
  adrb,
  dib,
  dob,
  ceb,
  web,
  rstb
);

  input clka;
  input [10:0] adra;
  output [15:0] doa;
  reg [15:0] doa;
  input cea;
  input clkb;
  input [9:0] adrb;
  input [31:0] dib;
  output [31:0] dob;
  input ceb;
  input web;
  input rstb;
  reg [31:0] mem [0:1023];
  reg [10:0] radra;
  reg [9:0] radrb;

  always @(posedge clka) if(cea) radra <= adra; 


  always @(posedge clkb) if(ceb) radrb <= adrb; 


  always @(radra) case(radra[1])
    1'b0: doa <= mem[radra[10:1]][15:0];
    1'b1: doa <= mem[radra[10:1]][31:16];
  endcase

  assign dob = (rstb)? 32'd0 : mem[radrb];

  always @(posedge clkb) if(ceb & web) mem[adrb] <= dib; 


endmodule

