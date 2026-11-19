

module rtfTextController
(
  rst_i,
  clk_i,
  cyc_i,
  stb_i,
  ack_o,
  we_i,
  sel_i,
  adr_i,
  dat_i,
  dat_o,
  lp,
  curpos,
  vclk,
  eol,
  eof,
  blank,
  border,
  rgbIn,
  rgbOut
);

  parameter COLS = 12'd56;
  parameter ROWS = 12'd31;
  input rst_i;
  input clk_i;
  input cyc_i;
  input stb_i;
  output ack_o;
  input we_i;
  input [1:0] sel_i;
  input [63:0] adr_i;
  input [15:0] dat_i;
  output [15:0] dat_o;
  reg [15:0] dat_o;
  input lp;
  input [15:0] curpos;
  input vclk;
  input eol;
  input eof;
  input blank;
  input border;
  input [24:0] rgbIn;
  output [24:0] rgbOut;reg [24:0] rgbOut;
  wire [23:0] bkColor24;
  wire [23:0] fgColor24;
  wire [23:0] tcColor24;
  wire pix;
  reg [15:0] rego;
  reg [11:0] windowTop;
  reg [11:0] windowLeft;
  reg [11:0] numCols;
  reg [11:0] numRows;
  reg [1:0] mode;
  reg [4:0] maxScanline;
  reg [4:0] maxScanpix;
  reg [4:0] cursorStart;reg [4:0] cursorEnd;
  reg [15:0] cursorPos;
  reg [15:0] startAddress;
  reg [2:0] rBlink;
  reg [3:0] bdrColorReg;
  reg [3:0] pixelWidth;
  reg [3:0] pixelHeight;
  wire [11:0] hctr;
  wire [11:0] scanline;
  wire [11:0] row;
  wire [11:0] col;
  reg [4:0] rowscan;
  wire nxt_row;
  wire nxt_col;
  wire [5:0] bcnt;
  wire blink;
  reg iblank;
  wire nhp;
  wire ld_shft;assign ld_shft = nxt_col & nhp;
  reg [15:0] txtAddr;
  reg [15:0] penAddr;
  wire [8:0] txtOut;
  wire [8:0] charOut;
  wire [3:0] txtBkCode;
  wire [4:0] txtFgCode;
  reg [4:0] txtTcCode;
  reg bgt;
  wire [8:0] tdat_o;
  wire [8:0] cdat_o;
  wire [8:0] chdat_o;
  wire [2:0] scanindex;assign scanindex = scanline[2:0];
  wire cs_text;assign cs_text = cyc_i && stb_i && (adr_i[63:16] == 48'hFFFF_FFFF_FFD0);
  wire cs_color;assign cs_color = cyc_i && stb_i && (adr_i[63:16] == 48'hFFFF_FFFF_FFD1);
  wire cs_rom;assign cs_rom = cyc_i && stb_i && (adr_i[63:16] == 48'hFFFF_FFFF_FFD2);
  wire cs_reg;assign cs_reg = cyc_i && stb_i && (adr_i[63:8] == 56'hFFFF_FFFF_FFDA_00);
  wire cs_any;assign cs_any = cs_text | cs_color | cs_rom | cs_reg;

  always @(posedge clk_i) if(cs_text) dat_o <= tdat_o; 
  else if(cs_color) dat_o <= cdat_o; 
  else if(cs_rom) dat_o <= chdat_o; 
  else if(cs_reg) dat_o <= rego; 
  else dat_o <= 16'h0000;

  wire [17:0] rowcol;assign rowcol = row * numCols;

  always @(posedge vclk) txtAddr <= startAddress + rowcol + col;


  syncRam4kx9_1rw1r
  textRam0
  (
    .wclk(clk_i),
    .wadr(adr_i[13:1]),
    .i(dat_i),
    .wo(tdat_o),
    .wce(cs_text),
    .we(we_i),
    .wrst(1'b0),
    .rclk(vclk),
    .radr(txtAddr[12:0]),
    .o(txtOut),
    .rce(ld_shft),
    .rrst(1'b0)
  );


  syncRam4kx9_1rw1r
  colorRam0
  (
    .wclk(clk_i),
    .wadr(txtAddr[12:0]),
    .i(dat_i),
    .wo(cdat_o),
    .wce(cs_color),
    .we(we_i),
    .wrst(1'b0),
    .rclk(vclk),
    .radr(adr_i[13:1]),
    .o({ txtBkCode, txtFgCode }),
    .rce(ld_shft),
    .rrst(1'b0)
  );


  syncRam4kx9_1rw1r
  charRam0
  (
    .wclk(clk_i),
    .wadr(adr_i[11:0]),
    .i(dat_i),
    .wo(chdat_o),
    .wce(cs_rom),
    .we(1'b0),
    .wrst(1'b0),
    .rclk(vclk),
    .radr({ txtOut, rowscan[2:0] }),
    .o(charOut),
    .rce(ld_shft),
    .rrst(1'b0)
  );

  reg [3:0] txtBkCode1;
  reg [4:0] txtFgCode1;

  always @(posedge vclk) if(nhp & ld_shft) txtBkCode1 <= txtBkCode; 


  always @(posedge vclk) if(nhp & ld_shft) txtFgCode1 <= txtFgCode; 

  reg ramRdy;reg ramRdy1;

  always @(posedge clk_i) begin
    ramRdy1 <= cs_any & !(ramRdy1 | ramRdy);
    ramRdy <= ramRdy1 & cs_any;
  end

  assign ack_o = (cyc_i & stb_i)? (we_i)? cs_any : ramRdy : 1'b0;
  wire lpe;
  wire edge_det_fall;wire edge_det_both;

  edge_det
  u1
  (
    .clk(clk_i),
    .rstn(~rst_i),
    .dat_i(lp),
    .edge_rising(lpe),
    .edge_falling(edge_det_fall),
    .edge_both(edge_det_both)
  );


  always @(posedge clk_i) if(rst_i) penAddr <= 32'h0000_0000; 
  else begin
    if(lpe) penAddr <= txtAddr; 
  end


  always @(cs_reg or cursorPos or penAddr or adr_i) if(cs_reg) begin
    case(adr_i[4:1])
      4'd0: rego <= numCols;
      4'd1: rego <= numRows;
      4'd11: rego <= cursorPos;
      4'd12: rego <= penAddr;
      default: rego <= 16'h0000;
    endcase
  end else rego <= 16'h0000;

  reg interlace;

  always @(posedge clk_i) if(rst_i) begin
    windowTop <= 12'd12;
    windowLeft <= 12'd128;
    pixelWidth <= 4'd2;
    pixelHeight <= 4'd2;
    numCols <= COLS;
    numRows <= ROWS;
    maxScanline <= 5'd7;
    maxScanpix <= 5'd7;
    rBlink <= 3'b111;
    startAddress <= 16'h0000;
    cursorStart <= 5'd00;
    cursorEnd <= 5'd31;
    cursorPos <= 16'h0003;
    txtTcCode <= 5'd31;
  end else begin
    if(cs_reg & we_i) begin
      case(adr_i[4:1])
        4'd00: numCols <= dat_i;
        4'd01: numRows <= dat_i;
        4'd02: windowLeft <= dat_i[11:0];
        4'd03: windowTop <= dat_i[11:0];
        4'd04: maxScanline <= dat_i[4:0];
        4'd05: begin
          pixelHeight <= dat_i[7:4];
          pixelWidth <= dat_i[3:0];
        end
        4'd07: txtTcCode <= dat_i[4:0];
        4'd08: begin
          cursorStart <= dat_i[4:0];
          rBlink <= dat_i[7:5];
        end
        4'd09: cursorEnd <= dat_i[4:0];
        4'd10: startAddress <= dat_i;
        4'd11: cursorPos <= dat_i;
      endcase
    end 
  end

  reg [7:0] curout;

  always @(scanindex) case(scanindex)
    3'd0: curout = 8'b11111111;
    3'd1: curout = 8'b10000001;
    3'd2: curout = 8'b10000001;
    3'd3: curout = 8'b10000001;
    3'd4: curout = 8'b10000001;
    3'd5: curout = 8'b10000001;
    3'd6: curout = 8'b10011001;
    3'd7: curout = 8'b11111111;
  endcase


  HVCounter
  uhv1
  (
    .rst(rst_i),
    .vclk(vclk),
    .pixcce(1'b1),
    .sync(eol),
    .cnt_offs(windowLeft),
    .pixsz(pixelWidth),
    .maxpix(maxScanpix),
    .nxt_pix(nhp),
    .pos(col),
    .nxt_pos(nxt_col),
    .ctr(hctr)
  );


  HVCounter
  uhv2
  (
    .rst(rst_i),
    .vclk(vclk),
    .pixcce(eol),
    .sync(eof),
    .cnt_offs(windowTop),
    .pixsz(pixelHeight),
    .maxpix(maxScanline),
    .nxt_pix(nvp),
    .pos(row),
    .nxt_pos(nxt_row),
    .ctr(scanline)
  );


  always @(posedge vclk) rowscan <= scanline - row * (maxScanline + 1);


  VT163
  #(
    6
  )
  ub1
  (
    .clk(vclk),
    .clr_n(!rst_i),
    .ent(eol & eof),
    .enp(1'b1),
    .ld_n(1'b1),
    .d(6'd0),
    .q(bcnt)
  );

  wire blink_en;assign blink_en = (cursorPos + 2 == txtAddr) && (scanline[4:0] >= cursorStart) && (scanline[4:0] <= cursorEnd);

  VT151
  ub2
  (
    .e_n(!blink_en),
    .s(rBlink),
    .i0(1'b1),
    .i1(1'b0),
    .i2(bcnt[4]),
    .i3(bcnt[5]),
    .i4(1'b1),
    .i5(1'b0),
    .i6(bcnt[4]),
    .i7(bcnt[5]),
    .z(blink),
    .z_n()
  );


  rtfColorROM
  ucm1
  (
    .clk(vclk),
    .ce(nhp & ld_shft),
    .code(txtBkCode1),
    .color(bkColor24)
  );


  rtfColorROM
  ucm2
  (
    .clk(vclk),
    .ce(nhp & ld_shft),
    .code(txtFgCode1),
    .color(fgColor24)
  );


  always @(posedge vclk) if(nhp & ld_shft) bgt <= { 1'b0, txtBkCode1 } == txtTcCode; 

  wire [7:0] charRev;assign charRev = { charOut[0], charOut[1], charOut[2], charOut[3], charOut[4], charOut[5], charOut[6], charOut[7] };
  wire [7:0] charout1;assign charout1 = (blink)? charRev ^ curout : charRev;

  ParallelToSerial
  ups1
  (
    .rst(rst_i),
    .clk(vclk),
    .ce(nhp),
    .ld(ld_shft),
    .qin(1'b0),
    .d(charout1),
    .qh(pix)
  );

  wire bpix;assign bpix = hctr[1] ^ scanline[4];

  always @(posedge vclk) if(nhp) iblank <= (row >= numRows) || (col >= numCols + 2) || (col < 2); 


  always @(posedge vclk) if(nhp) begin
    casex({ blank, iblank, border, bpix, pix })
      5'b1xxxx: rgbOut <= 25'h0000000;
      5'b01xxx: rgbOut <= rgbIn;
      5'b0010x: rgbOut <= 24'hBF2020;
      5'b0011x: rgbOut <= 24'hDFDFDF;
      5'b000x0: rgbOut <= (bgt)? rgbIn : bkColor24;
      5'b000x1: rgbOut <= fgColor24;
      default: rgbOut <= rgbIn;
    endcase
  end 


endmodule

