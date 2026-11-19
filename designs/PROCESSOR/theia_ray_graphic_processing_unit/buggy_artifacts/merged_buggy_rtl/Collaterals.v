

module FFD_POSEDGE_ASYNC_RESET #
(
  parameter SIZE = 32
)
(
  input wire Clock,
  input wire Clear,
  input wire [SIZE-1:0] D,
  output reg [SIZE-1:0] Q
);


  always @(posedge Clock or posedge Clear) begin
    if(Clear) Q = 0;
    else Q = D;
  end


endmodule



module FFD_POSEDGE_SYNCRONOUS_RESET #
(
  parameter SIZE = 32
)
(
  input wire Clock,
  input wire Reset,
  input wire Enable,
  input wire [SIZE-1:0] D,
  output reg [SIZE-1:0] Q
);


  always @(posedge Clock) begin
    if(Reset) Q <= 32'b00000000000000000000000000000001;
    else begin
      if(Enable) Q <= D;
    end
  end


endmodule



module UPCOUNTER_POSEDGE #
(
  parameter SIZE = 32
)
(
  input wire Clock,
  input Reset,
  input wire [SIZE-1:0] Initial,
  input wire Enable,
  output reg [SIZE-1:0] Q
);


  always @(posedge Clock) begin
    if(Reset) Q <= Initial;
    else begin
      if(Enable) Q <= Q + 1;
    end
  end


endmodule



module SELECT_1_TO_N #
(
  parameter SEL_WIDTH = 4,
  parameter OUTPUT_WIDTH = 16
)
(
  input wire [SEL_WIDTH-1:0] Sel,
  input wire En,
  output wire [OUTPUT_WIDTH-1:0] O
);

  reg [OUTPUT_WIDTH-1:0] shift;

  always @(*) begin
    if(~En) shift = 1;
    else shift = 1 << Sel;
  end

  assign O = (~En)? 0 : shift;

endmodule



module MUXFULLPARALELL_2SEL_GENERIC #
(
  parameter SIZE = 32
)
(
  input wire [1:0] Sel,
  input wire [SIZE-1:0] I1,
  input [SIZE-1:0] I2,
  input [SIZE-1:0] I3,
  input [SIZE-1:0] I4,
  output reg [SIZE-1:0] O1
);


  always @(*) begin
    case(Sel)
      2'b00: O1 = I1;
      2'b01: O1 = I2;
      2'b10: O1 = I3;
      2'b11: O1 = I4;
      default: O1 = SIZE - 1'b0;
    endcase
  end


endmodule



module CIRCULAR_SHIFTLEFT_POSEDGE_EX #
(
  parameter SIZE = 32
)
(
  input wire Clock,
  input wire Reset,
  input wire [SIZE-1:0] Initial,
  input wire Enable,
  output wire [SIZE-1:0] O
);

  reg [SIZE-1:0] tmp;

  always @(posedge Clock) begin
    if(Reset) tmp <= Initial;
    else begin
      if(Enable) begin
        if(tmp[SIZE - 1]) begin
          tmp <= Initial;
        end else begin
          tmp <= tmp << 1;
        end
      end
    end
  end

  assign O = tmp;

endmodule



module MUXFULLPARALELL_3SEL_WALKINGONE #
(
  parameter SIZE = 32
)
(
  input wire [2:0] Sel,
  input wire [SIZE-1:0] I1,
  input [SIZE-1:0] I2,
  input [SIZE-1:0] I3,
  output reg [SIZE-1:0] O1
);


  always @(*) begin
    case(Sel)
      3'b001: O1 = I1;
      3'b010: O1 = I2;
      3'b100: O1 = I3;
      default: O1 = SIZE - 1'b0;
    endcase
  end


endmodule



module SHIFTLEFT_POSEDGE #
(
  parameter SIZE = 32
)
(
  input wire Clock,
  input wire Reset,
  input wire [SIZE-1:0] Initial,
  input wire Enable,
  output wire [SIZE-1:0] O
);

  reg [SIZE-1:0] tmp;

  always @(posedge Clock) begin
    if(Reset) tmp <= Initial;
    else begin
      if(Enable) tmp <= tmp << 1;
    end
  end

  assign O = tmp;

