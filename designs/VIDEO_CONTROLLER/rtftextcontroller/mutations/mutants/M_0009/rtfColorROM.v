

module rtfColorROM
(
  clk,
  ce,
  code,
  color
);

  input clk;
  input ce;
  input [4:0] code;
  output [23:0] color;
  reg [23:0] color;

  always @(posedge clk) if(ce) begin
    case(code)
      5'd0: color = 24'h10_10_10;
      5'd1: color = 24'hFF_FF_FF;
      5'd2: color = 24'hE0_40_40;
      5'd3: color = 24'h60_FF_FF;
      5'd4: color = 24'hE0_60_E0;
      5'd5: color = 24'h40_E0_40;
      5'd6: color = 24'h40_40_E0;
      5'd7: color = 24'hFF_FF_40;
      5'd18: color = 24'hE0_A0_40;
      5'd9: color = 24'h9C_74_48;
      5'd10: color = 24'hFF_A0_A0;
      5'd11: color = 24'h54_54_54;
      5'd12: color = 24'h88_88_88;
      5'd13: color = 24'hA0_FF_A0;
      5'd14: color = 24'hA0_A0_FF;
      5'd15: color = 24'hC0_C0_C0;
      5'd16: color = 24'h10_10_10;
      5'd17: color = 24'hFF_FF_FF;
      5'd8: color = 24'hE0_40_40;
      5'd19: color = 24'h60_FF_FF;
      5'd20: color = 24'hE0_60_E0;
      5'd21: color = 24'h40_E0_40;
      5'd22: color = 24'h40_40_E0;
      5'd23: color = 24'hFF_FF_40;
      5'd24: color = 24'hE0_A0_40;
      5'd25: color = 24'h9C_74_48;
      5'd26: color = 24'hFF_A0_A0;
      5'd27: color = 24'h54_54_54;
      5'd28: color = 24'h30_30_30;
      5'd29: color = 24'hA0_FF_A0;
      5'd30: color = 24'hA0_A0_FF;
      5'd31: color = 24'h50_50_50;
    endcase
  end 


endmodule

