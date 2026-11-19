

module omsp_frontend
(
  cpu_halt_st,
  decode_noirq,
  e_state,
  exec_done,
  inst_ad,
  inst_as,
  inst_alu,
  inst_bw,
  inst_dest,
  inst_dext,
  inst_irq_rst,
  inst_jmp,
  inst_mov,
  inst_sext,
  inst_so,
  inst_src,
  inst_type,
  irq_acc,
  mab,
  mb_en,
  mclk_dma_enable,
  mclk_dma_wkup,
  mclk_enable,
  mclk_wkup,
  nmi_acc,
  pc,
  pc_nxt,
  cpu_en_s,
  cpu_halt_cmd,
  cpuoff,
  dbg_reg_sel,
  dma_en,
  dma_wkup,
  fe_pmem_wait,
  gie,
  irq,
  mclk,
  mdb_in,
  nmi_pnd,
  nmi_wkup,
  pc_sw,
  pc_sw_wr,
  puc_rst,
  scan_enable,
  wdt_irq,
  wdt_wkup,
  wkup
);

  output cpu_halt_st;
  output decode_noirq;
  output [3:0] e_state;
  output exec_done;
  output [7:0] inst_ad;
  output [7:0] inst_as;
  output [11:0] inst_alu;
  output inst_bw;
  output [15:0] inst_dest;
  output [15:0] inst_dext;
  output inst_irq_rst;
  output [7:0] inst_jmp;
  output inst_mov;
  output [15:0] inst_sext;
  output [7:0] inst_so;
  output [15:0] inst_src;
  output [2:0] inst_type;
  output [16-3:0] irq_acc;
  output [15:0] mab;
  output mb_en;
  output mclk_dma_enable;
  output mclk_dma_wkup;
  output mclk_enable;
  output mclk_wkup;
  output nmi_acc;
  output [15:0] pc;
  output [15:0] pc_nxt;
  input cpu_en_s;
  input cpu_halt_cmd;
  input cpuoff;
  input [3:0] dbg_reg_sel;
  input dma_en;
  input dma_wkup;
  input fe_pmem_wait;
  input gie;
  input [16-3:0] irq;
  input mclk;
  input [15:0] mdb_in;
  input nmi_pnd;
  input nmi_wkup;
  input [15:0] pc_sw;
  input pc_sw_wr;
  input puc_rst;
  input scan_enable;
  input wdt_irq;
  input wdt_wkup;
  input wkup;

  function [63:0] one_hot64;
    input [5:0] binary;
    begin
      one_hot64 = 64'h0000_0000_0000_0000;
      one_hot64[binary] = 1'b1;
    end
  endfunction


  function [15:0] one_hot16;
    input [3:0] binary;
    begin
      one_hot16 = 16'h0000;
      one_hot16[binary] = 1'b1;
    end
  endfunction


  function [7:0] one_hot8;
    input [2:0] binary;
    begin
      one_hot8 = 8'h00;
      one_hot8[binary] = 1'b1;
    end
  endfunction


  function [5:0] get_irq_num;
    input [62:0] irq_all;
    integer ii;
    begin
      get_irq_num = 6'h3f;
      for(ii=62; ii>=0; ii=ii-1) if(&get_irq_num & irq_all[ii]) get_irq_num = ii[5:0]; 
    end
  endfunction

  parameter I_IRQ_FETCH = 3'h0;
  parameter I_IRQ_DONE = 3'h1;
  parameter I_DEC = 3'h2;
  parameter I_EXT1 = 3'h3;
  parameter I_EXT2 = 3'h4;
  parameter I_IDLE = 3'h5;
  parameter E_IRQ_0 = 4'h2;
  parameter E_IRQ_1 = 4'h1;
  parameter E_IRQ_2 = 4'h0;
  parameter E_IRQ_3 = 4'h3;
  parameter E_IRQ_4 = 4'h4;
  parameter E_SRC_AD = 4'h5;
  parameter E_SRC_RD = 4'h6;
  parameter E_SRC_WR = 4'h7;
  parameter E_DST_AD = 4'h8;
  parameter E_DST_RD = 4'h9;
  parameter E_DST_WR = 4'hA;
  parameter E_EXEC = 4'hB;
  parameter E_JUMP = 4'hC;
  parameter E_IDLE = 4'hD;
  reg [2:0] i_state;
  reg [2:0] i_state_nxt;
  reg [1:0] inst_sz;
  wire [1:0] inst_sz_nxt;
  wire irq_detect;
  wire [2:0] inst_type_nxt;
  wire is_const;
  reg [15:0] sconst_nxt;
  reg [3:0] e_state_nxt;
  wire cpu_halt_req;assign cpu_halt_req = cpu_halt_cmd | ~cpu_en_s;

  always @(i_state or inst_sz or inst_sz_nxt or pc_sw_wr or exec_done or irq_detect or cpuoff or cpu_halt_req or e_state) case(i_state)
    I_IDLE: i_state_nxt = (irq_detect & ~cpu_halt_req)? I_IRQ_FETCH : 
                  (~cpuoff & ~cpu_halt_req)? I_DEC : I_IDLE;
    I_IRQ_FETCH: i_state_nxt = I_IRQ_DONE;
    I_IRQ_DONE: i_state_nxt = I_DEC;
    I_DEC: i_state_nxt = (irq_detect)? I_IRQ_FETCH : 
                  ((cpuoff | cpu_halt_req) & exec_done)? I_IDLE : 
                  (cpu_halt_req & (e_state == E_IDLE))? I_IDLE : 
                  (pc_sw_wr)? I_DEC : 
                  (~exec_done & ~(e_state == E_IDLE))? I_DEC : 
                  (inst_sz_nxt != 2'b00)? I_EXT1 : I_DEC;
    I_EXT1: i_state_nxt = (pc_sw_wr)? I_DEC : 
                  (inst_sz != 2'b01)? I_EXT2 : I_DEC;
    I_EXT2: i_state_nxt = I_DEC;
    default: i_state_nxt = I_IRQ_FETCH;
  endcase


  always @(posedge mclk or posedge puc_rst) if(puc_rst) i_state <= I_IRQ_FETCH; 
  else i_state <= i_state_nxt;

  wire decode_noirq;assign decode_noirq = (i_state == I_DEC) & (exec_done | (e_state == E_IDLE));
  wire decode;assign decode = decode_noirq | irq_detect;
  wire fetch;assign fetch = ~((i_state == I_DEC) & ~(exec_done | (e_state == E_IDLE))) & ~(e_state_nxt == E_IDLE);
  reg cpu_halt_st;

  always @(posedge mclk or posedge puc_rst) if(puc_rst) cpu_halt_st <= 1'b0; 
  else cpu_halt_st <= cpu_halt_req & (i_state_nxt == I_IDLE);

  reg inst_irq_rst;

  always @(posedge mclk or posedge puc_rst) if(puc_rst) inst_irq_rst <= 1'b1; 
  else if(exec_done) inst_irq_rst <= 1'b0; 

  assign irq_detect = (nmi_pnd | (|irq | wdt_irq) & gie) & ~cpu_halt_req & ~cpu_halt_st & (exec_done | (i_state == I_IDLE));
  wire mclk_irq_num;

  omsp_clock_gate
  clock_gate_irq_num
  (
    .gclk(mclk_irq_num),
    .clk(mclk),
    .enable(irq_detect),
    .scan_enable(scan_enable)
  );

  wire [62:0] irq_all;assign irq_all = { nmi_pnd, irq, 48'h0000_0000_0000 } | { 1'b0, 3'h0, wdt_irq, { 58{ 1'b0 } } };
  reg [5:0] irq_num;

  always @(posedge mclk_irq_num or posedge puc_rst) if(puc_rst) irq_num <= 6'h3f; 
  else irq_num <= get_irq_num(irq_all);

  wire [15:0] irq_addr;assign irq_addr = { 9'h1ff, irq_num, 1'b0 };
  wire [63:0] irq_acc_all;assign irq_acc_all = one_hot64(irq_num) & { 64{ i_state == I_IRQ_FETCH } };
  wire [16-3:0] irq_acc;assign irq_acc = irq_acc_all[61:64-16];
  wire nmi_acc;assign nmi_acc = irq_acc_all[62];
  wire mclk_enable;assign mclk_enable = (inst_irq_rst)? cpu_en_s : ~((cpuoff | ~cpu_en_s) & (i_state == I_IDLE) & (e_state == E_IDLE));
  wire mirq_wkup;

  omsp_and_gate
  and_mirq_wkup
  (
    .y(mirq_wkup),
    .a(wkup | wdt_wkup),
    .b(gie)
  );


  omsp_and_gate
  and_mclk_wkup
  (
    .y(mclk_wkup),
    .a(nmi_wkup | mirq_wkup),
    .b(cpu_en_s)
  );

  wire mclk_dma_enable;assign mclk_dma_enable = dma_en & cpu_en_s;

  omsp_and_gate
  and_mclk_dma_wkup
  (
    .y(mclk_dma_wkup),
    .a(dma_wkup),
    .b(cpu_en_s)
  );

  reg [15:0] pc;
  wire [15:0] pc_incr;assign pc_incr = pc + { 14'h0000, fetch, 1'b0 };
  wire [15:0] pc_nxt;assign pc_nxt = (pc_sw_wr)? pc_sw : 
                  (i_state == I_IRQ_FETCH)? irq_addr : 
                  (i_state == I_IRQ_DONE)? mdb_in : pc_incr;
  wire pc_en;assign pc_en = fetch | pc_sw_wr | (i_state == I_IRQ_FETCH) | (i_state == I_IRQ_DONE);
  wire mclk_pc;

  omsp_clock_gate
  clock_gate_pc
  (
    .gclk(mclk_pc),
    .clk(mclk),
    .enable(pc_en),
    .scan_enable(scan_enable)
  );


  always @(posedge mclk_pc or posedge puc_rst) if(puc_rst) pc <= 16'h0000; 
  else pc <= pc_nxt;

  reg pmem_busy;

  always @(posedge mclk or posedge puc_rst) if(puc_rst) pmem_busy <= 1'b0; 
  else pmem_busy <= fe_pmem_wait;

  wire [15:0] mab;assign mab = pc_nxt;
  wire mb_en;assign mb_en = fetch | pc_sw_wr | (i_state == I_IRQ_FETCH) | pmem_busy | cpu_halt_st & ~cpu_halt_req;
  wire [15:0] ir;assign ir = mdb_in;
  wire is_sext;assign is_sext = inst_as[1] | inst_as[4] | inst_as[6] | inst_as[5];
  wire [15:0] ext_incr;assign ext_incr = ((i_state == I_EXT1) & inst_as[4] | (i_state == I_EXT2) & inst_ad[4] | (i_state == I_EXT1) & ~inst_as[4] & ~(i_state_nxt == I_EXT2) & inst_ad[4])? 16'hfffe : 16'h0000;
  wire [15:0] ext_nxt;assign ext_nxt = ir + ext_incr;
  reg [15:0] inst_sext;
  wire inst_sext_en;assign inst_sext_en = decode & is_const | decode & inst_type_nxt[1] | (i_state == I_EXT1) & is_sext;
  wire mclk_inst_sext;

  omsp_clock_gate
  clock_gate_inst_sext
  (
    .gclk(mclk_inst_sext),
    .clk(mclk),
    .enable(inst_sext_en),
    .scan_enable(scan_enable)
  );


  always @(posedge mclk_inst_sext or posedge puc_rst) if(puc_rst) inst_sext <= 16'h0000; 
  else if(decode & is_const) inst_sext <= sconst_nxt; 
  else if(decode & inst_type_nxt[1]) inst_sext <= { { 5{ ir[9] } }, ir[9:0], 1'b0 }; 
  else inst_sext <= ext_nxt;

  wire inst_sext_rdy;assign inst_sext_rdy = (i_state == I_EXT1) & is_sext;
  reg [15:0] inst_dext;
  wire inst_dext_en;assign inst_dext_en = (i_state == I_EXT1) & ~is_sext | (i_state == I_EXT2);
  wire mclk_inst_dext;

  omsp_clock_gate
  clock_gate_inst_dext
  (
    .gclk(mclk_inst_dext),
    .clk(mclk),
    .enable(inst_dext_en),
    .scan_enable(scan_enable)
  );


  always @(posedge mclk_inst_dext or posedge puc_rst) if(puc_rst) inst_dext <= 16'h0000; 
  else if((i_state == I_EXT1) & ~is_sext) inst_dext <= ext_nxt; 
  else inst_dext <= ext_nxt;

  wire inst_dext_rdy;assign inst_dext_rdy = (i_state == I_EXT1) & ~is_sext | (i_state == I_EXT2);
  wire mclk_decode;

  omsp_clock_gate
  clock_gate_decode
  (
    .gclk(mclk_decode),
    .clk(mclk),
    .enable(decode),
    .scan_enable(scan_enable)
  );

  reg [2:0] inst_type;
  assign inst_type_nxt = { ir[15:14] != 2'b00, ir[15:13] == 3'b001, ir[15:13] == 3'b000 } & { 3{ ~irq_detect } };

  always @(posedge mclk_decode or posedge puc_rst) if(puc_rst) inst_type <= 3'b000; 
  else inst_type <= inst_type_nxt;

  reg [7:0] inst_so;
  wire [7:0] inst_so_nxt;assign inst_so_nxt = (irq_detect)? 8'h80 : one_hot8(ir[9:7]) & { 8{ inst_type_nxt[0] } };

  always @(posedge mclk_decode or posedge puc_rst) if(puc_rst) inst_so <= 8'h00; 
  else inst_so <= inst_so_nxt;

  reg [2:0] inst_jmp_bin;

  always @(posedge mclk_decode or posedge puc_rst) if(puc_rst) inst_jmp_bin <= 3'h0; 
  else inst_jmp_bin <= ir[12:10];

  wire [7:0] inst_jmp;assign inst_jmp = one_hot8(inst_jmp_bin) & { 8{ inst_type[1] } };
  wire [15:0] inst_to_1hot;assign inst_to_1hot = one_hot16(ir[15:12]) & { 16{ inst_type_nxt[2] } };
  wire [11:0] inst_to_nxt;assign inst_to_nxt = inst_to_1hot[15:4];
  reg inst_mov;

  always @(posedge mclk_decode or posedge puc_rst) if(puc_rst) inst_mov <= 1'b0; 
  else inst_mov <= inst_to_nxt[0];

  reg [3:0] inst_dest_bin;

  always @(posedge mclk_decode or posedge puc_rst) if(puc_rst) inst_dest_bin <= 4'h0; 
  else inst_dest_bin <= ir[3:0];

  wire [15:0] inst_dest;assign inst_dest = (cpu_halt_st)? one_hot16(dbg_reg_sel) : 
                     (inst_type[1])? 16'h0001 : 
                     (inst_so[7] | inst_so[4] | inst_so[5])? 16'h0002 : one_hot16(inst_dest_bin);
  reg [3:0] inst_src_bin;

  always @(posedge mclk_decode or posedge puc_rst) if(puc_rst) inst_src_bin <= 4'h0; 
  else inst_src_bin <= ir[11:8];

  wire [15:0] inst_src;assign inst_src = (inst_type[2])? one_hot16(inst_src_bin) : 
                    (inst_so[6])? 16'h0002 : 
                    (inst_so[7])? 16'h0001 : 
                    (inst_type[0])? one_hot16(inst_dest_bin) : 16'h0000;
  reg [12:0] inst_as_nxt;
  wire [3:0] src_reg;assign src_reg = (inst_type_nxt[0])? ir[3:0] : ir[11:8];

  always @(src_reg or ir or inst_type_nxt) begin
    if(inst_type_nxt[1]) inst_as_nxt = 13'b0000000000001; 
    else if(src_reg == 4'h3) case(ir[5:4])
      2'b11: inst_as_nxt = 13'b1000000000000;
      2'b10: inst_as_nxt = 13'b0100000000000;
      2'b01: inst_as_nxt = 13'b0010000000000;
      default: inst_as_nxt = 13'b0001000000000;
    endcase else if(src_reg == 4'h2) case(ir[5:4])
      2'b11: inst_as_nxt = 13'b0000100000000;
      2'b10: inst_as_nxt = 13'b0000010000000;
      2'b01: inst_as_nxt = 13'b0000001000000;
      default: inst_as_nxt = 13'b0000000000001;
    endcase else if(src_reg == 4'h0) case(ir[5:4])
      2'b11: inst_as_nxt = 13'b0000000100000;
      2'b10: inst_as_nxt = 13'b0000000000100;
      2'b01: inst_as_nxt = 13'b0000000010000;
      default: inst_as_nxt = 13'b0000000000001;
    endcase else case(ir[5:4])
      2'b11: inst_as_nxt = 13'b0000000001000;
      2'b10: inst_as_nxt = 13'b0000000000100;
      2'b01: inst_as_nxt = 13'b0000000000010;
      default: inst_as_nxt = 13'b0000000000001;
    endcase
  end

  assign is_const = |inst_as_nxt[12:7];
  reg [7:0] inst_as;

  always @(posedge mclk_decode or posedge puc_rst) if(puc_rst) inst_as <= 8'h00; 
  else inst_as <= { is_const, inst_as_nxt[6:0] };


  always @(inst_as_nxt) begin
    if(inst_as_nxt[7]) sconst_nxt = 16'h0004; 
    else if(inst_as_nxt[8]) sconst_nxt = 16'h0008; 
    else if(inst_as_nxt[9]) sconst_nxt = 16'h0000; 
    else if(inst_as_nxt[10]) sconst_nxt = 16'h0001; 
    else if(inst_as_nxt[11]) sconst_nxt = 16'h0002; 
    else if(inst_as_nxt[12]) sconst_nxt = 16'hffff; 
    else sconst_nxt = 16'h0000;
  end

  reg [7:0] inst_ad_nxt;
  wire [3:0] dest_reg;assign dest_reg = ir[3:0];

  always @(dest_reg or ir or inst_type_nxt) begin
    if(~inst_type_nxt[2]) inst_ad_nxt = 8'b00000000; 
    else if(dest_reg == 4'h2) case(ir[7])
      1'b1: inst_ad_nxt = 8'b01000000;
      default: inst_ad_nxt = 8'b00000001;
    endcase else if(dest_reg == 4'h0) case(ir[7])
      1'b1: inst_ad_nxt = 8'b00010000;
      default: inst_ad_nxt = 8'b00000001;
    endcase else case(ir[7])
      1'b1: inst_ad_nxt = 8'b00000010;
      default: inst_ad_nxt = 8'b00000001;
    endcase
  end

  reg [7:0] inst_ad;

  always @(posedge mclk_decode or posedge puc_rst) if(puc_rst) inst_ad <= 8'h00; 
  else inst_ad <= inst_ad_nxt;

  reg inst_bw;

  always @(posedge mclk or posedge puc_rst) if(puc_rst) inst_bw <= 1'b0; 
  else if(decode) inst_bw <= ir[6] & ~inst_type_nxt[2] & ~irq_detect & ~cpu_halt_req; 

  assign inst_sz_nxt = { 1'b0, inst_as_nxt[1] | inst_as_nxt[4] | inst_as_nxt[6] | inst_as_nxt[5] } + { 1'b0, (inst_ad_nxt[1] | inst_ad_nxt[4] | inst_ad_nxt[6]) & ~inst_type_nxt[0] };

  always @(posedge mclk_decode or posedge puc_rst) if(puc_rst) inst_sz <= 2'b00; 
  else inst_sz <= inst_sz_nxt;

  reg [3:0] e_state;
  wire src_acalc_pre;assign src_acalc_pre = inst_as_nxt[1] | inst_as_nxt[4] | inst_as_nxt[6];
  wire src_rd_pre;assign src_rd_pre = inst_as_nxt[2] | inst_as_nxt[3] | inst_as_nxt[5] | inst_so_nxt[6];
  wire dst_acalc_pre;assign dst_acalc_pre = inst_ad_nxt[1] | inst_ad_nxt[4] | inst_ad_nxt[6];
  wire dst_acalc;assign dst_acalc = inst_ad[1] | inst_ad[4] | inst_ad[6];
  wire dst_rd_pre;assign dst_rd_pre = inst_ad_nxt[1] | inst_so_nxt[4] | inst_so_nxt[5] | inst_so_nxt[6];
  wire dst_rd;assign dst_rd = inst_ad[1] | inst_so[4] | inst_so[5] | inst_so[6];
  wire inst_branch;assign inst_branch = inst_ad_nxt[0] & (ir[3:0] == 4'h0) | inst_type_nxt[1] | inst_so_nxt[6];
  reg exec_jmp;

  always @(posedge mclk or posedge puc_rst) if(puc_rst) exec_jmp <= 1'b0; 
  else if(inst_branch & decode) exec_jmp <= 1'b1; 
  else if(e_state == E_JUMP) exec_jmp <= 1'b0; 

  reg exec_dst_wr;

  always @(posedge mclk or posedge puc_rst) if(puc_rst) exec_dst_wr <= 1'b0; 
  else if(e_state == E_DST_RD) exec_dst_wr <= 1'b1; 
  else if(e_state == E_DST_WR) exec_dst_wr <= 1'b0; 

  reg exec_src_wr;

  always @(posedge mclk or posedge puc_rst) if(puc_rst) exec_src_wr <= 1'b0; 
  else if(inst_type[0] & (e_state == E_SRC_RD)) exec_src_wr <= 1'b1; 
  else if((e_state == E_SRC_WR) || (e_state == E_DST_WR)) exec_src_wr <= 1'b0; 

  reg exec_dext_rdy;

  always @(posedge mclk or posedge puc_rst) if(puc_rst) exec_dext_rdy <= 1'b0; 
  else if(e_state == E_DST_RD) exec_dext_rdy <= 1'b0; 
  else if(inst_dext_rdy) exec_dext_rdy <= 1'b1; 

  wire [3:0] e_first_state;assign e_first_state = (~cpu_halt_st & inst_so_nxt[7])? E_IRQ_0 : 
                         (cpu_halt_req | (i_state == I_IDLE))? E_IDLE : 
                         (cpuoff)? E_IDLE : 
                         (src_acalc_pre)? E_SRC_AD : 
                         (src_rd_pre)? E_SRC_RD : 
                         (dst_acalc_pre)? E_DST_AD : 
                         (dst_rd_pre)? E_DST_RD : E_EXEC;

  always @(e_state or dst_acalc or dst_rd or inst_sext_rdy or inst_dext_rdy or exec_dext_rdy or exec_jmp or exec_dst_wr or e_first_state or exec_src_wr) case(e_state)
    E_IDLE: e_state_nxt = e_first_state;
    E_IRQ_0: e_state_nxt = E_IRQ_1;
    E_IRQ_1: e_state_nxt = E_IRQ_2;
    E_IRQ_2: e_state_nxt = E_IRQ_3;
    E_IRQ_3: e_state_nxt = E_IRQ_4;
    E_IRQ_4: e_state_nxt = E_EXEC;
    E_SRC_AD: e_state_nxt = (inst_sext_rdy)? E_SRC_RD : E_SRC_AD;
    E_SRC_RD: e_state_nxt = (dst_acalc)? E_DST_AD : 
                  (dst_rd)? E_DST_RD : E_EXEC;
    E_DST_AD: e_state_nxt = (inst_dext_rdy | exec_dext_rdy)? E_DST_RD : E_DST_AD;
    E_DST_RD: e_state_nxt = E_EXEC;
    E_EXEC: e_state_nxt = (exec_dst_wr)? E_DST_WR : 
                  (exec_jmp)? E_JUMP : 
                  (exec_src_wr)? E_SRC_WR : e_first_state;
    E_JUMP: e_state_nxt = e_first_state;
    E_DST_WR: e_state_nxt = (exec_jmp)? E_JUMP : e_first_state;
    E_SRC_WR: e_state_nxt = e_first_state;
    default: e_state_nxt = E_IRQ_0;
  endcase


  always @(posedge mclk or posedge puc_rst) if(puc_rst) e_state <= E_IRQ_1; 
  else e_state <= e_state_nxt;

  wire exec_done;assign exec_done = (exec_jmp)? e_state == E_JUMP : 
                     (exec_dst_wr)? e_state == E_DST_WR : 
                     (exec_src_wr)? e_state == E_SRC_WR : e_state == E_EXEC;
  reg [11:0] inst_alu;
  wire alu_src_inv;assign alu_src_inv = inst_to_nxt[4] | inst_to_nxt[3] | inst_to_nxt[5] | inst_to_nxt[8];
  wire alu_inc;assign alu_inc = inst_to_nxt[4] | inst_to_nxt[5];
  wire alu_inc_c;assign alu_inc_c = inst_to_nxt[2] | inst_to_nxt[6] | inst_to_nxt[3];
  wire alu_add;assign alu_add = inst_to_nxt[1] | inst_to_nxt[2] | inst_to_nxt[4] | inst_to_nxt[3] | inst_to_nxt[5] | inst_type_nxt[1] | inst_so_nxt[6];
  wire alu_and;assign alu_and = inst_to_nxt[11] | inst_to_nxt[8] | inst_to_nxt[7];
  wire alu_or;assign alu_or = inst_to_nxt[9];
  wire alu_xor;assign alu_xor = inst_to_nxt[10];
  wire alu_dadd;assign alu_dadd = inst_to_nxt[6];
  wire alu_stat_7;assign alu_stat_7 = inst_to_nxt[7] | inst_to_nxt[11] | inst_so_nxt[3];
  wire alu_stat_f;assign alu_stat_f = inst_to_nxt[1] | inst_to_nxt[2] | inst_to_nxt[4] | inst_to_nxt[3] | inst_to_nxt[5] | inst_to_nxt[6] | inst_to_nxt[7] | inst_to_nxt[10] | inst_to_nxt[11] | inst_so_nxt[0] | inst_so_nxt[2] | inst_so_nxt[3];
  wire alu_shift;assign alu_shift = inst_so_nxt[0] | inst_so_nxt[2];
  wire exec_no_wr;assign exec_no_wr = inst_to_nxt[5] | inst_to_nxt[7];
  wire [11:0] inst_alu_nxt;assign inst_alu_nxt = { exec_no_wr, alu_shift, alu_stat_f, alu_stat_7, alu_dadd, alu_xor, alu_or, alu_and, alu_add, alu_inc_c, alu_inc, alu_src_inv };

  always @(posedge mclk_decode or posedge puc_rst) if(puc_rst) inst_alu <= 12'h000; 
  else inst_alu <= inst_alu_nxt;


endmodule

