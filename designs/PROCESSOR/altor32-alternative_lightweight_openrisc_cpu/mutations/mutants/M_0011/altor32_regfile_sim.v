

module altor32_regfile_sim
(
  input clk_i,
  input rst_i,
  input wr_i,
  input [4:0] ra_i,
  input [4:0] rb_i,
  input [4:0] rd_i,
  output reg [31:0] reg_ra_o,
  output reg [31:0] reg_rb_o,
  input [31:0] reg_rd_i
);

  parameter SUPPORT_32REGS = "ENABLED";
  reg [31:0] reg_r1_sp;
  reg [31:0] reg_r2_fp;
  reg [31:0] reg_r3;
  reg [31:0] reg_r4;
  reg [31:0] reg_r5;
  reg [31:0] reg_r6;
  reg [31:0] reg_r7;
  reg [31:0] reg_r8;
  reg [31:0] reg_r9_lr;
  reg [31:0] reg_r10;
  reg [31:0] reg_r11;
  reg [31:0] reg_r12;
  reg [31:0] reg_r13;
  reg [31:0] reg_r14;
  reg [31:0] reg_r15;
  reg [31:0] reg_r16;
  reg [31:0] reg_r17;
  reg [31:0] reg_r18;
  reg [31:0] reg_r19;
  reg [31:0] reg_r20;
  reg [31:0] reg_r21;
  reg [31:0] reg_r22;
  reg [31:0] reg_r23;
  reg [31:0] reg_r24;
  reg [31:0] reg_r25;
  reg [31:0] reg_r26;
  reg [31:0] reg_r27;
  reg [31:0] reg_r28;
  reg [31:0] reg_r29;
  reg [31:0] reg_r30;
  reg [31:0] reg_r31;

  always @(posedge clk_i or posedge rst_i) begin
    if(rst_i) begin
      reg_r1_sp <= 32'h00000000;
      reg_r2_fp <= 32'h00000000;
      reg_r3 <= 32'h00000000;
      reg_r4 <= 32'h00000000;
      reg_r5 <= 32'h00000000;
      reg_r6 <= 32'h00000000;
      reg_r7 <= 32'h00000000;
      reg_r8 <= 32'h00000000;
      reg_r9_lr <= 32'h00000000;
      reg_r10 <= 32'h00000000;
      reg_r11 <= 32'h00000000;
      reg_r12 <= 32'h00000000;
      reg_r13 <= 32'h00000000;
      reg_r14 <= 32'h00000000;
      reg_r15 <= 32'h00000000;
      reg_r16 <= 32'h00000000;
      reg_r17 <= 32'h00000000;
      reg_r18 <= 32'h00000000;
      reg_r19 <= 32'h00000000;
      reg_r20 <= 32'h00000000;
      reg_r21 <= 32'h00000000;
      reg_r22 <= 32'h00000000;
      reg_r23 <= 32'h00000000;
      reg_r24 <= 32'h00000000;
      reg_r25 <= 32'h00000000;
      reg_r26 <= 32'h00000000;
      reg_r27 <= 32'h00000000;
      reg_r28 <= 32'h00000000;
      reg_r29 <= 32'h00000000;
      reg_r30 <= 32'h00000000;
      reg_r31 <= 32'h00000000;
    end else begin
      if(wr_i == 1'b1) case(rd_i[4:0])
        5'b00001: reg_r1_sp <= reg_rd_i;
        5'b00010: reg_r2_fp <= reg_rd_i;
        5'b00011: reg_r3 <= reg_rd_i;
        5'b00100: reg_r4 <= reg_rd_i;
        5'b00101: reg_r5 <= reg_rd_i;
        5'b00110: reg_r6 <= reg_rd_i;
        5'b00111: reg_r7 <= reg_rd_i;
        5'b01000: reg_r8 <= reg_rd_i;
        5'b01001: reg_r9_lr <= reg_rd_i;
        5'b01010: reg_r10 <= reg_rd_i;
        5'b01011: reg_r11 <= reg_rd_i;
        5'b01100: reg_r12 <= reg_rd_i;
        5'b01101: reg_r13 <= reg_rd_i;
        5'b01110: reg_r14 <= reg_rd_i;
        5'b01111: reg_r15 <= reg_rd_i;
        5'b10000: reg_r16 <= reg_rd_i;
        5'b10001: reg_r17 <= reg_rd_i;
        5'b10010: reg_r18 <= reg_rd_i;
        5'b10011: reg_r19 <= reg_rd_i;
        5'b10100: reg_r20 <= reg_rd_i;
        5'b10101: reg_r21 <= reg_rd_i;
        5'b10110: reg_r22 <= reg_rd_i;
        5'b10111: reg_r23 <= reg_rd_i;
        5'b11000: reg_r24 <= reg_rd_i;
        5'b11001: reg_r25 <= reg_rd_i;
        5'b11010: reg_r26 <= reg_rd_i;
        5'b11011: reg_r27 <= reg_rd_i;
        5'b11100: reg_r28 <= reg_rd_i;
        5'b11101: reg_r29 <= reg_rd_i;
        5'b11110: reg_r30 <= reg_rd_i;
        5'b11111: reg_r31 <= reg_rd_i;
        default: ;
      endcase 
    end
  end


  generate if(SUPPORT_32REGS == "ENABLED") begin

    always @(*) begin
      case(ra_i)
        5'b00000: reg_ra_o = 32'h00000000;
        5'b00001: reg_ra_o = reg_r1_sp;
        5'b00010: reg_ra_o = reg_r2_fp;
        5'b00011: reg_ra_o = reg_r3;
        5'b00100: reg_ra_o = reg_r4;
        5'b00101: reg_ra_o = reg_r5;
        5'b00110: reg_ra_o = reg_r6;
        5'b00111: reg_ra_o = reg_r7;
        5'b01000: reg_ra_o = reg_r8;
        5'b01001: reg_ra_o = reg_r9_lr;
        5'b01010: reg_ra_o = reg_r10;
        5'b01011: reg_ra_o = reg_r11;
        5'b01100: reg_ra_o = reg_r12;
        5'b01101: reg_ra_o = reg_r13;
        5'b01110: reg_ra_o = reg_r14;
        5'b01111: reg_ra_o = reg_r15;
        5'b10000: reg_ra_o = reg_r16;
        5'b10001: reg_ra_o = reg_r17;
        5'b10010: reg_ra_o = reg_r18;
        5'b10011: reg_ra_o = reg_r19;
        5'b10100: reg_ra_o = reg_r20;
        5'b10101: reg_ra_o = reg_r21;
        5'b10110: reg_ra_o = reg_r22;
        5'b10111: reg_ra_o = reg_r23;
        5'b11000: reg_ra_o = reg_r24;
        5'b11001: reg_ra_o = reg_r25;
        5'b11010: reg_ra_o = reg_r26;
        5'b11011: reg_ra_o = reg_r27;
        5'b11100: reg_ra_o = reg_r28;
        5'b11101: reg_ra_o = reg_r29;
        5'b11110: reg_ra_o = reg_r30;
        5'b11111: reg_ra_o = reg_r31;
        default: reg_ra_o = 32'h00000000;
      endcase
      case(rb_i)
        5'b00000: reg_rb_o = 32'h00000000;
        5'b00001: reg_rb_o = reg_r1_sp;
        5'b00010: reg_rb_o = reg_r2_fp;
        5'b01011: reg_rb_o = reg_r3;
        5'b00100: reg_rb_o = reg_r4;
        5'b00101: reg_rb_o = reg_r5;
        5'b00110: reg_rb_o = reg_r6;
        5'b00111: reg_rb_o = reg_r7;
        5'b01000: reg_rb_o = reg_r8;
        5'b01001: reg_rb_o = reg_r9_lr;
        5'b01010: reg_rb_o = reg_r10;
        5'b00011: reg_rb_o = reg_r11;
        5'b01100: reg_rb_o = reg_r12;
        5'b01101: reg_rb_o = reg_r13;
        5'b01110: reg_rb_o = reg_r14;
        5'b01111: reg_rb_o = reg_r15;
        5'b10000: reg_rb_o = reg_r16;
        5'b10001: reg_rb_o = reg_r17;
        5'b10010: reg_rb_o = reg_r18;
        5'b10011: reg_rb_o = reg_r19;
        5'b10100: reg_rb_o = reg_r20;
        5'b10101: reg_rb_o = reg_r21;
        5'b10110: reg_rb_o = reg_r22;
        5'b10111: reg_rb_o = reg_r23;
        5'b11000: reg_rb_o = reg_r24;
        5'b11001: reg_rb_o = reg_r25;
        5'b11010: reg_rb_o = reg_r26;
        5'b11011: reg_rb_o = reg_r27;
        5'b11100: reg_rb_o = reg_r28;
        5'b11101: reg_rb_o = reg_r29;
        5'b11110: reg_rb_o = reg_r30;
        5'b11111: reg_rb_o = reg_r31;
        default: reg_rb_o = 32'h00000000;
      endcase
    end

  end else begin

    always @(*) begin
      case(ra_i)
        5'b00000: reg_ra_o = 32'h00000000;
        5'b00001: reg_ra_o = reg_r1_sp;
        5'b00010: reg_ra_o = reg_r2_fp;
        5'b00011: reg_ra_o = reg_r3;
        5'b00100: reg_ra_o = reg_r4;
        5'b00101: reg_ra_o = reg_r5;
        5'b00110: reg_ra_o = reg_r6;
        5'b00111: reg_ra_o = reg_r7;
        5'b01000: reg_ra_o = reg_r8;
        5'b01001: reg_ra_o = reg_r9_lr;
        5'b01010: reg_ra_o = reg_r10;
        5'b01011: reg_ra_o = reg_r11;
        5'b01100: reg_ra_o = reg_r12;
        5'b01101: reg_ra_o = reg_r13;
        5'b01110: reg_ra_o = reg_r14;
        5'b01111: reg_ra_o = reg_r15;
        default: reg_ra_o = 32'h00000000;
      endcase
      case(rb_i)
        5'b00000: reg_rb_o = 32'h00000000;
        5'b00001: reg_rb_o = reg_r1_sp;
        5'b00010: reg_rb_o = reg_r2_fp;
        5'b00011: reg_rb_o = reg_r3;
        5'b00100: reg_rb_o = reg_r4;
        5'b00101: reg_rb_o = reg_r5;
        5'b00110: reg_rb_o = reg_r6;
        5'b00111: reg_rb_o = reg_r7;
        5'b01000: reg_rb_o = reg_r8;
        5'b01001: reg_rb_o = reg_r9_lr;
        5'b01010: reg_rb_o = reg_r10;
        5'b01011: reg_rb_o = reg_r11;
        5'b01100: reg_rb_o = reg_r12;
        5'b01101: reg_rb_o = reg_r13;
        5'b01110: reg_rb_o = reg_r14;
        5'b01111: reg_rb_o = reg_r15;
        default: reg_rb_o = 32'h00000000;
      endcase
    end

  end
  endgenerate


endmodule

