

module t6507lp_alu
(
  clk,
  reset_n,
  alu_enable,
  alu_result,
  alu_status,
  alu_opcode,
  alu_a,
  alu_x,
  alu_y
);

  localparam C = 3'b000;
  localparam Z = 3'b001;
  localparam I = 3'b010;
  localparam D = 3'b011;
  localparam B = 3'b100;
  localparam V = 3'b110;
  localparam N = 3'b111;
  localparam IMP = 4'h0;localparam ACC = 4'h1;localparam IMM = 4'h2;localparam ZPG = 4'h3;localparam ZPX = 4'h4;localparam ZPY = 4'h5;localparam REL = 4'h6;localparam ABS = 4'h7;localparam ABX = 4'h8;localparam ABY = 4'h9;localparam IDX = 4'hA;localparam IDY = 4'hB;
  localparam ADC_IMM = 8'h69;localparam ADC_ZPG = 8'h65;localparam ADC_ZPX = 8'h75;localparam ADC_ABS = 8'h6D;localparam ADC_ABX = 8'h7D;localparam ADC_ABY = 8'h79;localparam ADC_IDX = 8'h61;localparam ADC_IDY = 8'h71;
  localparam AND_IMM = 8'h29;localparam AND_ZPG = 8'h25;localparam AND_ZPX = 8'h35;localparam AND_ABS = 8'h2D;localparam AND_ABX = 8'h3D;localparam AND_ABY = 8'h39;localparam AND_IDX = 8'h21;localparam AND_IDY = 8'h31;
  localparam ASL_ACC = 8'h0A;localparam ASL_ZPG = 8'h06;localparam ASL_ZPX = 8'h16;localparam ASL_ABS = 8'h0E;localparam ASL_ABX = 8'h1E;
  localparam BCC_REL = 8'h90;
  localparam BCS_REL = 8'hB0;
  localparam BEQ_REL = 8'hF0;
  localparam BIT_ZPG = 8'h24;localparam BIT_ABS = 8'h2C;
  localparam BMI_REL = 8'h30;
  localparam BNE_REL = 8'hD0;
  localparam BPL_REL = 8'h10;
  localparam BRK_IMP = 8'h00;
  localparam BVC_REL = 8'h50;
  localparam BVS_REL = 8'h70;
  localparam CLC_IMP = 8'h18;
  localparam CLD_IMP = 8'hD8;
  localparam CLI_IMP = 8'h58;
  localparam CLV_IMP = 8'hB8;
  localparam CMP_IMM = 8'hC9;localparam CMP_ZPG = 8'hC5;localparam CMP_ZPX = 8'hD5;localparam CMP_ABS = 8'hCD;localparam CMP_ABX = 8'hDD;localparam CMP_ABY = 8'hD9;localparam CMP_IDX = 8'hC1;localparam CMP_IDY = 8'hD1;
  localparam CPX_IMM = 8'hE0;localparam CPX_ZPG = 8'hE4;localparam CPX_ABS = 8'hEC;
  localparam CPY_IMM = 8'hC0;localparam CPY_ZPG = 8'hC4;localparam CPY_ABS = 8'hCC;
  localparam DEC_ZPG = 8'hC6;localparam DEC_ZPX = 8'hD6;localparam DEC_ABS = 8'hCE;localparam DEC_ABX = 8'hDE;
  localparam DEX_IMP = 8'hCA;
  localparam DEY_IMP = 8'h88;
  localparam EOR_IMM = 8'h49;localparam EOR_ZPG = 8'h45;localparam EOR_ZPX = 8'h55;localparam EOR_ABS = 8'h4D;localparam EOR_ABX = 8'h5D;localparam EOR_ABY = 8'h59;localparam EOR_IDX = 8'h41;localparam EOR_IDY = 8'h51;
  localparam INC_ZPG = 8'hE6;localparam INC_ZPX = 8'hF6;localparam INC_ABS = 8'hEE;localparam INC_ABX = 8'hFE;
  localparam INX_IMP = 8'hE8;
  localparam INY_IMP = 8'hC8;
  localparam JMP_ABS = 8'h4C;localparam JMP_IND = 8'h6C;
  localparam JSR_ABS = 8'h20;
  localparam LDA_IMM = 8'hA9;localparam LDA_ZPG = 8'hA5;localparam LDA_ZPX = 8'hB5;localparam LDA_ABS = 8'hAD;localparam LDA_ABX = 8'hBD;localparam LDA_ABY = 8'hB9;localparam LDA_IDX = 8'hA1;localparam LDA_IDY = 8'hB1;
  localparam LDX_IMM = 8'hA2;localparam LDX_ZPG = 8'hA6;localparam LDX_ZPY = 8'hB6;localparam LDX_ABS = 8'hAE;localparam LDX_ABY = 8'hBE;
  localparam LDY_IMM = 8'hA0;localparam LDY_ZPG = 8'hA4;localparam LDY_ZPX = 8'hB4;localparam LDY_ABS = 8'hAC;localparam LDY_ABX = 8'hBC;
  localparam LSR_ACC = 8'h4A;localparam LSR_ZPG = 8'h46;localparam LSR_ZPX = 8'h56;localparam LSR_ABS = 8'h4E;localparam LSR_ABX = 8'h5E;
  localparam NOP_IMP = 8'hEA;
  localparam ORA_IMM = 8'h09;localparam ORA_ZPG = 8'h05;localparam ORA_ZPX = 8'h15;localparam ORA_ABS = 8'h0D;localparam ORA_ABX = 8'h1D;localparam ORA_ABY = 8'h19;localparam ORA_IDX = 8'h01;localparam ORA_IDY = 8'h11;
  localparam PHA_IMP = 8'h48;
  localparam PHP_IMP = 8'h08;
  localparam PLA_IMP = 8'h68;
  localparam PLP_IMP = 8'h28;
  localparam ROL_ACC = 8'h2A;localparam ROL_ZPG = 8'h26;localparam ROL_ZPX = 8'h36;localparam ROL_ABS = 8'h2E;localparam ROL_ABX = 8'h3E;
  localparam ROR_ACC = 8'h6A;localparam ROR_ZPG = 8'h66;localparam ROR_ZPX = 8'h76;localparam ROR_ABS = 8'h6E;localparam ROR_ABX = 8'h7E;
  localparam RTI_IMP = 8'h40;
  localparam RTS_IMP = 8'h60;
  localparam SBC_IMM = 8'hE9;localparam SBC_ZPG = 8'hE5;localparam SBC_ZPX = 8'hF5;localparam SBC_ABS = 8'hED;localparam SBC_ABX = 8'hFD;localparam SBC_ABY = 8'hF9;localparam SBC_IDX = 8'hE1;localparam SBC_IDY = 8'hF1;
  localparam SEC_IMP = 8'h38;
  localparam SED_IMP = 8'hF8;
  localparam SEI_IMP = 8'h78;
  localparam STA_ZPG = 8'h85;localparam STA_ZPX = 8'h95;localparam STA_ABS = 8'h8D;localparam STA_ABX = 8'h9D;localparam STA_ABY = 8'h99;localparam STA_IDX = 8'h81;localparam STA_IDY = 8'h91;
  localparam STX_ZPG = 8'h86;localparam STX_ZPY = 8'h96;localparam STX_ABS = 8'h8E;
  localparam STY_ZPG = 8'h84;localparam STY_ZPX = 8'h94;localparam STY_ABS = 8'h8C;
  localparam TAX_IMP = 8'hAA;
  localparam TAY_IMP = 8'hA8;
  localparam TSX_IMP = 8'hBA;
  localparam TXA_IMP = 8'h8A;
  localparam TXS_IMP = 8'h9A;
  localparam TYA_IMP = 8'h98;
  localparam DATA_SIZE = 8;
  localparam [3:0] BCD_HIGH_LIMIT = 4'd9;
  localparam [3:0] BCD_FIX = 8'd6;
  input clk;wire clk;
  input reset_n;wire reset_n;
  input alu_enable;wire alu_enable;
  input [DATA_SIZE-1:0] alu_opcode;wire [DATA_SIZE-1:0] alu_opcode;
  input [DATA_SIZE-1:0] alu_a;wire [DATA_SIZE-1:0] alu_a;
  output [DATA_SIZE-1:0] alu_result;reg [DATA_SIZE-1:0] alu_result;
  output [DATA_SIZE-1:0] alu_status;reg [DATA_SIZE-1:0] alu_status;
  output [DATA_SIZE-1:0] alu_x;reg [DATA_SIZE-1:0] alu_x;
  output [DATA_SIZE-1:0] alu_y;reg [DATA_SIZE-1:0] alu_y;
  reg [DATA_SIZE-1:0] A;
  reg [DATA_SIZE-1:0] STATUS;
  reg [DATA_SIZE+1:0] result;
  reg [DATA_SIZE-1:0] op1;
  reg [DATA_SIZE-1:0] op2;
  reg [DATA_SIZE-1:0] bcdl;
  reg [DATA_SIZE-1:0] bcdh;
  reg [DATA_SIZE-1:0] bcdh2;
  reg [DATA_SIZE-1:0] AL;
  reg [DATA_SIZE-1:0] AH;

  always @(posedge clk or negedge reset_n) begin
    if(reset_n == 1'b0) begin
      alu_result <= 10'd0;
      alu_status[C] <= 1'b0;
      alu_status[N] <= 1'b0;
      alu_status[V] <= 1'b0;
      alu_status[5] <= 1'b1;
      alu_status[Z] <= 1'b1;
      alu_status[I] <= 1'b0;
      alu_status[B] <= 1'b0;
      alu_status[D] <= 1'b0;
      A <= 8'd0;
      alu_x <= 8'd0;
      alu_y <= 8'd0;
    end else if(alu_enable == 1'b1) begin
      case(alu_opcode)
        ADC_IMM, ADC_ZPG, ADC_ZPX, ADC_ABS, ADC_ABX, ADC_ABY, ADC_IDX, ADC_IDY, AND_IMM, AND_ZPG, AND_ZPX, AND_ABS, AND_ABX, AND_ABY, AND_IDX, AND_IDY, ASL_ACC, EOR_IMM, EOR_ZPG, EOR_ZPX, EOR_ABS, EOR_ABX, EOR_ABY, EOR_IDX, EOR_IDY, LSR_ACC, ORA_IMM, ORA_ZPG, ORA_ZPX, ORA_ABS, ORA_ABX, ORA_ABY, ORA_IDX, ORA_IDY, ROL_ACC, ROR_ACC, SBC_IMM, SBC_ZPG, SBC_ZPX, SBC_ABS, SBC_ABX, SBC_ABY, SBC_IDX, SBC_IDY, LDA_IMM, LDA_ZPG, LDA_ZPX, LDA_ABS, LDA_ABX, LDA_ABY, LDA_IDX, LDA_IDY, PLA_IMP: begin
          A <= result[7:0];
          alu_result <= result[7:0];
          alu_status <= STATUS;
        end
        LDX_IMM, LDX_ZPG, LDX_ZPY, LDX_ABS, LDX_ABY, TAX_IMP, TSX_IMP, INX_IMP, DEX_IMP: begin
          alu_x <= result[7:0];
          alu_status <= STATUS;
        end
        TXS_IMP: begin
          alu_x <= result[7:0];
        end
        TXA_IMP, TYA_IMP: begin
          A <= result[7:0];
          alu_status <= STATUS;
        end
        LDY_IMM, LDY_ZPG, LDY_ZPX, LDY_ABS, LDY_ABX, TAY_IMP, INY_IMP, DEY_IMP: begin
          alu_y <= result[7:0];
          alu_status <= STATUS;
        end
        CMP_IMM, CMP_ZPG, CMP_ZPX, CMP_ABS, CMP_ABX, CMP_ABY, CMP_IDX, CMP_IDY, CPX_IMM, CPX_ZPG, CPX_ABS, CPY_IMM, CPY_ZPG, CPY_ABS: begin
          alu_status <= STATUS;
        end
        PHA_IMP, STA_ZPG, STA_ZPX, STA_ABS, STA_ABX, STA_ABY, STA_IDX, STA_IDY: begin
          alu_result <= result[7:0];
        end
        STX_ZPG, STX_ZPY, STX_ABS: begin
          alu_x <= result[7:0];
        end
        STY_ZPG, STY_ZPX, STY_ABS: begin
          alu_y <= result[7:0];
        end
        SEC_IMP: begin
          alu_status[C] <= 1'b1;
        end
        SED_IMP: begin
          alu_status[D] <= 1'b1;
        end
        SEI_IMP: begin
          alu_status[I] <= 1'b1;
        end
        CLC_IMP: begin
          alu_status[C] <= 1'b0;
        end
        CLD_IMP: begin
          alu_status[D] <= 1'b0;
        end
        CLI_IMP: begin
          alu_status[I] <= 1'b0;
        end
        CLV_IMP: begin
          alu_status[V] <= 1'b0;
        end
        BRK_IMP: begin
          alu_status[B] <= 1'b1;
        end
        PLP_IMP, RTI_IMP: begin
          alu_status[C] <= alu_a[C];
          alu_status[Z] <= alu_a[Z];
          alu_status[I] <= alu_a[I];
          alu_status[D] <= alu_a[D];
          alu_status[B] <= alu_a[B];
          alu_status[V] <= alu_a[V];
          alu_status[N] <= alu_a[N];
          alu_status[5] <= 1'b1;
        end
        BIT_ZPG, BIT_ABS: begin
          alu_status[Z] <= STATUS[Z];
          alu_status[V] <= alu_a[6];
          alu_status[N] <= alu_a[7];
        end
        INC_ZPG, INC_ZPX, INC_ABS, INC_ABX, DEC_ZPG, DEC_ZPX, DEC_ABS, DEC_ABX, ASL_ZPG, ASL_ZPX, ASL_ABS, ASL_ABX, LSR_ZPG, LSR_ZPX, LSR_ABS, LSR_ABX, ROL_ZPG, ROL_ZPX, ROL_ABS, ROL_ABX, ROR_ZPG, ROR_ZPX, ROR_ABS, ROR_ABX: begin
          alu_result <= result[7:0];
          alu_status <= STATUS;
        end
        default: begin
          alu_result <= 8'hFF;
          alu_status <= 8'hFF;
          A <= 8'hFF;
          alu_x <= 8'hFF;
          alu_y <= 8'hFF;
        end
      endcase
    end 
  end


  always @(*) begin
    op1 = A;
    op2 = alu_a;
    result = { 2'd0, A[7:0] };
    result[9:8] = 2'b00;
    STATUS[N] = alu_status[N];
    STATUS[C] = alu_status[C];
    STATUS[V] = alu_status[V];
    STATUS[B] = alu_status[B];
    STATUS[I] = alu_status[I];
    STATUS[D] = alu_status[D];
    STATUS[Z] = alu_status[Z];
    STATUS[5] = 1'b1;
    bcdl = 8'd0;
    bcdh = 8'd0;
    bcdh2 = 8'd0;
    AL = 8'd0;
    AH = 8'd0;
    if(alu_enable == 1'b1) begin
      case(alu_opcode)
        BIT_ZPG, BIT_ABS: begin
          result[7:0] = A & alu_a;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        PLA_IMP: begin
          result[7:0] = alu_a;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        TAX_IMP, TAY_IMP, PHA_IMP, STA_ZPG, STA_ZPX, STA_ABS, STA_ABX, STA_ABY, STA_IDX, STA_IDY: begin
          result[7:0] = A;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        STX_ZPG, STX_ZPY, STX_ABS, TXA_IMP, TXS_IMP: begin
          result[7:0] = alu_x;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        STY_ZPG, STY_ZPX, STY_ABS, TYA_IMP: begin
          result[7:0] = alu_y;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        INC_ZPG, INC_ZPX, INC_ABS, INC_ABX: begin
          result[7:0] = alu_a + 8'd1;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        INX_IMP: begin
          result[7:0] = alu_x + 8'd1;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        INY_IMP: begin
          result[7:0] = alu_y + 8'd1;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        DEC_ZPG, DEC_ZPX, DEC_ABS, DEC_ABX: begin
          result[7:0] = alu_a + 8'd1;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        DEX_IMP: begin
          result[7:0] = alu_x - 8'd1;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        DEY_IMP: begin
          result[7:0] = alu_y - 8'd1;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        ADC_IMM, ADC_ZPG, ADC_ZPX, ADC_ABS, ADC_ABX, ADC_ABY, ADC_IDX, ADC_IDY: begin
          if(!alu_status[D]) begin
            result = op1 + op2 + { 7'd0, alu_status[C] };
            STATUS[N] = result[7];
            STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
            STATUS[V] = ((op1[7] == op2[7]) && (op1[7] != result[7]))? 1'b1 : 1'b0;
            STATUS[C] = result[8];
          end else begin
            AL = op1[3:0] + op2[3:0] + { 7'd0, alu_status[C] };
            AH = op1[7:4] + op2[7:4];
            STATUS[Z] = ((AL == 0) && (AH == 0))? 1'b1 : 1'b0;
            if(AL > { 4'd0, BCD_HIGH_LIMIT }) begin
              bcdl = AL + { 4'd0, BCD_FIX };
              bcdh = AH + 8'd1;
            end else begin
              bcdl = AL;
              bcdh = AH;
            end
            STATUS[N] = bcdh[3];
            STATUS[V] = ((op1[7] == op2[7]) && (op1[7] != bcdh[3]))? 1'b1 : 1'b0;
            if(bcdh > { 4'd0, BCD_HIGH_LIMIT }) begin
              bcdh2 = bcdh + { 4'd0, BCD_FIX };
            end else begin
              bcdh2 = bcdh;
            end
            STATUS[C] = bcdh2[4] || bcdh2[5];
            result[7:0] = { bcdh2[3:0], bcdl[3:0] };
          end
        end
        AND_IMM, AND_ZPG, AND_ZPX, AND_ABS, AND_ABX, AND_ABY, AND_IDX, AND_IDY: begin
          result[7:0] = A & alu_a;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        CMP_IMM, CMP_ZPG, CMP_ZPX, CMP_ABS, CMP_ABX, CMP_ABY, CMP_IDX, CMP_IDY: begin
          result[7:0] = A - alu_a;
          STATUS[C] = (A >= alu_a)? 1'b1 : 1'b0;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        EOR_IMM, EOR_ZPG, EOR_ZPX, EOR_ABS, EOR_ABX, EOR_ABY, EOR_IDX, EOR_IDY: begin
          result[7:0] = A ^ alu_a;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        LDA_IMM, LDA_ZPG, LDA_ZPX, LDA_ABS, LDA_ABX, LDA_ABY, LDA_IDX, LDA_IDY, LDX_IMM, LDX_ZPG, LDX_ZPY, LDX_ABS, LDX_ABY, LDY_IMM, LDY_ZPG, LDY_ZPX, LDY_ABS, LDY_ABX, TSX_IMP: begin
          result[7:0] = alu_a;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        ORA_IMM, ORA_ZPG, ORA_ZPX, ORA_ABS, ORA_ABX, ORA_ABY, ORA_IDX, ORA_IDY: begin
          result[7:0] = A | alu_a;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        SBC_IMM, SBC_ZPG, SBC_ZPX, SBC_ABS, SBC_ABX, SBC_ABY, SBC_IDX, SBC_IDY: begin
          result = op1 - op2 - (1'b1 - alu_status[C]);
          STATUS[N] = result[7];
          STATUS[V] = (op1[7] ^ op2[7] && op1[7] ^ result[7])? 1'b1 : 1'b0;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[C] = ~(result[8] || result[9]);
          if(alu_status[D]) begin
            AL = op1[3:0] - op2[3:0] - (1'b1 - alu_status[C]);
            AH = op1[7:4] - op2[7:4];
            if(AL[4]) begin
              bcdl = AL - { 4'd0, BCD_FIX };
              bcdh = AH - 8'd1;
            end else begin
              bcdl = AL;
              bcdh = AH;
            end
            if(bcdh[4]) begin
              bcdh2 = bcdh - { 4'd0, BCD_FIX };
            end else begin
              bcdh2 = bcdh;
            end
            result[7:0] = { bcdh2[3:0], bcdl[3:0] };
          end 
        end
        ASL_ACC: begin
          { STATUS[C], result[7:0] } = { A, 1'b0 };
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        ASL_ZPG, ASL_ZPX, ASL_ABS, ASL_ABX: begin
          { STATUS[C], result[7:0] } = { alu_a, 1'b0 };
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        LSR_ACC: begin
          { result[7:0], STATUS[C] } = { 1'b0, A };
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        LSR_ZPG, LSR_ZPX, LSR_ABS, LSR_ABX: begin
          { result[7:0], STATUS[C] } = { 1'b0, alu_a };
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        ROL_ACC: begin
          { STATUS[C], result[7:0] } = { A, alu_status[C] };
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        ROL_ZPG, ROL_ZPX, ROL_ABS, ROL_ABX: begin
          { STATUS[C], result[7:0] } = { alu_a, alu_status[C] };
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        ROR_ACC: begin
          { result[7:0], STATUS[C] } = { alu_status[C], A };
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        ROR_ZPG, ROR_ZPX, ROR_ABS, ROR_ABX: begin
          { result[7:0], STATUS[C] } = { alu_status[C], alu_a };
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        CPX_IMM, CPX_ZPG, CPX_ABS: begin
          result[7:0] = alu_x - alu_a;
          STATUS[C] = (alu_x >= alu_a)? 1'b1 : 1'b0;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        CPY_IMM, CPY_ZPG, CPY_ABS: begin
          result[7:0] = alu_y - alu_a;
          STATUS[C] = (alu_y >= alu_a)? 1'b1 : 1'b0;
          STATUS[Z] = (result[7:0] == 0)? 1'b1 : 1'b0;
          STATUS[N] = result[7];
        end
        default: begin
          result = 10'h3FF;
          STATUS = 8'hFF;
        end
      endcase
    end 
  end


endmodule

