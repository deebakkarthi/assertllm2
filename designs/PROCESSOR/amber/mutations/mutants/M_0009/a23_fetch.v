

module a23_fetch
(
  input i_clk,
  input [31:0] i_address,
  input i_address_valid,
  input [31:0] i_address_nxt,
  input [31:0] i_write_data,
  input i_write_enable,
  output [31:0] o_read_data,
  input i_priviledged,
  input i_exclusive,
  input [3:0] i_byte_enable,
  input i_data_access,
  input i_cache_enable,
  input i_cache_flush,
  input [31:0] i_cacheable_area,
  input i_system_rdy,
  output o_fetch_stall,
  output [31:0] o_wb_adr,
  output [3:0] o_wb_sel,
  output o_wb_we,
  input [31:0] i_wb_dat,
  output [31:0] o_wb_dat,
  output o_wb_cyc,
  output o_wb_stb,
  input i_wb_ack,
  input i_wb_err
);

  localparam MAIN_MSB = 26;
  localparam BOOT_MSB = 13;
  localparam MAIN_BASE = 32'h0000_0000;
  localparam BOOT_BASE = 32'h0000_0000;
  localparam AMBER_TM_BASE = 16'h1300;
  localparam AMBER_IC_BASE = 16'h1400;
  localparam AMBER_UART0_BASE = 16'h1600;
  localparam AMBER_UART1_BASE = 16'h1700;
  localparam ETHMAC_BASE = 16'h2000;
  localparam HIBOOT_BASE = 32'h2800_0000;
  localparam TEST_BASE = 16'hf000;

  function [0:0] in_loboot_mem;
    input [31:0] address;
    begin
      in_loboot_mem = (address >= BOOT_BASE) && (address < BOOT_BASE + 2 ** (BOOT_MSB + 1) - 1);
    end
  endfunction


  function [0:0] in_hiboot_mem;
    input [31:0] address;
    begin
      in_hiboot_mem = address[31:BOOT_MSB+1] == HIBOOT_BASE[31:BOOT_MSB+1];
    end
  endfunction


  function [0:0] in_boot_mem;
    input [31:0] address;
    begin
      in_boot_mem = in_loboot_mem(address) || in_hiboot_mem(address);
    end
  endfunction


  function [0:0] in_main_mem;
    input [31:0] address;
    begin
      in_main_mem = (address >= MAIN_BASE) && (address < MAIN_BASE + 2 ** (MAIN_MSB + 1) - 1) && !in_boot_mem(address);
    end
  endfunction


  function [0:0] in_uart0;
    input [31:0] address;
    begin
      in_uart0 = address[31:16] == AMBER_UART0_BASE;
    end
  endfunction


  function [0:0] in_uart1;
    input [31:0] address;
    begin
      in_uart1 = address[31:16] == AMBER_UART1_BASE;
    end
  endfunction


  function [0:0] in_ic;
    input [31:0] address;
    begin
      in_ic = address[31:16] == AMBER_IC_BASE;
    end
  endfunction


  function [0:0] in_tm;
    input [31:0] address;
    begin
      in_tm = address[31:16] == AMBER_TM_BASE;
    end
  endfunction


  function [0:0] in_test;
    input [31:0] address;
    begin
      in_test = address[31:16] == TEST_BASE;
    end
  endfunction


  function [0:0] in_ethmac;
    input [31:0] address;
    begin
      in_ethmac = address[31:16] == ETHMAC_BASE;
    end
  endfunction


  function [0:0] in_cachable_mem;
    input [31:0] address;
    begin
      in_cachable_mem = in_loboot_mem(address) || in_main_mem(address);
    end
  endfunction

  wire cache_stall;
  wire wb_stall;
  wire [31:0] cache_read_data;
  wire sel_cache;
  wire sel_wb;
  wire cache_wb_req;
  wire address_cachable;
  assign address_cachable = in_cachable_mem(i_address) && i_cacheable_area[i_address[25:21]];
  assign sel_cache = address_cachable && i_address_valid && i_cache_enable && !i_exclusive;
  assign sel_wb = !sel_cache && i_address_valid && !cache_stall;
  assign o_read_data = (sel_cache)? cache_read_data : 
                       (sel_wb)? i_wb_dat : 32'hffeeddcc;
  assign o_fetch_stall = !i_system_rdy && wb_stall || cache_stall;

  a23_cache
  u_cache
  (
    .i_clk(i_clk),
    .i_select(sel_cache),
    .i_exclusive(i_exclusive),
    .i_write_data(i_write_data),
    .i_write_enable(i_write_enable),
    .i_address(i_address),
    .i_address_nxt(i_address_nxt),
    .i_byte_enable(i_byte_enable),
    .i_cache_enable(i_cache_enable),
    .i_cache_flush(i_cache_flush),
    .o_read_data(cache_read_data),
    .o_stall(cache_stall),
    .i_core_stall(o_fetch_stall),
    .o_wb_req(cache_wb_req),
    .i_wb_address(o_wb_adr),
    .i_wb_read_data(i_wb_dat),
    .i_wb_stall(o_wb_stb & ~i_wb_ack)
  );


  a23_wishbone
  u_wishbone
  (
    .i_clk(i_clk),
    .i_select(sel_wb),
    .i_write_data(i_write_data),
    .i_write_enable(i_write_enable),
    .i_byte_enable(i_byte_enable),
    .i_data_access(i_data_access),
    .i_exclusive(i_exclusive),
    .i_address(i_address),
    .o_stall(wb_stall),
    .i_cache_req(cache_wb_req),
    .o_wb_adr(o_wb_adr),
    .o_wb_sel(o_wb_sel),
    .o_wb_we(o_wb_we),
    .i_wb_dat(i_wb_dat),
    .o_wb_dat(o_wb_dat),
    .o_wb_cyc(o_wb_cyc),
    .o_wb_stb(o_wb_stb),
    .i_wb_ack(i_wb_ack),
    .i_wb_err(i_wb_err)
  );


endmodule

