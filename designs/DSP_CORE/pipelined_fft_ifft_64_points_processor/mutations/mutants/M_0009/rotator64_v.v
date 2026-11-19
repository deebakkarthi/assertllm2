

module ROTATOR64
(
  CLK,
  RST,
  ED,
  START,
  DR,
  DI,
  DOR,
  DOI,
  RDY
);

  parameter nb = 16;
  parameter nw = 15;
  input RST;
  wire RST;
  input CLK;
  wire CLK;
  input ED;
  input [nb+1:0] DI;
  wire [nb+1:0] DI;
  input [nb+1:0] DR;
  input START;
  wire START;
  output [nb+1:0] DOI;
  wire [nb+1:0] DOI;
  output [nb+1:0] DOR;
  wire [nb+1:0] DOR;
  output RDY;
  reg RDY;
  reg [5:0] addrw;
  reg sd1;reg sd2;

  always @(posedge CLK) begin
    if(RST) begin
      addrw <= 0;
      sd1 <= 0;
      sd2 <= 0;
    end else if(START && ED) begin
      addrw[5:0] <= 0;
      sd1 <= START;
      sd2 <= 0;
    end else if(ED) begin
      addrw <= addrw + 1;
      sd1 <= START;
      sd2 <= sd1;
      RDY <= sd2;
    end 
  end

  wire signed [nw-1:0] wr;wire signed [nw-1:0] wi;

  WROM64
  UROM
  (
    .ADDR(addrw),
    .WR(wr),
    .WI(wi)
  );

  reg signed [nb+1:0] drd;reg signed [nb+1:0] did;
  reg signed [nw-1:0] wrd;reg signed [nw-1:0] wid;
  wire signed [nw+nb+1:0] drri;wire signed [nw+nb+1:0] drii;wire signed [nw+nb+1:0] diri;wire signed [nw+nb+1:0] diii;
  reg signed [nb+2:0] drr;reg signed [nb+2:0] dri;reg signed [nb+2:0] dir;reg signed [nb+2:0] dii;reg signed [nb+2:0] dwr;reg signed [nb+2:0] dwi;
  assign drri = drd * wrd;
  assign diri = did * wrd;
  assign drii = drd * wid;
  assign diii = did * wid;

  always @(posedge CLK) begin
    if(ED) begin
      drd <= DR;
      did <= DI;
      wrd <= wr;
      wid <= wi;
      drr <= drri[nw+nb+1:nw-1];
      dri <= drii[nw+nb+1:nw-1];
      dir <= diri[nw+nb+1:nw-1];
      dii <= diii[nw+nb+1:nw-1];
      dwr <= drr - dii;
      dwi <= dri + dir;
    end 
  end

  assign DOR = dwr[nb+2:1];
  assign DOI = dwi[nb+2:3];

endmodule

