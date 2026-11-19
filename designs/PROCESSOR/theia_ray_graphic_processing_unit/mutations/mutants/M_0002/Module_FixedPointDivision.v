

module SignedIntegerDivision
(
  input wire Clock,
  input Reset,
  input wire [32-1:0] iDividend,
  input [32-1:0] iDivisor,
  output reg [32-1:0] xQuotient,
  input wire iInputReady,
  output reg OutputReady
);

  parameter SIGN = 31;
  wire Sign;
  wire [32-1:0] wDividend;wire [32-1:0] wDivisor;
  wire wInputReady;

  FFD_POSEDGE_SYNCRONOUS_RESET
  #(
    32
  )
  FFD1
  (
    .Clock(Clock),
    .Reset(Reset),
    .Enable(iInputReady),
    .D(iDividend),
    .Q(wDividend)
  );


  FFD_POSEDGE_SYNCRONOUS_RESET
  #(
    32
  )
  FFD2
  (
    .Clock(Clock),
    .Reset(Reset),
    .Enable(iInputReady),
    .D(iDivisor),
    .Q(wDivisor)
  );


  FFD_POSEDGE_SYNCRONOUS_RESET
  #(
    1
  )
  FFD3
  (
    .Clock(Clock),
    .Reset(Reset),
    .Enable(1'b1),
    .D(iInputReady),
    .Q(wInputReady)
  );

  wire [32-1:0] wAbsDividend;wire [32-1:0] wAbsDivisor;
  wire [32-1:0] wQuottientTemp;
  wire [32-1:0] wAbsQuotient;
  assign Sign = wDividend[SIGN] ^ wDivisor[SIGN];
  assign wAbsDividend = (wDividend[SIGN] == 1)? ~wDividend + 1'b1 : wDividend;
  assign wAbsDivisor = (wDivisor[SIGN] == 1)? ~wDivisor + 1'b1 : wDivisor;
  wire DivReady;

  UnsignedIntegerDivision
  UDIV
  (
    .Clock(Clock),
    .Reset(Reset),
    .iDividend(wAbsDividend),
    .iDivisor(wAbsDivisor),
    .xQuotient(wQuottientTemp),
    .iInputReady(DivReady),
    .OutputReady(wInputReady)
  );

  assign wAbsQuotient = wQuottientTemp & 32'h7FFFFFFF;

  always @(posedge Clock) begin
    if(DivReady) begin
      if(Sign == 1) xQuotient = ~wAbsQuotient + 1'b1; 
      else xQuotient = wAbsQuotient;
    end 
    OutputReady = DivReady;
    if(Reset == 1) OutputReady = 0; 
  end


endmodule



module UnsignedIntegerDivision
(
  input wire Clock,
  input Reset,
  input wire [32-1:0] iDividend,
  input [32-1:0] iDivisor,
  output reg [32-1:0] xQuotient,
  input wire iInputReady,
  output reg OutputReady
);

  reg [63:0] Dividend;reg [63:0] Divisor;
  reg [32-1:0] i;reg [32-1:0] num_bits;
  reg [63:0] t;reg [63:0] q;reg [63:0] d;reg [63:0] Bit;
  reg [63:0] Quotient;reg [63:0] Remainder;
  reg [5:0] CurrentState;reg [5:0] NextState;

  always @(negedge Clock) begin
    if(Reset != 1) CurrentState = NextState; 
    else CurrentState = 0;
  end


  always @(posedge Clock) begin
    case(CurrentState)
      0: begin
        OutputReady = 0;
        NextState = (iInputReady == 1)? 6'd1 : 0;
      end
      6'd1: begin
        Dividend = iDividend;
        Dividend = Dividend << 17;
        Divisor = iDivisor;
        Remainder = 0;
        Quotient = 0;
        if(Divisor == 0) begin
          Quotient[31:0] = 32'h0FFF_FFFF;
          NextState = 6'd5;
        end else if(Divisor > Dividend) begin
          Remainder = Dividend;
          NextState = 6'd5;
        end else if(Divisor == Dividend) begin
          Quotient = 1;
          NextState = 6'd5;
        end else begin
          NextState = 6'd3;
        end
        num_bits = 64;
      end
      6'd3: begin
        Bit = (Dividend & 64'h8000000000000000) >> 63;
        Remainder = (Remainder << 1) | Bit;
        d = Dividend;
        Dividend = Dividend << 1;
        num_bits = num_bits - 1;
        NextState = (Remainder < Divisor)? 6'd3 : 6'd2;
      end
      6'd2: begin
        Dividend = d;
        Remainder = Remainder >> 1;
        num_bits = num_bits + 1;
        i = 0;
        NextState = 6'd4;
      end
      6'd4: begin
        Bit = (Dividend & 64'h8000000000000000) >> 63;
        Remainder = (Remainder << 1) | Bit;
        t = Remainder - Divisor;
        q = !((t & 64'h8000000000000000) >> 63);
        Dividend = Dividend << 1;
        Quotient = (Quotient << 1) | q;
        if(q != 0) Remainder = t; 
        i = i + 1;
        if(i < num_bits) NextState = 6'd4; 
        else NextState = 6'd5;
      end
      6'd5: begin
        xQuotient = Quotient[32:0];
        OutputReady = 1;
        NextState = (iInputReady == 0)? 0 : 6'd5;
      end
    endcase
  end


endmodule

