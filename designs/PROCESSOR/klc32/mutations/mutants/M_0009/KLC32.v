

module KLC32
(
  RST,
  clk_i,
  ipl_i,
  vpa_i,
  halt_i,
  inta_o,
  fc_o,
  rst_o,
  cyc_o,
  stb_o,
  ack_i,
  err_i,
  sel_o,
  we_o,
  adr_o,
  dat_i,
  dat_o
);

  parameter IFETCH = 8'd1;
  parameter REGFETCHA = 8'd2;
  parameter REGFETCHB = 8'd3;
  parameter EXECUTE = 8'd4;
  parameter MEMORY1 = 8'd5;
  parameter MEMORY1_ACK = 8'd6;
  parameter WRITEBACK = 8'd7;
  parameter JSR1 = 8'd10;
  parameter JSR2 = 8'd11;
  parameter JSRShort = 8'd12;
  parameter RTS = 8'd13;
  parameter JMP = 8'd14;
  parameter LOAD_SP = 8'd15;
  parameter VECTOR = 8'd16;
  parameter INTA = 8'd20;
  parameter FETCH_VECTOR = 8'd21;
  parameter TRAP1 = 8'd22;
  parameter TRAP2 = 8'd23;
  parameter TRAP3 = 8'd24;
  parameter RTI1 = 8'd25;
  parameter RTI2 = 8'd26;
  parameter RTI3 = 8'd27;
  parameter TRAP = 8'd28;
  parameter RESET = 8'd29;
  parameter JSR32 = 8'd30;
  parameter JMP32 = 8'd31;
  parameter WRITE_FLAGS = 8'd32;
  parameter FETCH_IMM32 = 8'd33;
  parameter REGFETCHC = 8'd34;
  parameter PUSH1 = 8'd35;
  parameter PUSH2 = 8'd36;
  parameter PUSH3 = 8'd37;
  parameter POP1 = 8'd38;
  parameter POP2 = 8'd39;
  parameter POP3 = 8'd40;
  parameter LINK = 8'd41;
  parameter UNLK = 8'd42;
  parameter TAS = 8'd43;
  parameter TAS2 = 8'd44;
  parameter PEA = 8'd45;
  parameter MULTDIV1 = 8'd49;
  parameter MULTDIV2 = 8'd50;
  parameter MULT1 = 8'd51;
  parameter MULT2 = 8'd52;
  parameter MULT3 = 8'd53;
  parameter MULT4 = 8'd54;
  parameter MULT5 = 8'd55;
  parameter MULT6 = 8'd56;
  parameter MULT7 = 8'd57;
  parameter DIV1 = 8'd61;
  parameter DIV2 = 8'd62;
  input RST;
  input clk_i;
  input [2:0] ipl_i;
  input vpa_i;
  input halt_i;
  output inta_o;
  reg inta_o;
  output [2:0] fc_o;
  reg [2:0] fc_o;
  output rst_o;
  output cyc_o;
  reg cyc_o;
  output stb_o;
  reg stb_o;
  input ack_i;
  input err_i;
  output we_o;
  reg we_o;
  output [3:0] sel_o;
  reg [3:0] sel_o;
  output [31:0] adr_o;
  reg [31:0] adr_o;
  input [31:0] dat_i;
  output [31:0] dat_o;
  reg [31:0] dat_o;
  reg cpu_clk_en;
  reg clk_en;
  wire clk;
  reg [7:0] state;
  reg [31:0] ir;
  reg tf;reg sf;
  reg [31:0] pc;
  reg [31:0] usp;reg [31:0] ssp;
  reg [31:0] ctr;
  wire [5:0] opcode;assign opcode = ir[31:26];
  reg Rcbit;
  reg [5:0] mopcode;
  wire [5:0] func;assign func = ir[5:0];
  wire [9:0] func1;assign func1 = ir[10:1];
  wire [3:0] cond;assign cond = ir[19:16];
  wire [31:0] brdisp;assign brdisp = { { 16{ ir[15] } }, ir[15:2], 2'b0 };
  reg [4:0] Rn;
  reg [31:0] regfile [31:0];
  wire [31:0] rfo1;assign rfo1 = regfile[Rn];
  wire [31:0] rfo;assign rfo = (Rn == 5'd0)? 32'd0 : 
               (Rn == 5'd31)? (sf)? ssp : usp : rfo1;
  reg vf;reg nf;reg cf;reg zf;
  reg xer_ov;reg xer_ca;reg xer_so;
  reg [2:0] im;
  reg [2:0] iplr;
  reg [7:0] vecnum;
  reg [31:0] vector;
  reg [31:0] ea;
  reg [15:0] rstsh;
  assign rst_o = rstsh[15];
  reg prev_nmi;
  reg nmi_edge;
  reg [31:0] sr1;
  reg [31:0] tgt;
  reg [31:0] a;reg [31:0] b;reg [31:0] c;reg [31:0] imm;reg [31:0] aa;reg [31:0] bb;
  wire signed [31:0] as;assign as = a;
  wire signed [31:0] bs;assign bs = b;
  reg [31:0] res;
  reg [3:0] cr0;reg [3:0] cr1;reg [3:0] cr2;reg [3:0] cr3;reg [3:0] cr4;reg [3:0] cr5;reg [3:0] cr6;reg [3:0] cr7;
  wire [31:0] cr;assign cr = { cr7, cr6, cr5, cr4, cr3, cr2, cr1, cr0 };
  wire [31:0] sr;assign sr = { tf, 1'b0, sf, 2'b00, im, 16'd0 };
  reg [31:0] tick;
  reg [31:0] be_addr;
  reg [5:0] cnt;
  reg [31:0] div_r0;
  reg [31:0] div_q0;
  reg [31:0] div_q;reg [31:0] div_r;
  wire [32:0] div_dif;assign div_dif = div_r0 - bb;
  wire IsSubi;assign IsSubi = opcode == 6'd5;
  wire IsCmpi;assign IsCmpi = opcode == 6'd6;
  wire IsSub;assign IsSub = (opcode == 6'd2) && (func == 6'd5);
  wire IsCmp;assign IsCmp = (opcode == 6'd2) && (func == 6'd6);
  wire IsNeg;assign IsNeg = (opcode == 6'd1) && (func == 6'd3);
  wire IsDivi;assign IsDivi = (opcode == 6'd14) || (opcode == 6'd15);
  wire IsDivu;assign IsDivu = (opcode == 6'd14) || (opcode == 6'd2) && ((func == 6'd28) || (func == 6'd30));
  wire IsMult;assign IsMult = (opcode == 6'd12) || (opcode == 6'd13) || (opcode == 6'd2) && ((func == 6'd24) || (func == 6'd26) || (func == 6'd25) || (func == 6'd27));
  wire IsDiv;assign IsDiv = (opcode == 6'd14) || (opcode == 6'd15) || (opcode == 6'd2) && ((func == 6'd28) || (func == 6'd29) || (func == 6'd30) || (func == 6'd31));
  wire hasConst16;assign hasConst16 = (opcode == 6'd4) || (opcode == 6'd5) || (opcode == 6'd6) || (opcode == 6'd8) || (opcode == 6'd9) || (opcode == 6'd10) || (opcode == 6'd48) || (opcode == 6'd49) || (opcode == 6'd50) || (opcode == 6'd51) || (opcode == 6'd52) || (opcode == 6'd56) || (opcode == 6'd57) || (opcode == 6'd58) || (opcode == 6'd55) || (opcode == 6'd46) || (opcode == 6'd54);
  wire isStop;assign isStop = (opcode == 6'd0) && (func == 6'd53);
  wire c_ri;wire c_rr;
  wire v_ri;wire v_rr;

  carry
  u1
  (
    .op(IsSubi | IsCmpi),
    .a(a[31]),
    .b(imm[31]),
    .s(res[31]),
    .c(c_ri)
  );


  carry
  u2
  (
    .op(IsSub | IsCmp | IsNeg),
    .a(a[31]),
    .b(b[31]),
    .s(res[31]),
    .c(c_rr)
  );


  overflow
  u3
  (
    .op(IsSubi | IsCmpi),
    .a(a[31]),
    .b(imm[31]),
    .s(res[31]),
    .v(v_ri)
  );


  overflow
  u4
  (
    .op(IsSub | IsCmp | IsNeg),
    .a(a[31]),
    .b(b[31]),
    .s(res[31]),
    .v(v_rr)
  );

  wire [7:0] bcdaddo;wire [7:0] bcdsubo;
  wire bcdaddc;wire bcdsubc;

  BCDAdd
  u5
  (
    .ci(cr0[0]),
    .a(a[7:0]),
    .b(b[7:0]),
    .o(bcdaddo),
    .c(bcdaddc)
  );


  BCDSub
  u6
  (
    .ci(cr0[0]),
    .a(a[7:0]),
    .b(b[7:0]),
    .o(bcdsubo),
    .c(bcdsubc)
  );

  wire [63:0] shlo;assign shlo = { 32'd0, a } << b[4:0];
  wire [63:0] shro;assign shro = { a, 32'd0 } >> b[4:0];
  reg res_sgn;
  wire [31:0] mp0;assign mp0 = aa[15:0] * bb[15:0];
  wire [31:0] mp1;assign mp1 = aa[15:0] * bb[31:16];
  wire [31:0] mp2;assign mp2 = aa[31:16] * bb[15:0];
  wire [31:0] mp3;assign mp3 = aa[31:16] * bb[31:16];
  reg [63:0] prod;
  wire divByZero;

  function [0:0] GetCrBit;
    input [4:0] Rn;
    begin
      case(Rn[4:2])
        3'd0: GetCrBit = cr0[Rn[1:0]];
        3'd1: GetCrBit = cr1[Rn[1:0]];
        3'd2: GetCrBit = cr2[Rn[1:0]];
        3'd3: GetCrBit = cr3[Rn[1:0]];
        3'd4: GetCrBit = cr4[Rn[1:0]];
        3'd5: GetCrBit = cr5[Rn[1:0]];
        3'd6: GetCrBit = cr6[Rn[1:0]];
        3'd7: GetCrBit = cr7[Rn[1:0]];
      endcase
    end
  endfunction


  function [3:0] GetCr;
    input [2:0] Rn;
    begin
      case(Rn)
        3'd0: GetCr = cr0;
        3'd1: GetCr = cr1;
        3'd2: GetCr = cr2;
        3'd3: GetCr = cr3;
        3'd4: GetCr = cr4;
        3'd5: GetCr = cr5;
        3'd6: GetCr = cr6;
        3'd7: GetCr = cr7;
      endcase
    end
  endfunction

  wire [3:0] crc;assign crc = GetCr(Rn[4:2]);
  wire cr_zf;assign cr_zf = crc[2];
  wire cr_nf;assign cr_nf = crc[3];
  wire cr_cf;assign cr_cf = crc[0];
  wire cr_vf;assign cr_vf = crc[1];

  BUFGCE
  u20
  (
    .CE(cpu_clk_en),
    .I(clk_i),
    .O(clk)
  );


  always @(posedge clk_i) if(RST) begin
    cpu_clk_en <= 1'b1;
  end else begin
    if(ipl_i == 3'd7) cpu_clk_en <= 1'b1; 
    else cpu_clk_en <= clk_en;
  end


  always @(posedge clk) if(RST) begin
    prev_nmi <= 1'b0;
    nmi_edge <= 1'b0;
    state <= RESET;
    im <= 3'b111;
    sf <= 1'b1;
    tf <= 1'b0;
    inta_o <= 1'b0;
    cyc_o <= 1'b0;
    stb_o <= 1'b0;
    sel_o <= 4'b0000;
    we_o <= 1'b0;
    clk_en <= 1'b1;
    tick <= 32'd0;
    rstsh <= 16'hFFFF;
  end else begin
    tick <= tick + 32'd1;
    clk_en <= 1'b1;
    rstsh <= { rstsh, 1'b0 };
    prev_nmi <= ipl_i == 3'd7;
    if(!prev_nmi && (ipl_i == 3'd7)) nmi_edge <= 1'b1; 
    case(state)
      RESET: begin
        im <= 3'b111;
        sf <= 1'b1;
        tf <= 1'b0;
        vector <= 32'h00000000;
        state <= LOAD_SP;
      end
      LOAD_SP: if(!cyc_o) begin
        fc_o <= { sf, 2'b01 };
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= vector;
      end else if(ack_i) begin
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        sel_o <= 4'b0000;
        ssp[31:2] <= dat_i[31:2];
        ssp[1:0] <= 2'b00;
        vector <= 32'h00000004;
        state <= VECTOR;
      end 
      VECTOR: if(!cyc_o) begin
        fc_o <= { sf, 2'b01 };
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= vector;
      end else if(ack_i) begin
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        sel_o <= 4'b0000;
        pc[31:2] <= dat_i[31:2];
        pc[1:0] <= 2'b00;
        state <= IFETCH;
      end 
      IFETCH: if(!cyc_o) begin
        if(halt_i) begin
        end else if(nmi_edge) begin
          sr1 <= sr;
          im <= ipl_i;
          tf <= 1'b0;
          sf <= 1'b1;
          iplr <= ipl_i;
          state <= INTA;
          nmi_edge <= 1'b0;
        end else if(ipl_i > im) begin
          sr1 <= sr;
          im <= ipl_i;
          tf <= 1'b0;
          sf <= 1'b1;
          iplr <= ipl_i;
          state <= INTA;
        end else if(tf) begin
          sr1 <= sr;
          tf <= 1'b0;
          sf <= 1'b1;
          vector <= 32'h00000024;
          state <= TRAP;
        end else begin
          fc_o <= { sf, 2'b10 };
          cyc_o <= 1'b1;
          stb_o <= 1'b1;
          sel_o <= 4'b1111;
          adr_o <= pc;
        end
      end else if(ack_i) begin
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        pc <= pc + 32'd4;
        ir <= dat_i;
        Rn <= dat_i[25:21];
        state <= REGFETCHA;
      end 
      REGFETCHA: begin
        Rcbit <= 1'b0;
        a <= rfo;
        b <= 32'd0;
        Rn <= ir[20:16];
        if(hasConst16 && (ir[15:0] == 16'h8000)) state <= FETCH_IMM32; 
        else begin
          case(opcode)
            6'd8: imm <= { 16'hFFFF, ir[15:0] };
            6'd9: imm <= { 16'h0000, ir[15:0] };
            6'd10: imm <= { 16'h0000, ir[15:0] };
            default: imm <= { { 16{ ir[15] } }, ir[15:0] };
          endcase
          state <= EXECUTE;
        end
        case(opcode)
          6'd0: case(func)
            6'd48: if(!sf) begin
              vector <= 32'h00000020;
              state <= TRAP;
            end else begin
              tf <= 1'b1;
              state <= IFETCH;
            end
            6'd49: if(!sf) begin
              vector <= 32'h00000020;
              state <= TRAP;
            end else begin
              tf <= 1'b0;
              state <= IFETCH;
            end
            6'd51: if(!sf) begin
              vector <= 32'h00000020;
              state <= TRAP;
            end else begin
              im <= ir[2:0];
              state <= IFETCH;
            end
            6'd50: begin
              sf <= 1'b0;
              state <= IFETCH;
            end
            6'd32: state <= JMP32;
            6'd33: state <= JSR32;
            6'd34: state <= RTS;
            6'd35: if(!sf) begin
              vector <= 32'h00000020;
              state <= TRAP;
            end else state <= RTI1;
            6'd52: if(!sf) begin
              vector <= 32'h00000020;
              state <= TRAP;
            end else begin
              rstsh <= 16'hFFFF;
              state <= IFETCH;
            end
            6'd53: if(!sf) begin
              vector <= 32'h00000020;
              state <= TRAP;
            end else begin
              im <= ir[8:6];
              tf <= ir[9];
              sf <= ir[10];
              clk_en <= 1'b0;
              state <= IFETCH;
            end
            default: begin
              vector <= 32'h00000010;
              state <= TRAP;
            end
          endcase
          6'd1: begin
            Rcbit <= ir[6];
            case(func)
              6'd24: state <= UNLK;
              6'd1, 6'd2, 6'd3, 6'd4, 6'd5, 6'd6, 6'd33, 6'd32, 6'd48, 6'd63: ;
              default: begin
                vector <= 32'h00000010;
                state <= TRAP;
              end
            endcase
          end
          6'd60: state <= IFETCH;
          6'd21: begin
            tgt <= { pc[31:26], ir[25:2], 2'b00 };
            state <= JSR1;
          end
          6'd20: begin
            pc[25:2] <= ir[25:2];
            state <= IFETCH;
          end
          6'd16: case(cond)
            4'd0: begin
              pc <= pc + brdisp;
              state <= IFETCH;
            end
            4'd1: begin
              state <= IFETCH;
            end
            4'd7: begin
              if(cr_zf) pc <= pc + brdisp; 
              state <= IFETCH;
            end
            4'd6: begin
              if(!cr_zf) pc <= pc + brdisp; 
              state <= IFETCH;
            end
            4'd11: begin
              if(cr_nf) pc <= pc + brdisp; 
              state <= IFETCH;
            end
            4'd10: begin
              if(!cr_zf) pc <= pc + brdisp; 
              state <= IFETCH;
            end
            4'd2: begin
              if(!cr_cf & !cr_zf) pc <= pc + brdisp; 
              state <= IFETCH;
            end
            4'd3: begin
              if(cf | zf) pc <= pc + brdisp; 
              state <= IFETCH;
            end
            4'd4: begin
              if(!cr_cf) pc <= pc + brdisp; 
              state <= IFETCH;
            end
            4'd5: begin
              if(cr_cf) pc <= pc + brdisp; 
              state <= IFETCH;
            end
            4'd14: begin
              if(cr_nf & cr_vf & !cr_zf | !cr_nf & !cr_vf & !cr_zf) pc <= pc + brdisp; 
              state <= IFETCH;
            end
            4'd15: begin
              if(cr_zf | cr_nf & !cr_vf | !cr_nf & cr_vf) pc <= pc + brdisp; 
              state <= IFETCH;
            end
            4'd12: begin
              if(cr_nf & cr_vf | !cr_nf & !cr_vf) pc <= pc + brdisp; 
              state <= IFETCH;
            end
            4'd13: begin
              if(cr_nf & !cr_vf | !cr_nf & cr_vf) pc <= pc + brdisp; 
              state <= IFETCH;
            end
            4'd9: begin
              if(cr_vf) pc <= pc + brdisp; 
              state <= IFETCH;
            end
            4'd8: begin
              if(!cr_vf) pc <= pc + brdisp; 
              state <= IFETCH;
            end
          endcase
          6'd17: case(cond)
            4'd0: begin
              vector <= 32'h00000080 + { ir[3:0], 2'b00 };
              state <= TRAP;
            end
            4'd7: begin
              if(cr_zf) begin
                vector <= 32'h00000080;
                state <= TRAP;
              end else state <= IFETCH;
            end
            4'd6: begin
              if(!cr_zf) begin
                vector <= 32'h00000080;
                state <= TRAP;
              end else state <= IFETCH;
            end
            4'd11: begin
              if(cr_nf) begin
                vector <= 32'h00000080;
                state <= TRAP;
              end else state <= IFETCH;
            end
            4'd10: begin
              if(!cr_zf) begin
                vector <= 32'h00000080;
                state <= TRAP;
              end else state <= IFETCH;
            end
            4'd2: begin
              if(!cr_cf & !cr_zf) begin
                vector <= 32'h00000080;
                state <= TRAP;
              end else state <= IFETCH;
            end
            4'd3: begin
              if(cf | zf) begin
                vector <= 32'h00000080;
                state <= TRAP;
              end else state <= IFETCH;
            end
            4'd4: begin
              if(!cr_cf) begin
                vector <= 32'h00000080;
                state <= TRAP;
              end else state <= IFETCH;
            end
            4'd5: begin
              if(cr_cf) begin
                vector <= 32'h00000080;
                state <= TRAP;
              end else state <= IFETCH;
            end
            4'd14: begin
              if(cr_nf & cr_vf & !cr_zf | !cr_nf & !cr_vf & !cr_zf) begin
                vector <= 32'h00000080;
                state <= TRAP;
              end else state <= IFETCH;
            end
            4'd15: begin
              if(cr_zf | cr_nf & !cr_vf | !cr_nf & cr_vf) begin
                vector <= 32'h00000080;
                state <= TRAP;
              end else state <= IFETCH;
            end
            4'd12: begin
              if(cr_nf & cr_vf | !cr_nf & !cr_vf) begin
                vector <= 32'h00000080;
                state <= TRAP;
              end else state <= IFETCH;
            end
            4'd13: begin
              if(cr_nf & !cr_vf | !cr_nf & cr_vf) begin
                vector <= 32'h00000080;
                state <= TRAP;
              end else state <= IFETCH;
            end
            4'd9: begin
              if(cr_vf) begin
                vector <= 32'h0000001C;
                state <= TRAP;
              end else state <= IFETCH;
            end
            4'd8: begin
              if(!cr_vf) begin
                vector <= 32'h0000001C;
                state <= TRAP;
              end else state <= IFETCH;
            end
          endcase
          6'd18: Rn <= ir[15:11];
          6'd59: state <= PUSH1;
          6'd53: state <= POP1;
          6'd2: begin
            state <= REGFETCHB;
            Rcbit <= ir[6];
            case(func)
              6'd21, 6'd20, 6'd4, 6'd5, 6'd6, 6'd60, 6'd61, 6'd8, 6'd9, 6'd10, 6'd12, 6'd13, 6'd14, 6'd16, 6'd17, 6'd18, 6'd19, 6'd24, 6'd26, 6'd25, 6'd27, 6'd28, 6'd29, 6'd30, 6'd31, 6'd48, 6'd49, 6'd50, 6'd51, 6'd52, 6'd56, 6'd57, 6'd58, 6'd23, 6'd22: ;
              default: begin
                vector <= 32'h00000010;
                state <= TRAP;
              end
            endcase
          end
          6'd3: state <= REGFETCHB;
          6'd19: case(func1)
            10'd449: begin
              state <= IFETCH;
              case(ir[15:13])
                3'd0: cr0[ir[12:11]] <= GetCrBit(ir[25:21]) | GetCrBit(ir[20:16]);
                3'd1: cr1[ir[12:11]] <= GetCrBit(ir[25:21]) | GetCrBit(ir[20:16]);
                3'd2: cr2[ir[12:11]] <= GetCrBit(ir[25:21]) | GetCrBit(ir[20:16]);
                3'd3: cr3[ir[12:11]] <= GetCrBit(ir[25:21]) | GetCrBit(ir[20:16]);
                3'd4: cr4[ir[12:11]] <= GetCrBit(ir[25:21]) | GetCrBit(ir[20:16]);
                3'd5: cr5[ir[12:11]] <= GetCrBit(ir[25:21]) | GetCrBit(ir[20:16]);
                3'd6: cr6[ir[12:11]] <= GetCrBit(ir[25:21]) | GetCrBit(ir[20:16]);
                3'd7: cr7[ir[12:11]] <= GetCrBit(ir[25:21]) | GetCrBit(ir[20:16]);
              endcase
            end
            10'd417: begin
              state <= IFETCH;
              case(ir[15:13])
                3'd0: cr0[ir[12:11]] <= GetCrBit(ir[25:21]) | ~GetCrBit(ir[20:16]);
                3'd1: cr1[ir[12:11]] <= GetCrBit(ir[25:21]) | ~GetCrBit(ir[20:16]);
                3'd2: cr2[ir[12:11]] <= GetCrBit(ir[25:21]) | ~GetCrBit(ir[20:16]);
                3'd3: cr3[ir[12:11]] <= GetCrBit(ir[25:21]) | ~GetCrBit(ir[20:16]);
                3'd4: cr4[ir[12:11]] <= GetCrBit(ir[25:21]) | ~GetCrBit(ir[20:16]);
                3'd5: cr5[ir[12:11]] <= GetCrBit(ir[25:21]) | ~GetCrBit(ir[20:16]);
                3'd6: cr6[ir[12:11]] <= GetCrBit(ir[25:21]) | ~GetCrBit(ir[20:16]);
                3'd7: cr7[ir[12:11]] <= GetCrBit(ir[25:21]) | ~GetCrBit(ir[20:16]);
              endcase
            end
            10'd257: begin
              state <= IFETCH;
              case(ir[15:13])
                3'd0: cr0[ir[12:11]] <= GetCrBit(ir[25:21]) & GetCrBit(ir[20:16]);
                3'd1: cr1[ir[12:11]] <= GetCrBit(ir[25:21]) & GetCrBit(ir[20:16]);
                3'd2: cr2[ir[12:11]] <= GetCrBit(ir[25:21]) & GetCrBit(ir[20:16]);
                3'd3: cr3[ir[12:11]] <= GetCrBit(ir[25:21]) & GetCrBit(ir[20:16]);
                3'd4: cr4[ir[12:11]] <= GetCrBit(ir[25:21]) & GetCrBit(ir[20:16]);
                3'd5: cr5[ir[12:11]] <= GetCrBit(ir[25:21]) & GetCrBit(ir[20:16]);
                3'd6: cr6[ir[12:11]] <= GetCrBit(ir[25:21]) & GetCrBit(ir[20:16]);
                3'd7: cr7[ir[12:11]] <= GetCrBit(ir[25:21]) & GetCrBit(ir[20:16]);
              endcase
            end
            10'd129: begin
              state <= IFETCH;
              case(ir[15:13])
                3'd0: cr0[ir[12:11]] <= GetCrBit(ir[25:21]) & ~GetCrBit(ir[20:16]);
                3'd1: cr1[ir[12:11]] <= GetCrBit(ir[25:21]) & ~GetCrBit(ir[20:16]);
                3'd2: cr2[ir[12:11]] <= GetCrBit(ir[25:21]) & ~GetCrBit(ir[20:16]);
                3'd3: cr3[ir[12:11]] <= GetCrBit(ir[25:21]) & ~GetCrBit(ir[20:16]);
                3'd4: cr4[ir[12:11]] <= GetCrBit(ir[25:21]) & ~GetCrBit(ir[20:16]);
                3'd5: cr5[ir[12:11]] <= GetCrBit(ir[25:21]) & ~GetCrBit(ir[20:16]);
                3'd6: cr6[ir[12:11]] <= GetCrBit(ir[25:21]) & ~GetCrBit(ir[20:16]);
                3'd7: cr7[ir[12:11]] <= GetCrBit(ir[25:21]) & ~GetCrBit(ir[20:16]);
              endcase
            end
            10'd193: begin
              state <= IFETCH;
              case(ir[15:13])
                3'd0: cr0[ir[12:11]] <= GetCrBit(ir[25:21]) ^ GetCrBit(ir[20:16]);
                3'd1: cr1[ir[12:11]] <= GetCrBit(ir[25:21]) ^ GetCrBit(ir[20:16]);
                3'd2: cr2[ir[12:11]] <= GetCrBit(ir[25:21]) ^ GetCrBit(ir[20:16]);
                3'd3: cr3[ir[12:11]] <= GetCrBit(ir[25:21]) ^ GetCrBit(ir[20:16]);
                3'd4: cr4[ir[12:11]] <= GetCrBit(ir[25:21]) ^ GetCrBit(ir[20:16]);
                3'd5: cr5[ir[12:11]] <= GetCrBit(ir[25:21]) ^ GetCrBit(ir[20:16]);
                3'd6: cr6[ir[12:11]] <= GetCrBit(ir[25:21]) ^ GetCrBit(ir[20:16]);
                3'd7: cr7[ir[12:11]] <= GetCrBit(ir[25:21]) ^ GetCrBit(ir[20:16]);
              endcase
            end
            10'd33: begin
              state <= IFETCH;
              case(ir[15:13])
                3'd0: cr0[ir[12:11]] <= ~(GetCrBit(ir[25:21]) | GetCrBit(ir[20:16]));
                3'd1: cr1[ir[12:11]] <= ~(GetCrBit(ir[25:21]) | GetCrBit(ir[20:16]));
                3'd2: cr2[ir[12:11]] <= ~(GetCrBit(ir[25:21]) | GetCrBit(ir[20:16]));
                3'd3: cr3[ir[12:11]] <= ~(GetCrBit(ir[25:21]) | GetCrBit(ir[20:16]));
                3'd4: cr4[ir[12:11]] <= ~(GetCrBit(ir[25:21]) | GetCrBit(ir[20:16]));
                3'd5: cr5[ir[12:11]] <= ~(GetCrBit(ir[25:21]) | GetCrBit(ir[20:16]));
                3'd6: cr6[ir[12:11]] <= ~(GetCrBit(ir[25:21]) | GetCrBit(ir[20:16]));
                3'd7: cr7[ir[12:11]] <= ~(GetCrBit(ir[25:21]) | GetCrBit(ir[20:16]));
              endcase
            end
            10'd225: begin
              state <= IFETCH;
              case(ir[15:13])
                3'd0: cr0[ir[12:11]] <= ~(GetCrBit(ir[25:21]) & GetCrBit(ir[20:16]));
                3'd1: cr1[ir[12:11]] <= ~(GetCrBit(ir[25:21]) & GetCrBit(ir[20:16]));
                3'd2: cr2[ir[12:11]] <= ~(GetCrBit(ir[25:21]) & GetCrBit(ir[20:16]));
                3'd3: cr3[ir[12:11]] <= ~(GetCrBit(ir[25:21]) & GetCrBit(ir[20:16]));
                3'd4: cr4[ir[12:11]] <= ~(GetCrBit(ir[25:21]) & GetCrBit(ir[20:16]));
                3'd5: cr5[ir[12:11]] <= ~(GetCrBit(ir[25:21]) & GetCrBit(ir[20:16]));
                3'd6: cr6[ir[12:11]] <= ~(GetCrBit(ir[25:21]) & GetCrBit(ir[20:16]));
                3'd7: cr7[ir[12:11]] <= ~(GetCrBit(ir[25:21]) & GetCrBit(ir[20:16]));
              endcase
            end
            10'd289: begin
              state <= IFETCH;
              case(ir[15:13])
                3'd0: cr0[ir[12:11]] <= ~(GetCrBit(ir[25:21]) ^ GetCrBit(ir[20:16]));
                3'd1: cr1[ir[12:11]] <= ~(GetCrBit(ir[25:21]) ^ GetCrBit(ir[20:16]));
                3'd2: cr2[ir[12:11]] <= ~(GetCrBit(ir[25:21]) ^ GetCrBit(ir[20:16]));
                3'd3: cr3[ir[12:11]] <= ~(GetCrBit(ir[25:21]) ^ GetCrBit(ir[20:16]));
                3'd4: cr4[ir[12:11]] <= ~(GetCrBit(ir[25:21]) ^ GetCrBit(ir[20:16]));
                3'd5: cr5[ir[12:11]] <= ~(GetCrBit(ir[25:21]) ^ GetCrBit(ir[20:16]));
                3'd6: cr6[ir[12:11]] <= ~(GetCrBit(ir[25:21]) ^ GetCrBit(ir[20:16]));
                3'd7: cr7[ir[12:11]] <= ~(GetCrBit(ir[25:21]) ^ GetCrBit(ir[20:16]));
              endcase
            end
            default: begin
              vector <= 32'h00000010;
              state <= TRAP;
            end
          endcase
          6'd4, 6'd5, 6'd6, 6'd8, 6'd9, 6'd10, 6'd12, 6'd13, 6'd14, 6'd15, 6'd55, 6'd54, 6'd46, 6'd50, 6'd49, 6'd48, 6'd52, 6'd51: ;
          6'd58, 6'd57, 6'd56: state <= REGFETCHB;
          default: begin
            vector <= 32'h00000010;
            state <= TRAP;
          end
        endcase
      end
      REGFETCHB: begin
        b <= rfo;
        Rn <= ir[15:11];
        if((opcode == 6'd3) || (opcode == 6'd2) && ((func == 6'd56) || (func == 6'd57) || (func == 6'd58))) state <= REGFETCHC; 
        else begin
          if(hasConst16 && (ir[15:0] == 16'h8000)) state <= FETCH_IMM32; 
          else begin
            case(opcode)
              6'd8: imm <= { 16'hFFFF, ir[15:0] };
              6'd9: imm <= { 16'h0000, ir[15:0] };
              6'd10: imm <= { 16'h0000, ir[15:0] };
              default: imm <= { { 16{ ir[15] } }, ir[15:0] };
            endcase
            state <= EXECUTE;
          end
        end
      end
      REGFETCHC: begin
        c <= rfo;
        Rn <= ir[10:6];
        state <= EXECUTE;
      end
      FETCH_IMM32: if(!cyc_o) begin
        fc_o <= { sf, 2'b10 };
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= pc;
      end else if(ack_i) begin
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        sel_o <= 4'b0000;
        imm <= dat_i;
        pc <= pc + 32'd4;
        state <= EXECUTE;
      end 
      EXECUTE: begin
        state <= WRITEBACK;
        case(opcode)
          6'd1: begin
            case(func)
              6'd1: res <= (a[31])? -a : a;
              6'd2: res <= (a[31])? 32'hFFFFFFFF : |a;
              6'd3: res <= -a;
              6'd4: res <= ~a;
              6'd5: res <= { { 24{ a[7] } }, a[7:0] };
              6'd6: res <= { { 16{ a[15] } }, a[15:0] };
              6'd33: casex(ir[25:21])
                5'b00xxx: res <= GetCr(ir[23:21]);
                5'b01000: res <= cr;
                5'b01001: res <= usp;
                5'b01010: if(!sf) begin
                  vector <= 32'h00000020;
                  state <= TRAP;
                end else begin
                  res <= im;
                end
                5'b01011: res <= be_addr;
                5'b01111: res <= tick;
              endcase
              6'd32: casex(ir[20:16])
                5'b00xxx: begin
                  state <= IFETCH;
                  case(ir[18:16])
                    3'd0: cr0 <= a[3:0];
                    3'd1: cr1 <= a[3:0];
                    3'd2: cr2 <= a[3:0];
                    3'd3: cr3 <= a[3:0];
                    3'd4: cr4 <= a[3:0];
                    3'd5: cr5 <= a[3:0];
                    3'd6: cr6 <= a[3:0];
                    3'd7: cr7 <= a[3:0];
                  endcase
                end
                5'b01000: begin
                  state <= IFETCH;
                  cr0 <= a[3:0];
                  cr1 <= a[7:4];
                  cr2 <= a[11:8];
                  cr3 <= a[15:12];
                  cr4 <= a[19:16];
                  cr5 <= a[23:20];
                  cr6 <= a[27:24];
                  cr7 <= a[31:28];
                end
                5'b01001: usp <= a;
                5'b01010: if(!sf) begin
                  vector <= 32'h00000020;
                  state <= TRAP;
                end else begin
                  im <= a[2:0];
                  state <= IFETCH;
                end
              endcase
              6'd63: begin
                ir <= a;
                Rn <= a[25:21];
                state <= REGFETCHA;
              end
              6'd48: begin
                state <= IFETCH;
                case(ir[18:16])
                  3'd0: cr0 <= GetCr(ir[23:21]);
                  3'd1: cr1 <= GetCr(ir[23:21]);
                  3'd2: cr2 <= GetCr(ir[23:21]);
                  3'd3: cr3 <= GetCr(ir[23:21]);
                  3'd4: cr4 <= GetCr(ir[23:21]);
                  3'd5: cr5 <= GetCr(ir[23:21]);
                  3'd6: cr6 <= GetCr(ir[23:21]);
                  3'd7: cr7 <= GetCr(ir[23:21]);
                endcase
              end
              default: res <= 32'd0;
            endcase
          end
          6'd2: begin
            case(func)
              6'd4: res <= a + b;
              6'd5: res <= a - b;
              6'd6: res <= a - b;
              6'd8: res <= a & b;
              6'd11: res <= a & ~b;
              6'd9: res <= a | b;
              6'd15: res <= a | ~b;
              6'd10: res <= a ^ b;
              6'd12: res <= ~(a & b);
              6'd13: res <= ~(a | b);
              6'd14: res <= ~(a ^ b);
              6'd16: res <= shlo[31:0];
              6'd17: res <= shro[63:32];
              6'd18: res <= shlo[31:0] | shlo[63:32];
              6'd19: res <= shro[31:0] | shro[63:32];
              6'd23: res <= (as < bs)? as : bs;
              6'd22: res <= (as < bs)? bs : as;
              6'd60: res <= bcdaddo;
              6'd61: res <= bcdsubo;
              default: res <= 32'd0;
            endcase
            if(func == 6'd20) begin
              pc <= a + b;
              pc[1:0] <= 2'b00;
              state <= IFETCH;
            end else if(func == 6'd21) begin
              tgt <= a + b;
              tgt[1:0] <= 2'b00;
              state <= JSR1;
            end 
            case(func)
              6'd48: begin
                ea <= a + b;
                mopcode <= 6'd48;
                state <= MEMORY1;
              end
              6'd49: begin
                ea <= a + b;
                mopcode <= 6'd49;
                state <= MEMORY1;
              end
              6'd51: begin
                ea <= a + b;
                mopcode <= 6'd51;
                state <= MEMORY1;
              end
              6'd50: begin
                ea <= a + b;
                mopcode <= 6'd50;
                state <= MEMORY1;
              end
              6'd52: begin
                ea <= a + b;
                mopcode <= 6'd52;
                state <= MEMORY1;
              end
              6'd58: begin
                ea <= a + b;
                mopcode <= 6'd58;
                b <= c;
                state <= MEMORY1;
              end
              6'd57: begin
                ea <= a + b;
                mopcode <= 6'd57;
                b <= c;
                state <= MEMORY1;
              end
              6'd56: begin
                ea <= a + b;
                mopcode <= 6'd56;
                b <= c;
                state <= MEMORY1;
              end
              6'd24: state <= MULTDIV1;
              6'd26: state <= MULTDIV1;
              6'd25: state <= MULTDIV1;
              6'd27: state <= MULTDIV1;
              6'd28: state <= MULTDIV1;
              6'd29: state <= MULTDIV1;
              6'd30: state <= MULTDIV1;
              6'd31: state <= MULTDIV1;
            endcase
          end
          6'd18: begin
            case(cond)
              4'd0: res <= 32'd1;
              4'd7: res <= cr_zf;
              4'd6: res <= !cr_zf;
              4'd11: res <= cr_nf;
              4'd10: res <= !cr_zf;
              4'd2: res <= !cr_cf & !cr_zf;
              4'd3: res <= cf | zf;
              4'd4: res <= !cr_cf;
              4'd5: res <= cr_cf;
              4'd14: res <= cr_nf & cr_vf & !cr_zf | !cr_nf & !cr_vf & !cr_zf;
              4'd15: res <= cr_zf | cr_nf & !cr_vf | !cr_nf & cr_vf;
              4'd12: res <= cr_nf & cr_vf | !cr_nf & !cr_vf;
              4'd13: res <= cr_nf & !cr_vf | !cr_nf & cr_vf;
              4'd9: res <= cr_vf;
              4'd8: res <= !cr_vf;
            endcase
          end
          6'd4: res <= a + imm;
          6'd5: res <= a - imm;
          6'd6: res <= a - imm;
          6'd8: res <= a & imm;
          6'd9: res <= a | imm;
          6'd10: res <= a ^ imm;
          6'd54: state <= LINK;
          6'd12: state <= MULTDIV1;
          6'd13: state <= MULTDIV1;
          6'd14: state <= MULTDIV1;
          6'd15: state <= MULTDIV1;
          default: res <= 32'd0;
        endcase
        case(opcode)
          6'd46: begin
            ea <= a + imm;
            mopcode <= opcode;
            state <= TAS;
          end
          6'd48: begin
            ea <= a + imm;
            mopcode <= opcode;
            state <= MEMORY1;
          end
          6'd49: begin
            ea <= a + imm;
            mopcode <= opcode;
            state <= MEMORY1;
          end
          6'd50: begin
            ea <= a + imm;
            mopcode <= opcode;
            state <= MEMORY1;
          end
          6'd51: begin
            ea <= a + imm;
            mopcode <= opcode;
            state <= MEMORY1;
          end
          6'd52: begin
            ea <= a + imm;
            mopcode <= opcode;
            state <= MEMORY1;
          end
          6'd56: begin
            ea <= a + imm;
            mopcode <= opcode;
            state <= MEMORY1;
          end
          6'd57: begin
            ea <= a + imm;
            mopcode <= opcode;
            state <= MEMORY1;
          end
          6'd58: begin
            ea <= a + imm;
            mopcode <= opcode;
            state <= MEMORY1;
          end
          6'd55: begin
            ea <= a + imm;
            mopcode <= opcode;
            state <= PEA;
          end
          default: ea <= 32'd0;
        endcase
      end
      MEMORY1: begin
        case(mopcode)
          6'd48: begin
            fc_o <= { sf, 2'b01 };
            cyc_o <= 1'b1;
            stb_o <= 1'b1;
            sel_o <= 4'b1111;
            adr_o <= ea;
            state <= MEMORY1_ACK;
          end
          6'd49, 6'd51: begin
            fc_o <= { sf, 2'b01 };
            cyc_o <= 1'b1;
            stb_o <= 1'b1;
            sel_o <= (ea[1])? 4'b1100 : 4'b0011;
            adr_o <= ea;
            state <= MEMORY1_ACK;
          end
          6'd50, 6'd52: begin
            fc_o <= { sf, 2'b01 };
            cyc_o <= 1'b1;
            stb_o <= 1'b1;
            case(ea[1:0])
              2'd0: sel_o <= 4'b0001;
              2'd1: sel_o <= 4'b0010;
              2'd2: sel_o <= 4'b0100;
              2'd3: sel_o <= 4'b1000;
            endcase
            adr_o <= ea;
            state <= MEMORY1_ACK;
          end
          6'd56: begin
            fc_o <= { sf, 2'b01 };
            cyc_o <= 1'b1;
            stb_o <= 1'b1;
            we_o <= 1'b1;
            sel_o <= 4'b1111;
            adr_o <= ea;
            dat_o <= b;
            state <= MEMORY1_ACK;
          end
          6'd57: begin
            fc_o <= { sf, 2'b01 };
            cyc_o <= 1'b1;
            stb_o <= 1'b1;
            we_o <= 1'b1;
            sel_o <= (ea[1])? 4'b1100 : 4'b0011;
            adr_o <= ea;
            dat_o <= { 2{ b[15:0] } };
            state <= MEMORY1_ACK;
          end
          6'd58: begin
            fc_o <= { sf, 2'b01 };
            cyc_o <= 1'b1;
            stb_o <= 1'b1;
            we_o <= 1'b1;
            case(ea[1:0])
              2'd0: sel_o <= 4'b0001;
              2'd1: sel_o <= 4'b0010;
              2'd2: sel_o <= 4'b0100;
              2'd3: sel_o <= 4'b1000;
            endcase
            adr_o <= ea;
            dat_o <= { 4{ b[7:0] } };
            state <= MEMORY1_ACK;
          end
        endcase
      end
      MEMORY1_ACK: if(ack_i) begin
        case(mopcode)
          6'd48: begin
            cyc_o <= 1'b0;
            stb_o <= 1'b0;
            sel_o <= 4'b0000;
            res <= dat_i;
            state <= WRITEBACK;
          end
          6'd49: begin
            cyc_o <= 1'b0;
            stb_o <= 1'b0;
            sel_o <= 4'b0000;
            if(sel_o == 4'b0011) res <= { { 16{ dat_i[15] } }, dat_i[15:0] }; 
            else res <= { { 16{ dat_i[31] } }, dat_i[31:16] };
            state <= WRITEBACK;
          end
          6'd51: begin
            cyc_o <= 1'b0;
            stb_o <= 1'b0;
            sel_o <= 4'b0000;
            if(sel_o == 4'b0011) res <= { 16'd0, dat_i[15:0] }; 
            else res <= { 16'd0, dat_i[31:16] };
            state <= WRITEBACK;
          end
          6'd50: begin
            cyc_o <= 1'b0;
            stb_o <= 1'b0;
            sel_o <= 4'b0000;
            case(sel_o)
              4'b0001: res <= { { 24{ dat_i[7] } }, dat_i[7:0] };
              4'b0010: res <= { { 24{ dat_i[15] } }, dat_i[15:8] };
              4'b0100: res <= { { 24{ dat_i[23] } }, dat_i[23:16] };
              4'b1000: res <= { { 24{ dat_i[31] } }, dat_i[31:24] };
            endcase
            state <= WRITEBACK;
          end
          6'd52: begin
            cyc_o <= 1'b0;
            stb_o <= 1'b0;
            sel_o <= 4'b0000;
            case(sel_o)
              4'b0001: res <= { 24'd0, dat_i[7:0] };
              4'b0010: res <= { 24'd0, dat_i[15:8] };
              4'b0100: res <= { 24'd0, dat_i[23:16] };
              4'b1000: res <= { 24'd0, dat_i[31:24] };
            endcase
            state <= WRITEBACK;
          end
          6'd56, 6'd57, 6'd58: begin
            cyc_o <= 1'b0;
            stb_o <= 1'b0;
            we_o <= 1'b0;
            sel_o <= 4'b0000;
            state <= IFETCH;
          end
        endcase
      end 
      TAS: if(!cyc_o) begin
        fc_o <= { sf, 2'b01 };
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= ea;
      end else if(ack_i) begin
        cyc_o <= ~dat_i[31];
        stb_o <= 1'b0;
        sel_o <= 4'b0000;
        res <= dat_i;
        state <= TAS2;
      end 
      TAS2: if(!res[31]) begin
        if(!stb_o) begin
          fc_o <= { sf, 2'b01 };
          cyc_o <= 1'b1;
          stb_o <= 1'b1;
          we_o <= 1'b1;
          sel_o <= 4'b1111;
          adr_o <= ea;
          dat_o <= { 1'b1, res[30:0] };
        end else if(ack_i) begin
          cyc_o <= 1'b0;
          stb_o <= 1'b0;
          we_o <= 1'b0;
          sel_o <= 4'b0000;
          state <= WRITEBACK;
        end 
      end else begin
        cyc_o <= 1'b0;
        state <= WRITEBACK;
      end
      PUSH1: if(ir[25:1] == 25'd0) state <= IFETCH; 
      else begin
        Rn <= ir[25:21];
        ir[25:0] <= { ir[20:1], 6'b0 };
        if(ir[25:21] != 5'd0) state <= PUSH2; 
      end
      PUSH2: begin
        fc_o <= { sf, 2'b01 };
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        we_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= (sf)? ssp - 32'd4 : usp - 32'd4;
        dat_o <= rfo;
        state <= PUSH3;
      end
      PUSH3: if(ack_i) begin
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        we_o <= 1'b0;
        sel_o <= 4'b0000;
        if(sf) ssp <= ssp - 32'd4; 
        else usp <= usp - 32'd4;
        state <= PUSH1;
      end 
      PEA: if(!cyc_o) begin
        fc_o <= { sf, 2'b01 };
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        we_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= (sf)? ssp - 32'd4 : usp - 32'd4;
        dat_o <= ea;
      end else if(ack_i) begin
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        we_o <= 1'b0;
        sel_o <= 4'b0000;
        if(sf) ssp <= ssp - 32'd4; 
        else usp <= usp - 32'd4;
        state <= IFETCH;
      end 
      LINK: if(!cyc_o) begin
        fc_o <= { sf, 2'b01 };
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        we_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= (sf)? ssp - 32'd4 : usp - 32'd4;
        dat_o <= a;
      end else if(ack_i) begin
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        we_o <= 1'b0;
        sel_o <= 4'b0000;
        if(sf) begin
          ssp <= ssp - 32'd4;
          res <= ssp - 32'd4;
        end else begin
          usp <= usp - 32'd4;
          res <= usp - 32'd4;
        end
        state <= WRITEBACK;
      end 
      POP1: if(ir[25:1] == 25'd0) state <= IFETCH; 
      else begin
        Rn <= ir[25:21];
        ir[25:0] <= { ir[20:1], 6'b0 };
        if(ir[25:21] != 5'd0) state <= POP2; 
      end
      POP2: begin
        fc_o <= { sf, 2'b01 };
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= (sf)? ssp : usp;
        state <= POP3;
      end
      POP3: if(ack_i) begin
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        sel_o <= 4'b0000;
        if(sf) ssp <= ssp + 32'd4; 
        else usp <= usp + 32'd4;
        res <= dat_i;
        state <= WRITEBACK;
      end 
      UNLK: if(!cyc_o) begin
        fc_o <= { sf, 2'b01 };
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= a;
        if(sf) ssp <= a; 
        else usp <= a;
      end else if(ack_i) begin
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        sel_o <= 4'b0000;
        if(sf) ssp <= ssp + 32'd4; 
        else usp <= usp + 32'd4;
        res <= dat_i;
        state <= WRITEBACK;
      end 
      WRITEBACK: begin
        state <= WRITE_FLAGS;
        if((opcode != 6'd6) && !((opcode == 6'd2) && (func == 6'd6))) begin
          regfile[Rn] <= res;
          if(Rn == 5'd31) begin
            if(sf) ssp <= res; 
            else usp <= res;
          end 
        end 
        case(opcode)
          6'd1: case(func)
            6'd1: begin
              if(!Rcbit) state <= IFETCH; 
              vf <= res[31];
              cf <= 1'b0;
              nf <= res[31];
              zf <= res == 32'd0;
            end
            6'd2, 6'd4, 6'd5, 6'd6: begin
              if(!Rcbit) state <= IFETCH; 
              vf <= 1'b0;
              cf <= 1'b0;
              nf <= res[31];
              zf <= res == 32'd0;
            end
            6'd3: begin
              if(!Rcbit) state <= IFETCH; 
              vf <= v_rr;
              cf <= c_rr;
              nf <= res[31];
              zf <= res == 32'd0;
            end
          endcase
          6'd2: case(func)
            6'd4, 6'd5: begin
              if(!Rcbit) state <= IFETCH; 
              vf <= v_rr;
              cf <= c_rr;
              nf <= res[31];
              zf <= res == 32'd0;
            end
            6'd6: begin
              state <= WRITE_FLAGS;
              vf <= 1'b0;
              cf <= c_rr;
              nf <= res[31];
              zf <= res == 32'd0;
            end
            6'd8, 6'd9, 6'd10, 6'd12, 6'd13, 6'd14, 6'd23, 6'd22, 6'd48, 6'd49, 6'd50, 6'd51, 6'd52: begin
              if(!Rcbit) state <= IFETCH; 
              vf <= 1'b0;
              cf <= 1'b0;
              nf <= res[31];
              zf <= res == 32'd0;
            end
            6'd16, 6'd18: begin
              if(!Rcbit) state <= IFETCH; 
              vf <= 1'b0;
              cf <= shlo[32];
              nf <= res[31];
              zf <= res == 32'd0;
            end
            6'd17, 6'd19: begin
              if(!Rcbit) state <= IFETCH; 
              vf <= 1'b0;
              cf <= shro[31];
              nf <= res[31];
              zf <= res == 32'd0;
            end
            6'd60: begin
              if(!Rcbit) state <= IFETCH; 
              vf <= 1'b0;
              cf <= bcdaddc;
              nf <= res[7];
              zf <= res[7:0] == 8'd0;
            end
            6'd61: begin
              if(!Rcbit) state <= IFETCH; 
              vf <= 1'b0;
              cf <= bcdsubc;
              nf <= res[7];
              zf <= res[7:0] == 8'd0;
            end
            6'd28, 6'd29, 6'd30, 6'd31: begin
              if(!Rcbit) state <= IFETCH; 
              vf <= divByZero;
              cf <= divByZero;
              nf <= res[31];
              zf <= res == 32'd0;
            end
            6'd24, 6'd26, 6'd25, 6'd27: begin
              if(!Rcbit) state <= IFETCH; 
              cf <= vf;
              nf <= res[31];
              zf <= res == 32'd0;
            end
          endcase
          6'd4, 6'd5: begin
            vf <= v_ri;
            cf <= c_ri;
            nf <= res[31];
            zf <= res == 32'd0;
          end
          6'd6: begin
            vf <= 1'b0;
            cf <= c_ri;
            nf <= res[31];
            zf <= res == 32'd0;
          end
          6'd8, 6'd9, 6'd10, 6'd48, 6'd49, 6'd50, 6'd51, 6'd52, 6'd53, 6'd46: begin
            vf <= 1'b0;
            cf <= 1'b0;
            nf <= res[31];
            zf <= res == 32'd0;
          end
          6'd15, 6'd14: begin
            vf <= divByZero;
            cf <= divByZero;
            nf <= res[31];
            zf <= res == 32'd0;
          end
          6'd13, 6'd12: begin
            cf <= vf;
            nf <= res[31];
            zf <= res == 32'd0;
          end
          6'd53: state <= POP1;
          6'd54: begin
            state <= IFETCH;
            if(sf) ssp <= ssp - imm; 
            else usp <= usp - imm;
          end
        endcase
      end
      WRITE_FLAGS: begin
        state <= IFETCH;
        if((opcode == 6'd6) || (opcode == 6'd2) && (func == 6'd6)) begin
          $display("Writing flags to Cr%d", Rn[4:2]);
          case(Rn[4:2])
            3'd0: cr0 <= { nf, zf, vf, cf };
            3'd1: cr1 <= { nf, zf, vf, cf };
            3'd2: cr2 <= { nf, zf, vf, cf };
            3'd3: cr3 <= { nf, zf, vf, cf };
            3'd4: cr4 <= { nf, zf, vf, cf };
            3'd5: cr5 <= { nf, zf, vf, cf };
            3'd6: cr6 <= { nf, zf, vf, cf };
            3'd7: cr7 <= { nf, zf, vf, cf };
          endcase
        end else begin
          case(opcode)
            6'd1: case(func)
              6'd1, 6'd2, 6'd3, 6'd4, 6'd5, 6'd6: if(Rcbit) cr0 <= { nf, zf, vf, cf }; 
              default: ;
            endcase
            6'd2: case(func)
              6'd24, 6'd26, 6'd25, 6'd27, 6'd28, 6'd29, 6'd30, 6'd31, 6'd4, 6'd5, 6'd8, 6'd11, 6'd9, 6'd15, 6'd10, 6'd12, 6'd13, 6'd14, 6'd23, 6'd22, 6'd60, 6'd61, 6'd16, 6'd17, 6'd18, 6'd19, 6'd48, 6'd49, 6'd50, 6'd51, 6'd52: if(Rcbit) cr0 <= { nf, zf, vf, cf }; 
              default: ;
            endcase
            6'd12, 6'd13, 6'd14, 6'd15, 6'd4, 6'd5, 6'd8, 6'd9, 6'd10, 6'd48, 6'd49, 6'd50, 6'd51, 6'd52, 6'd46: cr0 <= { nf, zf, vf, cf };
            default: ;
          endcase
        end
      end
      JMP32: if(!cyc_o) begin
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= pc;
      end else if(ack_i) begin
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        sel_o <= 4'b0000;
        pc <= dat_i;
        state <= IFETCH;
      end 
      JSR32: if(!cyc_o) begin
        fc_o <= { sf, 2'b10 };
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= pc;
      end else if(ack_i) begin
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        sel_o <= 4'b0000;
        pc <= pc + 32'd4;
        tgt <= dat_i;
        state <= JSR1;
      end 
      JSR1: if(!cyc_o) begin
        fc_o <= { sf, 2'b01 };
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        we_o <= 1'b1;
        sel_o <= 4'b1111;
        if(sf) adr_o <= ssp - 32'd4; 
        else adr_o <= usp - 32'd4;
        dat_o <= pc;
      end else if(ack_i) begin
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        we_o <= 1'b0;
        sel_o <= 4'b0000;
        if(sf) ssp <= ssp - 32'd4; 
        else usp <= usp - 32'd4;
        pc <= tgt;
        state <= IFETCH;
      end 
      RTS: if(!cyc_o) begin
        fc_o <= { sf, 2'b01 };
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= (sf)? ssp : usp;
      end else if(ack_i) begin
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        sel_o <= 4'b0000;
        if(sf) ssp <= ssp + 32'd4 + ir[21:6]; 
        else usp <= usp + 32'd4 + ir[21:6];
        pc <= { dat_i[31:2], 2'b00 } + { ir[25:22], 2'b00 };
        state <= IFETCH;
      end 
      INTA: if(!cyc_o) begin
        fc_o <= 3'b111;
        inta_o <= 1'b1;
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        sel_o <= 4'b0001;
        adr_o <= { 27'h7FFFFFF, iplr, 2'b00 };
      end else if(vpa_i) begin
        inta_o <= 1'b0;
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        sel_o <= 4'b0000;
        vecnum <= 32'd24 + iplr;
        state <= FETCH_VECTOR;
      end else if(ack_i) begin
        inta_o <= 1'b0;
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        sel_o <= 4'b0000;
        vecnum <= dat_i[7:0];
        state <= FETCH_VECTOR;
      end else if(err_i) begin
        inta_o <= 1'b0;
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        sel_o <= 4'b0000;
        vecnum <= 32'd24;
        state <= FETCH_VECTOR;
      end 
      FETCH_VECTOR: if(!cyc_o) begin
        fc_o <= 3'b101;
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= { vecnum, 2'b00 };
      end else if(ack_i) begin
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        sel_o <= 4'b0000;
        vector <= dat_i;
        state <= TRAP1;
      end 
      TRAP1: if(!cyc_o) begin
        fc_o <= { 3'b101 };
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        we_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= ssp - 32'd4;
        dat_o <= pc;
      end else if(ack_i) begin
        stb_o <= 1'b0;
        we_o <= 1'b0;
        sel_o <= 4'b0000;
        sr1 <= sr;
        sf <= 1'b1;
        tf <= 1'b0;
        ssp <= ssp - 32'd4;
        state <= TRAP2;
      end 
      TRAP2: if(!stb_o) begin
        fc_o <= { 3'b101 };
        stb_o <= 1'b1;
        we_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= ssp - 32'd4;
        dat_o <= cr;
      end else if(ack_i) begin
        stb_o <= 1'b0;
        we_o <= 1'b0;
        sel_o <= 4'b0000;
        ssp <= ssp - 32'd4;
        state <= TRAP3;
      end 
      TRAP3: if(!stb_o) begin
        fc_o <= { 3'b101 };
        stb_o <= 1'b1;
        we_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= ssp - 32'd4;
        dat_o <= sr1;
      end else if(ack_i) begin
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        we_o <= 1'b0;
        sel_o <= 4'b0000;
        ssp <= ssp - 32'd4;
        state <= VECTOR;
      end 
      RTI1: if(!cyc_o) begin
        fc_o <= { 3'b101 };
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= ssp;
      end else if(ack_i) begin
        stb_o <= 1'b0;
        sel_o <= 4'b0000;
        im <= dat_i[18:16];
        sf <= dat_i[21];
        tf <= dat_i[23];
        ssp <= ssp + 32'd4;
        state <= RTI2;
      end 
      RTI2: if(!stb_o) begin
        fc_o <= { 3'b101 };
        stb_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= ssp;
      end else if(ack_i) begin
        stb_o <= 1'b0;
        sel_o <= 4'b0000;
        cr0 <= dat_i[3:0];
        cr1 <= dat_i[7:4];
        cr2 <= dat_i[11:8];
        cr3 <= dat_i[15:12];
        cr4 <= dat_i[19:16];
        cr5 <= dat_i[23:20];
        cr6 <= dat_i[27:24];
        cr7 <= dat_i[31:28];
        ssp <= ssp + 32'd4;
        state <= RTI3;
      end 
      RTI3: if(!stb_o) begin
        fc_o <= { 3'b101 };
        stb_o <= 1'b1;
        sel_o <= 4'b1111;
        adr_o <= ssp;
      end else if(ack_i) begin
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        sel_o <= 4'b0000;
        pc <= dat_i;
        ssp <= ssp + 32'd4;
        state <= IFETCH;
      end 
      MULTDIV1: begin
        state <= (IsMult)? MULT1 : DIV1;
        cnt <= 6'd0;
        case(opcode)
          6'd2: case(func)
            6'd26, 6'd27, 6'd29, 6'd31: begin
              aa <= (a[31])? -a : a;
              bb <= (b[31])? -b : b;
              res_sgn <= a[31] ^ b[31];
            end
            6'd24, 6'd25, 6'd28, 6'd30: begin
              aa <= a;
              bb <= b;
              res_sgn <= 1'b0;
            end
          endcase
          6'd13, 6'd15: begin
            aa <= (a[31])? -a : a;
            bb <= (imm[31])? -imm : imm;
            res_sgn <= a[31] ^ imm[31];
          end
          6'd12, 6'd14: begin
            aa <= a;
            bb <= imm;
            res_sgn <= 1'b0;
          end
        endcase
      end
      MULT1: begin
        prod <= { mp3, mp0 } + { mp1, 16'd0 };
        state <= MULT2;
      end
      MULT2: begin
        prod <= prod + { mp2, 16'd0 };
        state <= (res_sgn)? MULT6 : MULTDIV2;
      end
      MULT6: begin
        state <= MULTDIV2;
        prod <= -prod;
      end
      DIV1: if(cnt <= 32) begin
        cnt <= cnt + 8'd1;
        aa[0] <= ~div_dif[31];
        aa[31:1] <= aa[30:0];
        div_r0[0] <= aa[31];
        if(~div_dif[31]) div_r0[31:1] <= div_dif[31:0]; 
        else div_r0[31:1] <= div_r0[30:0];
      end else state <= DIV2;
      DIV2: begin
        state <= MULTDIV2;
        if(res_sgn) begin
          div_q <= -aa;
          div_r <= -div_r0;
        end else begin
          div_q <= aa;
          div_r <= div_r0;
        end
      end
      MULTDIV2: begin
        state <= WRITEBACK;
        case(opcode)
          6'd2: case(func)
            6'd24: begin
              res <= prod[31:0];
              vf <= |prod[63:32];
            end
            6'd26: begin
              res <= prod[31:0];
              vf <= (prod[31])? ~&prod[63:32] : |prod[63:32];
            end
            6'd25: begin
              res <= prod[63:32];
            end
            6'd27: begin
              res <= prod[63:32];
            end
            6'd29: res <= div_q;
            6'd28: res <= div_q;
            6'd31: res <= div_r;
            6'd30: res <= div_r;
          endcase
          6'd13: begin
            res <= prod[31:0];
            vf <= (prod[31])? ~&prod[63:32] : |prod[63:32];
          end
          6'd12: begin
            res <= prod[31:0];
            vf <= |prod[63:32];
          end
          6'd14: res <= div_q;
          6'd15: res <= div_q;
        endcase
      end
    endcase
    if(cyc_o | err_i) begin
      cyc_o <= 1'b0;
      stb_o <= 1'b0;
      sel_o <= 4'b0000;
      we_o <= 1'b0;
      inta_o <= 1'b0;
      be_addr <= adr_o;
      vector <= 32'h00000008;
      state <= TRAP;
    end 
  end


endmodule