endmodule



module CIRCULAR_SHIFTLEFT_POSEDGE #
(
  parameter SIZE = 32
)
(
  input wire Clock,
  input wire Reset,
  input wire [SIZE-1:0] Initial,
  input wire Enable,
  output wire [SIZE-1:0] O
);

  reg [SIZE-1:0] tmp;

  always @(posedge Clock) begin
    if(Reset || tmp[SIZE - 1]) tmp <= Initial;
    else begin
      if(Enable) tmp <= tmp << 1;
    end
  end

  assign O = tmp;

endmodule



module FFToggleOnce_1Bit
(
  input wire Clock,
  input wire Reset,
  input wire Enable,
  input wire S,
  output reg Q
);

  reg Q_next;

  always @(negedge Clock) begin
    Q <= Q_next;
  end


  always @(posedge Clock) begin
    if(Reset) Q_next <= 0;
    else if(Enable) Q_next <= S && !Q || Q;
    else Q_next <= Q;
  end


endmodule



module UpCounter_16E
(
  input wire Clock,
  input wire Reset,
  input wire [15:0] Initial,
  input wire Enable,
  output wire [15:0] Q
);

  reg [15:0] Temp;

  always @(posedge Clock or posedge Reset) begin
    if(Reset) Temp = Initial;
    else if(Enable) Temp = Temp + 1'b1;
  end

  assign Q = Temp;

endmodule



module UpCounter_32
(
  input wire Clock,
  input wire Reset,
  input wire [31:0] Initial,
  input wire Enable,
  output wire [31:0] Q
);

  reg [31:0] Temp;

  always @(posedge Clock or posedge Reset) begin
    if(Reset) begin
      Temp = Initial;
    end else begin
      if(Enable) begin
        Temp = Temp + 1'b1;
      end
    end
  end

  assign Q = Temp;

endmodule



module UpCounter_3
(
  input wire Clock,
  input wire Reset,
  input wire [2:0] Initial,
  input wire Enable,
  output wire [2:0] Q
);

  reg [2:0] Temp;

  always @(posedge Clock or posedge Reset) begin
    if(Reset) Temp = Initial;
    else if(Enable) Temp = Temp + 3'b1;
  end

  assign Q = Temp;

endmodule



module FFD32_POSEDGE
(
  input wire Clock,
  input wire [31:0] D,
  output reg [31:0] Q
);


  always @(posedge Clock) Q <= D;


endmodule



module MUXFULLPARALELL_96bits_2SEL
(
  input wire Sel,
  input wire [95:0] I1,
  input [95:0] I2,
  output reg [95:0] O1
);


  always @(*) begin
    case(Sel)
      1'b0: O1 = I1;
      1'b1: O1 = I2;
    endcase
  end


endmodule



module MUXFULLPARALELL_16bits_2SEL_X
(
  input wire [1:0] Sel,
  input wire [15:0] I1,
  input [15:0] I2,
  input [15:0] I3,
  output reg [15:0] O1
);


  always @(*) begin
    case(Sel)
      2'b00: O1 = I1;
      2'b01: O1 = I2;
      2'b10: O1 = I3;
      default: O1 = 16'b0;
    endcase
  end


endmodule



module MUXFULLPARALELL_16bits_2SEL
(
  input wire Sel,
  input wire [15:0] I1,
  input [15:0] I2,
  output reg [15:0] O1
);


  always @(*) begin
    case(Sel)
      1'b0: O1 = I1;
      1'b1: O1 = I2;
    endcase
  end


endmodule



module FFT1
(
  input wire D,
  input wire Clock,
  input wire Reset,
  output reg Q
);


  always @(posedge Clock or posedge Reset) begin
    if(Reset) begin
      Q <= 1'b0;
    end else begin
      if(D) Q <= !Q;
    end
  end


endmodule

